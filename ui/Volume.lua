local Element = require('ui/Element')

function vol_panel_render(info, state, vol)
    if state.vol_open then return end
    exetral_panel_hide()
    vol_panel_hide(vol, state)
    state.vol_open = true
    -- local width = 229 + state.size + state.marginX + 42
    local width = state.marginX + state.size + 6 + 200 + 12 + state.marginX + 42
    local h = 48
    local x = (info.x + info.h / 2) - width / 2

    -- panel
    vol.volpanel.x = x
    vol.volpanel.y = state.panel_y - h
    vol.volpanel.x1 = x + width
    vol.volpanel.y1 = state.panel_y
    vol.volpanel.w = width
    vol.volpanel.h = h
    Element:panel(true, vol.volpanel, state)

    -- 音量图标
    vol.volicon.x = x + state.marginX
    vol.volicon.y = (state.panel_y - h) + (h - state.size) / 2
    vol.volicon.x1 = vol.volicon.x + state.size
    vol.volicon.y1 = vol.volicon.y + state.size
    vol.volicon.h = state.size
    vol.volicon.w = state.size
    Element:button(true, vol.volicon, state)

    local silderH = state.silderH
    -- local sliderW = width - 2 * state.marginX - state.size * 2 - 5 * 2
    local sliderW = 200
    -- 滑轨
    vol.volslider.x = x + state.marginX + state.size + 6
    vol.volslider.y = (state.panel_y - h) + (h - silderH) / 2
    vol.volslider.x1 = vol.volslider.x + 200
    vol.volslider.y1 = vol.volslider.y + silderH
    vol.volslider.w = sliderW
    vol.volslider.h = silderH
    Element:panel(true, vol.volslider, state)

    -- 滑块
    vol.volsliderBar.x = x + state.marginX + state.size + 6 + state.volume * 2 - silderH
    vol.volsliderBar.y = (state.panel_y - h) + (h - silderH * 2) / 2
    vol.volsliderBar.w = silderH * 2
    vol.volsliderBar.h = silderH * 2
    Element:panel(true, vol.volsliderBar, state)

    -- 音量
    vol.volsliderTxt.x = x + width - state.marginX - 42
    vol.volsliderTxt.y = (state.panel_y - h) + (h - state.size) / 2 + 1
    vol.volsliderTxt.h = state.size
    Element:button(true, vol.volsliderTxt, state)

    -- print(vol.volsliderTxt.x, vol.volslider.x + sliderW )
end

function vol_panel_hide(vol, state)
    for _, v in pairs(vol) do
        Element:panel(false, v, state)
    end
    state.vol_open = false
end
