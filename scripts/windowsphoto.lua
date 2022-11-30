-- local assdraw = require 'mp.assdraw'
-- local msg = require 'mp.msg'
-- local opt = require 'mp.options'
local utils = require 'mp.utils'
-- local ass = assdraw.ass_new()
-- local ass = getmetatable(assdraw.ass_new())

package.path = mp.find_config_file('scripts') .. '/?.lua'

local Element = require('ui/Element')
require('ui/Volume')
require('ui/Utils')

local state = {
    osd_w = 0,
    osd_h = 0,
    -- play = true,
    size = 28,
    font_size = 20,
    osd = mp.create_osd_overlay("ass-events"),
    panel_x = 0,
    panel_y = 0,
    panel_w = 0,
    panel_h = 42,
    silderH = 4,
    marginX = 12,
    hover_style = '{\\1c&HFFFFFF&\\1a&HE0&\\3a&HDF&\\bord0}',
    panel_style = '{\\1c&H2C2C2C&\\1a&H10&\\3a&H15&\\bord0.3}',
    visible = true,
    timer,
    keep = false,
    extra_panel = { x1 = 0, y1 = 0, x2 = 0, y2 = 0 },
    ccOrAudio = 'audio',
    ccOeAudio_open = false,
    vol_open = false,
    volume = 100,
    startFileVisble = false,
    isStream = false,
    streamNum = 0,
    enable = true,
}

local thumbfast = {
    width = 0,
    height = 0,
    disabled = true,
    available = false
}

local time = {
    seconds = 0,
    cSeconds = 0,
    -- timer,
    len1 = Element:bounds('00:00', state.font_size),
    len2 = Element:bounds('00:00:00', state.font_size)
}

local videoSlider = {
    startFile = {
        id = 58,
        x = 0,
        y = 0,
        h = state.font_size,
        hover_style = '{\\1c&HFFFFFF&\\bord0}',
        icon = '00:00'
    },
    endFile = {
        id = 57,
        x = 0,
        y = 0,
        h = state.font_size,
        hover_style = '{\\1c&HFFFFFF&\\bord0}',
        icon = '00:00'
    },
    sliderLow = {
        id = 56,
        x = 0,
        y = 0,
        w = 0,
        h = state.silderH,
        z = 1000,
        hover_style = '{\\1c&H808080&\\bord0}',
        type = 'slider'
    },
    sliderUp = {
        id = 55,
        x = 0,
        y = 0,
        w = 0,
        h = state.silderH,
        z = 1001,
        hover_style = '{\\1c&HFFFFFF&\\bord0}',
        type = 'slider'
    },
    sliderBar = {
        id = 54,
        hover_style = '{\\1c&HFFFFFF&\\bord0}',
        x = 0,
        y = 0,
        w = state.silderH * 2,
        h = state.silderH * 2,
        z = 1003,
        drag = false,
    },
    sliderCache = {
        id = 40,
        x = 0,
        y = 0,
        w = 0,
        h = state.silderH,
        z = 1002,
        -- hover_style = '{\\1c&HD3DCC4&\\bord0}',
        hover_style = '{\\1c&HD0D5B5&\\bord0}',
        type = 'slider'
    },
}

local icons = {
    play = '\xee\x99\xae',
    pause = '\xee\x98\x80',
    audio = '\xee\x98\x81',
    vol_low = '\xee\xa1\x90',
    vol_mute = '\xee\xa1\x8f',
    vol_full = '\xee\xa1\x8e',
    cc = '\xee\x9a\xa0',
    quit = '\xee\x98\x9b',
    -- quti = '\xee\x98\xad',
}

local subs_audios = {
    sub = { count = 1, data = {
        [1] = {
            id = 'load',
            selected = false,
            title = '选择字幕文件...',
            text = '',
            len = Element:bounds('选择字幕文件...', state.font_size),
            -- title_len = 0,
            text_len = 0
        }
    } },
    audio = { count = 0, data = {} }
}

-- local subs = { count = 0, data = {} }
-- local audios = { count = 0, data = {} }

function vol_icon()
    local icon = icons.vol_full
    if state.volume < 50 then
        icon = icons.vol_low
    end
    if state.volume == 0 or mp.get_property_bool('mute') then
        icon = icons.vol_mute
    end
    return icon
end

local buttons = {
    play = {
        id = 1, x = 0, y = 0,
        hover_style = state.hover_style,
        h = state.size,
        w = state.size,
        icon = icons.pause,
    },
    audio = {
        id = 2, x = 0, y = 0,
        hover_style = state.hover_style,
        h = state.size,
        w = state.size,
        icon = icons.audio,
    },
    volume = {
        id = 3, x = 0, y = 0,
        hover_style = state.hover_style,
        h = state.size,
        w = state.size,
        icon = vol_icon(),
    },
    sub = {
        id = 4, x = 0, y = 0,
        hover_style = state.hover_style,
        h = state.size,
        w = state.size,
        icon = icons.cc,
    },
    -- quit = {id = 8,x = 0, y = 0,h = state.size,icon = '\xee\x98\xad',}
    quit = {
        id = 5, x = 0, y = 0,
        hover_style = '{\\1c&H3E3EE5&\\bord0}',
        h = state.size,
        w = state.size,
        icon = icons.quit,
    }

}

local vol = {
    volpanel = {
        id = 30,
        hover_style = state.panel_style,
        x1 = 0,
        y1 = 0,
        x = 0,
        y = 0,
        w = 0,
        h = 0,
        z = 100
    },
    volicon = {
        id = 31,
        hover_style = state.hover_style,
        x1 = 0,
        y1 = 0,
        x = 0,
        y = 0,
        w = 0,
        h = 0,
        icon = vol_icon(),
    },
    volslider = {
        id = 32,
        hover_style = '{\\1c&HFFFFFF&\\bord0}',
        x1 = 0,
        y1 = 0,
        x = 0,
        y = 0,
        w = 0,
        h = 0,
        z = 200,
        type = 'slider'
    },
    volsliderBar = {
        id = 33,
        hover_style = '{\\1c&HFFFFFF&\\bord0}',
        x = 0,
        y = 0,
        w = 0,
        h = 0,
        z = 200,
        drag = false,
    },
    volsliderTxt = {
        id = 34,
        hover_style = '{\\1c&HFFFFFF&\\bord0}',
        x = 0,
        y = 0,
        h = 0,
        icon = state.volume,
    },
}

function extra_panel_render(type, data)
    -- if state.ccOeAudio_open then return end
    exetral_panel_hide()
    vol_panel_hide(vol, state)
    state.ccOeAudio_open = true
    local info = buttons[type]
    state.ccOrAudio = type

    local len = data.data[1].len
    for _, v1 in pairs(data.data) do
        if v1.len > len then
            len = v1.len
        end
    end

    local width = len + 2 * state.marginX

    local space = 2
    local h = data.count * state.font_size + (data.count - 1) * space + 2 * state.marginX

    state.extra_panel.x1 = (info.x + info.h / 2) - width / 2
    state.extra_panel.y1 = state.panel_y - h
    state.extra_panel.x2 = (info.x + info.h / 2) + width / 2
    state.extra_panel.y2 = state.panel_y

    Element:panel(true, {
        id = 10,
        hover_style = state.panel_style,
        x = (info.x + info.h / 2) - width / 2,
        y = state.panel_y - h,
        w = width,
        h = h,
        z = 100,
    }, state)

    for i = 1, data.count do
        if data.data[i].selected then
            Element:panel(true, {
                id = 11,
                hover_style = state.hover_style,
                x = (info.x + info.h / 2) - width / 2 + state.marginX,
                y = state.panel_y - h + state.marginX + (state.font_size + space) * (i - 1),
                w = width - 2 * state.marginX,
                h = state.font_size,
                z = 200,
            }, state)
        end
        data.data[i]['x'] = (info.x + info.h / 2) - width / 2 + state.marginX
        data.data[i]['y'] = state.panel_y - h + state.marginX + (state.font_size + space) * (i - 1)
        data.data[i]['w'] = width - 2 * state.marginX
        data.data[i]['h'] = state.font_size
        data.data[i]['hover_style'] = state.hover_style
        Element:button(true, {
            id = 20 + i,
            x = (info.x + info.h / 2) - width / 2 + state.marginX,
            y = state.panel_y - h + state.marginX + (state.font_size + space) * (i - 1),
            h = state.font_size,
            icon = data.data[i].title
        }, state)
        Element:button(true, {
            id = 30 + i,
            x = (info.x + info.h / 2) - width / 2 + state.marginX + width - 2 * state.marginX - data.data[i].text_len,
            y = state.panel_y - h + state.marginX + (state.font_size + space) * (i - 1),
            h = state.font_size,
            icon = data.data[i].text
        }, state)
    end
end

function button_click(name)
    local switchStr = {
        quit = function()
            mp.commandv('quit')
        end,
        play = function()
            -- print(mp.get_property_bool("pause"))
            state.play = not mp.get_property_bool("pause")
            mp.set_property_bool("pause", state.play)
        end,
        audio = function()
            if subs_audios['audio'].count <= 1 then return end
            extra_panel_render('audio', subs_audios['audio'])
        end,
        sub = function()
            -- if subs_audios['sub'].count <= 1 then return end
            extra_panel_render('sub', subs_audios['sub'])
        end,
        volume = function()
            vol_panel_render(buttons['volume'], state, vol)
        end
    }
    local isExit = switchStr[name]
    if isExit then
        switchStr[name]()
    end
end

function click(action)

    if state.keep then
        local mouse_pos = mp.get_property_native('mouse-pos')
        local x = math.floor(mouse_pos.x * 720 / state.osd_h)
        local y = math.floor(mouse_pos.y * 720 / state.osd_h)

        if action == 'mbtn_left_up' then
            -- main buttons
            for n, v in pairs(buttons) do
                if hit(x, y, v.x, v.y, v.x + state.size, v.y + state.size) then
                    button_click(n)
                end
            end

            local count = state.ccOrAudio == 'sub' and subs_audios[state.ccOrAudio].count + 100 or
                subs_audios[state.ccOrAudio].count
            if state.ccOeAudio_open and count > 1 and subs_audios[state.ccOrAudio].data[1] and
                subs_audios[state.ccOrAudio].data[1].x then
                for _, v in pairs(subs_audios[state.ccOrAudio].data) do
                    local x0, y0, w, h = v.x and v.x or 0, v.y and v.y or 0, v.w and v.w or 0, v.h and v.h or 0
                    if not v.selected and hit(x, y, x0, y0, x0 + w, y0 + h) then
                        -- v.selected = true
                        exetral_panel_hide()
                        if v.id == 'load' then
                            open_file_dialog()
                        else
                            mp.commandv('set', state.ccOrAudio, v.id)
                        end
                    end
                end
            end

            -- 音量滑轨点击
            if vol.volslider.x ~= 0 and state.vol_open then
                if hit(x, y, vol.volslider.x, vol.volslider.y, vol.volslider.x1, vol.volslider.y1) then
                    local len = mouse_pos.x - math.floor(state.osd_h / 720 * vol.volslider.x)
                    len = math.floor(len * 720 / state.osd_h)
                    state.volume = math.floor(len / 2)
                    vol.volsliderBar.x = vol.volslider.x + len - vol.volsliderBar.w / 2
                    mp.commandv('set', 'volume', state.volume)
                end
            end

            -- 视频滑轨点击
            if videoSlider.sliderLow.x > 0 then
                if hit(x, y, videoSlider.sliderLow.x, videoSlider.sliderLow.y,
                    videoSlider.sliderLow.x + videoSlider.sliderLow.w, videoSlider.sliderLow.y + videoSlider.sliderLow.h) then
                    local len     = mouse_pos.x - math.floor(state.osd_h / 720 * videoSlider.sliderLow.x)
                    len           = math.floor(len * 720 / state.osd_h)
                    local seconds = math.floor(len * time.seconds / videoSlider.sliderLow.w)
                    mp.commandv('seek', seconds, 'absolute')
                end
            end

            -- vol-panel-icon
            if vol.volicon.x > 0 and state.vol_open and
                hit(x, y, vol.volicon.x, vol.volicon.y, vol.volicon.x1, vol.volicon.y1) then
                mp.commandv('cycle', 'mute')
            end
        end

        -- vol_drag
        if vol.volsliderBar.x > 0 and state.vol_open and action == 'mbtn_left_down' and
            hit(x, y, vol.volsliderBar.x, vol.volsliderBar.y, vol.volsliderBar.x + vol.volsliderBar.w,
                vol.volsliderBar.y + vol.volsliderBar.h) then
            vol.volsliderBar.drag = true
        end

        if vol.volsliderBar.drag and action == 'mouse_move' then
            local len = mouse_pos.x - math.floor(state.osd_h / 720 * vol.volslider.x)
            len = math.floor(len * 720 / state.osd_h)
            if len > 200 then len = 200 end
            if len < 0 then len = 0 end
            state.volume = math.floor(len / 2)
            vol.volsliderBar.x = vol.volslider.x + len - vol.volsliderBar.w / 2
            Element:panel(true, vol.volsliderBar, state)
            vol.volsliderTxt.icon = state.volume
            -- vol.volsliderTxt.x = vol.volsliderTxt.x + ( 42 - Element:bounds(state.volume, state.size)) / 2
            Element:button(true, vol.volsliderTxt, state)
        end

        if vol.volsliderBar.drag and action == 'mbtn_left_up' then
            vol.volsliderBar.drag = false
            mp.commandv('set', 'volume', state.volume)
        end

        -- video-drag
        if videoSlider.sliderBar.x > 0 and action == 'mbtn_left_down' and
            hit(x, y, videoSlider.sliderBar.x, videoSlider.sliderBar.y, videoSlider.sliderBar.x + videoSlider.sliderBar.w
                , videoSlider.sliderBar.y + videoSlider.sliderBar.h) then
            -- mp.set_property_native('pause', true)
            videoSlider.sliderBar.drag = true
        end

        if videoSlider.sliderBar.drag and action == 'mouse_move' then
            local len    = mouse_pos.x - math.floor(state.osd_h / 720 * videoSlider.sliderLow.x)
            len          = math.floor(len * 720 / state.osd_h)
            local maxLen = videoSlider.sliderLow.w
            if len > maxLen then len = maxLen end
            if len < 0 then len = 0 end
            local seconds = len * time.seconds / maxLen

            -- time.timer = mp.add_timeout(0.05, function() mp.commandv('seek', seconds, 'absolute+exact') end)
            time.cSeconds = seconds
            videoSlider.sliderUp.w = len
            videoSlider.sliderBar.x = videoSlider.sliderLow.x + len - state.silderH
            Element:panel(true, videoSlider.sliderUp, state)
            Element:panel(true, videoSlider.sliderBar, state)
            local _, icon = timeFormat(seconds)
            if seconds < 3600 and time.seconds > 3600 then
                icon = '00:' .. icon
            end
            videoSlider.startFile.icon = '' .. icon
            Element:button(true, videoSlider.startFile, state)

        end

        if videoSlider.sliderBar.drag and action == 'mbtn_left_up' then
            mp.commandv('seek', time.cSeconds, 'absolute')
            videoSlider.sliderBar.drag = false
            -- mp.set_property_native('pause', false)
            -- time.timer:kill()
        end

    end
end

function hover(mouseX, mouseY)
    if state.keep then
        local flag = false
        local hover_button
        local x = math.floor(mouseX * 720 / state.osd_h)
        local y = math.floor(mouseY * 720 / state.osd_h)
        -- main buttons
        for n, v in pairs(buttons) do
            if hit(x, y, v.x, v.y, v.x + state.size, v.y + state.size) then
                flag = true
                hover_button = buttons[n]
            end
        end

        local data = subs_audios[state.ccOrAudio]
        if state.ccOeAudio_open and data.count >= 1 and data.data[1] and data.data[1].x then
            for n, v in pairs(data.data) do
                if not v.selected and hit(x, y, v.x, v.y, v.x + v.w, v.y + v.h) then
                    flag = true
                    hover_button = data.data[n]
                end
            end
        end

        -- vol_panel_icon
        if vol.volicon.x > 0 and state.vol_open and
            hit(x, y, vol.volicon.x, vol.volicon.y, vol.volicon.x1, vol.volicon.y1) then
            flag = true
            hover_button = vol.volicon
        end
        Element:hover(flag, hover_button, state)

        -- sliderLow -- thumbfast
        if hit(x, y, videoSlider.sliderLow.x, videoSlider.sliderLow.y, videoSlider.sliderLow.x + videoSlider.sliderLow.w
            ,
            videoSlider.sliderLow.y + videoSlider.sliderLow.h) then
            -- videoSlider.sliderBar.drag = true
            if not thumbfast.disabled then
                local len = mouseX - math.floor(state.osd_h / 720 * videoSlider.sliderLow.x)
                len       = math.floor(len * 720 / state.osd_h)
                if len > videoSlider.sliderLow.w then len = videoSlider.sliderLow.w end
                if len < 0 then len = 0 end

                local seconds = len * time.seconds / videoSlider.sliderLow.w
                local y = math.floor(state.osd_h / 720 * state.panel_y) - 10 - thumbfast.height
                mp.commandv("script-message-to", "thumbfast", "thumb",
                    -- hovered time in seconds
                    seconds,
                    -- x
                    mouseX - thumbfast.width / 2,
                    -- y
                    y
                )
                -- thumbfast-time
                -- local _, icon = timeFormat(seconds)
                -- local len = Element:bounds(icon, state.font_size)
                -- Element:button(true, {
                --     id = 42,
                --     x = math.floor(mouseX * 720 / state.osd_h) - len / 2,
                --     y = state.panel_y,
                --     h = state.font_size,
                --     icon = icon
                -- }, state)
            end
        else
            if thumbfast.available then
                mp.commandv("script-message-to", "thumbfast", "clear")
                -- Element:button(false, { id = 42 }, state)
            end
        end
    end

end

function hide()
    -- main-panel
    Element:panel(false, { id = 62 }, state)
    -- main-panel-button
    for _, v in pairs(buttons) do
        Element:button(false, v, state)
    end
    exetral_panel_hide()
    vol_panel_hide(vol, state)
    -- videoSlider
    state.startFileVisble = false
    for _, v in pairs(videoSlider) do
        Element:button(false, v, state)
    end
    if state.streamNum > 1 then
        for i = 40, 40 + state.streamNum - 1 do
            Element:button(false, { id = i }, state)
        end
    end

    state.visible = true
    state.enable = false
end

function exetral_panel_hide()
    -- --hover
    Element:hover(false, { id = 61 }, state)
    -- extra_panel
    Element:panel(false, { id = 10 }, state)
    -- extra_panel_seleted
    Element:panel(false, { id = 11 }, state)
    -- extra_panel_text
    local data = subs_audios[state.ccOrAudio]
    if data.count >= 1 then
        for i = 1, data.count do
            Element:panel(false, { id = 20 + i }, state)
            Element:panel(false, { id = 30 + i }, state)
        end
    end
    state.ccOeAudio_open = false
end

-- function videoSlider()

-- end

function render()
    -- local w, h = mp.get_osd_size()
    -- local panel_x = w * 720 / h * 0.2
    -- local panel_w = w * 720 / h * 0.6
    -- local panel_y = h * 720 / h * 0.8
    -- if not state.visible then return end
    -- state.visible = true
    state.enable = true
    if state.visible then

        local panel_x = state.osd_w * 720 / state.osd_h * 0.2
        local panel_w = state.osd_w * 720 / state.osd_h * 0.6
        local panel_y = state.osd_h * 720 / state.osd_h * 0.8

        -- local w, h = mp.get_osd_size()
        -- local panel_x = w * 720 / h * 0.2
        -- local panel_w = w * 720 / h * 0.6
        -- local panel_y = h * 720 / h * 0.8

        state.panel_x = panel_x
        state.panel_y = panel_y
        state.panel_w = panel_w

        --  button
        for n, _ in pairs(buttons) do
            buttons[n].y = panel_y + (state.panel_h - state.size) / 2
        end
        buttons.play.x = panel_x + state.marginX / 2

        buttons.audio.x = buttons.play.x + state.size + state.marginX
        buttons.sub.x = buttons.audio.x + state.size + state.marginX
        buttons.volume.x = buttons.sub.x + state.size + state.marginX
        buttons.quit.x = panel_x + panel_w - state.size - state.marginX / 2
        for _, v in pairs(buttons) do
            Element:button(true, v, state)
        end

        -- panel
        Element:panel(true, {
            id = 62,
            hover_style = state.panel_style,
            x = panel_x,
            y = panel_y,
            w = panel_w,
            h = state.panel_h,
            z = 100,
        }, state)

        -- videlSlider
        ---- startFile
        local startFileX = buttons.volume.x + state.size + state.marginX
        local fileY = panel_y + (state.panel_h - state.font_size) / 2 + 2
        videoSlider.startFile.x = startFileX
        videoSlider.startFile.y = fileY
        -- videoSlider.startFile.icon = time.startFile
        Element:button(true, videoSlider.startFile, state)
        state.startFileVisble = true

        local length = time.seconds < 3600 and time.len1 or time.len2

        ---- endFile
        local endFileX = buttons.quit.x - state.marginX - length
        videoSlider.endFile.x = endFileX
        videoSlider.endFile.y = fileY
        -- videoSlider.endFile.icon = time.endFile
        Element:button(true, videoSlider.endFile, state)

        local ssX = startFileX + length + state.marginX
        local ssW = endFileX - ssX - state.marginX * 2
        ---- 滑轨底色
        videoSlider.sliderLow.x = ssX
        videoSlider.sliderLow.y = panel_y + (state.panel_h - state.silderH) / 2 + 1
        videoSlider.sliderLow.w = ssW
        Element:panel(true, videoSlider.sliderLow, state)
        ---- 滑轨
        videoSlider.sliderUp.x = ssX
        videoSlider.sliderUp.y = panel_y + (state.panel_h - state.silderH) / 2 + 1
        -- videoSlider.sliderUp.w = 100 -- 走过的时间
        Element:panel(true, videoSlider.sliderUp, state)
        ---- 滑块
        videoSlider.sliderBar.x = ssX - state.silderH
        videoSlider.sliderBar.y = videoSlider.sliderUp.y - state.silderH / 2
        Element:panel(true, videoSlider.sliderBar, state)
        -- print(time.seconds, ssW / time.seconds, ssW)
        -- cache
        videoSlider.sliderCache.y = panel_y + (state.panel_h - state.silderH) / 2 + 1

        --auto hide
        state.timer = mp.add_timeout(0, hide)
        state.timer:kill()
        state.timer.timeout = 1
        state.timer:resume()
        state.visible = false
    else
        --auto hide
        local mouse_pos = mp.get_property_native('mouse-pos')
        local x = mouse_pos.x * 720 / state.osd_h
        local y = mouse_pos.y * 720 / state.osd_h

        local x1, y1 = math.floor(state.osd_w * 0.2), math.floor(state.osd_h * 0.8)
        local x2, y2 = x1 + math.floor(state.osd_w * 0.6), y1 + math.floor(state.osd_h / 720 * state.panel_h)
        state.keep = hit(x, y, state.panel_x, state.panel_y, state.panel_x + state.panel_w, state.panel_y + state.panel_h)
            or
            (
            state.ccOeAudio_open and
                hit(x, y, state.extra_panel.x1, state.extra_panel.y1, state.extra_panel.x2, state.extra_panel.y2))
            or
            (state.vol_open and hit(x, y, vol.volpanel.x, vol.volpanel.y, vol.volpanel.x1, vol.volpanel.y1))

        if state.keep then
            state.timer:kill()
        else
            state.timer:kill()
            state.timer.timeout = 1
            state.timer:resume()
        end

    end
    do_enable_keybindings()
end

function dispatch(source, what)
    local action = string.format("%s%s", source, what and ("_" .. what) or "")

    if action == 'mouse_move' then
        local mouse_pos = mp.get_property_native('mouse-pos')
        hover(mouse_pos.x, mouse_pos.y)
        render()
    end
    -- if action == 'mbtn_left_down' then
    click(action)
    -- end
end

function do_enable_keybindings()
    if state.keep then
        mp.enable_key_bindings("input")
    else
        mp.disable_key_bindings("input")
        mp.enable_key_bindings("mouse", "allow-vo-dragging+allow-hide-cursor")
    end

end

mp.set_key_bindings({
    -- { "mbtn_left", function(e) dispatch("mbtn_left", "up") end, function(e) dispatch("mbtn_left", "down") end },
    { "mouse_move", function(e) dispatch("mouse_move", nil) end },
    -- { "mbtn_left", click },
    -- { "mouse_move", render },
}, "mouse", "force")
-- do_enable_keybindings()
mp.set_key_bindings({
    { "mbtn_left", function(e) dispatch("mbtn_left", "up") end, function(e) dispatch("mbtn_left", "down") end },
}, "input", "force")
mp.enable_key_bindings("input")

mp.observe_property('osd-dimensions', 'native', function(_, val)
    -- local w, h = mp.get_osd_size()
    if val.w ~= 0 then
        state.osd_w = val.w
        state.osd_h = val.h
        render()
        cache_render()
    end
end)

mp.observe_property("playback-time", "number", function(_, val)
    if val ~= nil then
        local _, cTime = timeFormat(val)
        -- time.cSeconds = val
        local icon = cTime
        if val < 3600 and time.seconds > 3600 then
            icon = '00:' .. cTime
        end
        if state.startFileVisble and not videoSlider.sliderBar.drag then
            -- if state.startFileVisble then
            videoSlider.startFile.icon = '' .. icon
            Element:button(true, videoSlider.startFile, state)
            local w                 = videoSlider.sliderLow.w
            local length            = math.floor(val * w / time.seconds)
            videoSlider.sliderUp.w  = length + state.silderH
            videoSlider.sliderBar.x = videoSlider.sliderLow.x + length - state.silderH / 2
            Element:panel(true, videoSlider.sliderUp, state)
            Element:panel(true, videoSlider.sliderBar, state)
        end
    end
end)

mp.observe_property("duration", "number", function(_, val)
    if val ~= nil then
        time.seconds = val
        local s, e = timeFormat(val)
        videoSlider.startFile.icon = '' .. s
        videoSlider.endFile.icon = '' .. e
        -- time.len = Element:bounds(e, state.font_size)
        -- state.visible = true
        -- state.timer = mp.add_timeout(0, hide)
        -- state.timer:kill()
        -- render()
        if state.startFileVisble then
            Element:button(true, videoSlider.endFile, state)
        end
    end
end)

-- mp.observe_property('mouse-pos', 'native', function(_, val)
--     -- hover(val.x, val.y)
--     -- render()
-- end)

mp.observe_property("pause", "bool", function(_, val)
    if buttons.play.x == 0 then return end
    if val then
        buttons.play.icon = icons.play
    else
        buttons.play.icon = icons.pause
    end
    if state.enable then
        mp.add_timeout(0.05, function() Element:button(true, buttons.play, state) end)
    end

end)

mp.observe_property('track-list', 'native', function(name, value)
    local types = { sub = 0, audio = 0 }
    for _, track in pairs(value) do
        if track.type == 'sub' then
            types[track.type] = types[track.type] + 1
            local title = track.title and track.title or ''
            local lang = track.lang and track.lang or ''
            title = title == '' and lang or title
            local text = track.codec
            local len = title == '' and 0 or Element:bounds(title .. ',,', state.font_size)
            local text_len = Element:bounds(text, state.font_size)
            subs_audios['sub'].data[track['id'] + 1] = {
                id = track['id'],
                selected = track.selected,
                title = title .. '   ',
                text = text,
                len = len + text_len,
                text_len = text_len,
            }
        elseif track.type == 'audio' then
            types[track.type] = types[track.type] + 1
            local ch = track['audio-channels'] .. 'Ch'
            local rate = track['demux-samplerate'] / 1000 .. 'KHz'
            local title = track.title and track.title or ''
            local lang = track.lang and track.lang or ''
            title = title == '' and lang or title
            local text = track.codec .. ', ' .. ch .. ', ' .. rate
            local len = title == '' and 0 or Element:bounds(title .. ',,', state.font_size)
            local text_len = Element:bounds(text, state.font_size)
            subs_audios['audio'].data[track['id']] = {
                id = track['id'],
                selected = track.selected,
                title = title .. '   ',
                text = text,
                len = len + text_len,
                text_len = text_len,
            }
        end
    end
    subs_audios['sub'].count = types.sub + 1
    subs_audios['audio'].count = types.audio
end)

mp.observe_property("mute", 'bool', function(_, _)
    if state.vol_open then
        vol.volicon.icon = vol_icon()
        Element:button(true, vol.volicon, state)
        buttons.volume.icon = vol_icon()
        Element:button(true, buttons.volume, state)
    end
end)

mp.observe_property("volume", 'number', function(_, val)
    state.volume = val
    -- if state.vol_open then
    Element:panel(true, vol.volsliderBar, state, not state.vol_open)
    vol.volsliderTxt.icon = state.volume
    Element:button(true, vol.volsliderTxt, state, not state.vol_open)
    vol.volicon.icon = vol_icon()
    Element:button(true, vol.volicon, state, not state.vol_open)
    buttons.volume.icon = vol_icon()
    Element:button(true, buttons.volume, state, not state.vol_open)
    vol.volsliderBar.x = vol.volslider.x + val * 2 - vol.volsliderBar.w / 2
    Element:panel(true, vol.volsliderBar, state, not state.vol_open)
    -- end
end)

-- mp.observe_property("demuxer-cache-state", 'native', function(name, val)
--         for k, v in pairs(val) do
--             print(k, v)
--         end
-- end)

mp.register_script_message("thumbfast-info", function(json)
    local data = utils.parse_json(json)
    if type(data) ~= "table" or not data.width or not data.height then
        msg.error("thumbfast-info: received json didn't produce a table with thumbnail information")
    else
        thumbfast = data
    end
end)

mp.observe_property('demuxer-via-network', 'native', function(_, val)
    if val then
        state.isStream = true
    end
end)

function cache_render()
    if state.isStream then
        mp.observe_property('demuxer-cache-state', 'native', function(_, cache_state)
            if cache_state then
                -- for name, range in pairs(cache_state) do
                --     print(name, range)
                -- end
                local ranges = cache_state['seekable-ranges']
                local num = 0
                for _, v in pairs(ranges) do
                    --缓冲渲染
                    local start_cache, end_cache = v['start'], v['end']
                    if end_cache - start_cache ~= 0 and state.startFileVisble then
                        local x = start_cache == 0 and videoSlider.sliderLow.x or
                            videoSlider.sliderLow.x + math.floor(start_cache * videoSlider.sliderLow.w / time.seconds)
                        local w = math.floor((end_cache - start_cache) * videoSlider.sliderLow.w / time.seconds)
                        videoSlider.sliderCache.x = x
                        videoSlider.sliderCache.w = w
                        videoSlider.sliderCache.id = 40 + num
                        Element:panel(true, videoSlider.sliderCache, state)
                    end
                    num = num + 1
                end
                -- if cache_state["underrun"] then

                -- print(1111)

                -- end
                if num > state.streamNum then
                    state.streamNum = num
                end
                -- print(range['start'], range['end'], cache_state['bof-cached'], cache_state['eof-cached'])
            end
        end)
    end
end
