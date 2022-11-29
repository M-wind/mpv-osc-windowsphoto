local assdraw = require 'mp.assdraw'
local ass = assdraw.ass_new()
local osd = mp.create_osd_overlay("ass-events")

local Element = {}

-- function Button:new(props, state)
-- 	return Class.new(self, props, state)
-- end

function Element:bounds(text, h)
	local tags = '\\bord0'
	tags = tags .. '\\fnmpv-icon'
	tags = tags .. '\\fs' .. h
	osd.data = '{' .. tags .. '}' .. text
	osd.id = 59
	osd.compute_bounds = true
	osd.hidden = true
	local res = osd:update()
	osd:remove()
	-- return res.x1 - res.x0, res.y1 - res.y0
	return res.x1 - res.x0
end

function Element:button(flag, props, state, hidden)
	state.osd.id = props.id
	if flag then
		local tags = '\\pos(' .. (props.x + 1) .. ',' .. (props.y - 1) .. ')'
		tags = tags .. '\\blur0'
		tags = tags .. '\\bord0'
		tags = tags .. '\\fnmpv-icon'
		tags = tags .. '\\fs' .. props.h
		tags = tags .. '\\1c&HFFFFFF'
		state.osd.data = '{' .. tags .. '}' .. props.icon
		state.osd.hidden = hidden and true or false
		state.osd.z = 1000
		state.osd:update()
	else
		state.osd:remove()
	end
end

function Element:hover(flag, props, state)
	state.osd.id = 61
	if flag then
		ass.text = ''
		ass:append(props.hover_style)
		ass:pos(props.x, props.y)
		ass:draw_start()
		ass:round_rect_cw(0, 0, props.w, props.h, 4)
		ass:draw_stop()

		state.osd.data = ass.text
		state.osd.z = 500
		state.osd:update()
	else
		state.osd:remove()
	end
end

function Element:panel(flag, props, state, hidden)
	state.osd.id = props.id
	if flag then
		ass.text = ''
		ass:append(props.hover_style)
		ass:pos(props.x, props.y)
		ass:draw_start()
		ass:round_rect_cw(0, 0, props.w, props.h, props.type and 2 or 4)
		ass:draw_stop()

		state.osd.data = ass.text
		state.osd.hidden = hidden and true or false
		state.osd.z = props.z
		state.osd:update()
	else
		state.osd:remove()
	end
end

function Element:panel1(flag, props, state)
	state.osd.id = props.id
	if flag then
		ass.text = ''
		ass:append(props.hover_style)
		ass:pos(props.x, props.y)
		ass:draw_start()
		ass:rect_cw(0, 0, props.w, props.h, props.type and 2 or 4)
		ass:draw_stop()

		state.osd.data = ass.text
		state.osd.z = props.z
		state.osd:update()
	else
		state.osd:remove()
	end
end

return Element
