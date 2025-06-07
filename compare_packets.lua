local gui_enabled = gui_enabled()
if not gui_enabled then return end

register_menu("Tools/Compare Packets", function()
    local num_marked = 0
    local pkt1, pkt2

    local function find_marked_packets()
        num_marked = 0
        local tap = Listener.new("frame", "frame.marked == 1")
        function tap.packet(pinfo, tvb)
            num_marked = num_marked + 1
            if num_marked == 1 then
                pkt1 = {number = pinfo.number, tvb = tvb:range():bytes()}
            elseif num_marked == 2 then
                pkt2 = {number = pinfo.number, tvb = tvb:range():bytes()}
            end
        end

        retap_packets()
        tap:remove()
    end

    find_marked_packets()

    if num_marked ~= 2 then
        report_failure("Exactly two packets must be marked")
        return
    end

    local bytes1 = pkt1.tvb
    local bytes2 = pkt2.tvb

    local len1 = bytes1:len()
    local len2 = bytes2:len()
    local maxlen = math.max(len1, len2)

    local win = TextWindow.new("Packet Comparison")
    win:append("=== Packet Comparison ===\n")
    win:append(string.format("Packet 1: #%d | Length: %d\n", pkt1.number, len1))
    win:append(string.format("Packet 2: #%d | Length: %d\n", pkt2.number, len2))
    win:append("Offset | Byte1  Byte2  Match\n")

    for i = 0, maxlen - 1 do
        local b1 = i < len1 and bytes1:get_index(i) or 0
        local b2 = i < len2 and bytes2:get_index(i) or 0
        local match = (b1 == b2) and "✓" or "✗"
        win:append(string.format("0x%04X |  %02X    %02X    %s\n", i, b1, b2, match))
    end

end, MENU_TOOLS_UNSORTED)
