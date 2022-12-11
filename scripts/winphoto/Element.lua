local assdraw = require 'mp.assdraw'
local ass = assdraw.ass_new()

local Element = {}

function Element.new(x, y, w, h, style, text, raduis)
    local self = { x = x, y = y, w = w, h = h, style = style, text = text or '', raduis = raduis or PanelR }
    local txt = function()
        ass.text = ''
        ass:new_event()
        ass:pos(self.x + 1, self.y - 1)
        ass:append('{' .. self.style .. '\\fs' .. self.h .. '}' .. self.text)
        return ass.text
    end
    local panel = function(props)
        ass.text = ''
        ass:new_event()
        ass:pos(self.x, self.y)
        ass:append(props and props.style or self.style)
        ass:draw_start()
        ass:round_rect_cw(0, 0, self.w, self.h, props and props.raduis or self.raduis)
        ass:draw_stop()
        return ass.text
    end
    local mouseIn = function(x, y)
        local dx = math.max(self.x - x, 0, x - (self.x + self.w))
        local dy = math.max(self.y - y, 0, y - (self.y + self.h))
        return dx + dy == 0
    end
    return {
        info = self,
        txt = txt,
        panel = panel,
        mouseIn = mouseIn,
    }
end

return Element
