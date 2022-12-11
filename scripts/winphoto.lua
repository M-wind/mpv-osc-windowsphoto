local utils = require 'mp.utils'
local osd = mp.create_osd_overlay("ass-events")

package.path = mp.find_config_file('scripts') .. '/?.lua'
require('winphoto.Config')
require('winphoto.Utils')
local Element = require('winphoto.Element')
local Elements = {}
local EleVol, EleSub, EleAudio = {}, {}, {}
local sub, audio = {}, {}
local id = { main = 1, hover = 2, sub = 3, audio = 4, volume = 5 }
local state = {
    volume = 100,
    volumeMax = 130,
    volumeTextLen = math.floor(Bounds('130', FontSize)),
    timer,
    play = false,
    enable = true,
}
local time = { seconds = 0, duration = 0, len1 = Bounds('00:00', FontSize2), len2 = Bounds('00:00:00', FontSize2) }
local open = { keep = false, mainPanel = true, sub = false, audio = false, volume = false }
local thumbfast = {
    width = 0,
    height = 0,
    disabled = true,
    available = false
}
local press = { vol = false, video = false }
local function render(tId, data)
    local text = ''
    local a = SortById(data)
    for _, v in pairs(a) do
        if data[v].type == 'panel' then
            text = text .. data[v].ele.panel() .. '\n'
        elseif data[v].type == 'button' or data[v].type == 'text' then
            text = text .. data[v].ele.txt() .. '\n'
        elseif data[v].type == 'cache' then
            if data[v].ele.info.w > 1 then
                text = text .. data[v].ele.panel() .. '\n'
            end
        end
    end
    osd.id = tId
    osd.data = text
    osd.z = 1000
    osd:update()
end

local function mainRender()
    render(id.main, Elements)
end

local function hoverRender(ele, style)
    osd.id = id.hover
    osd.data = ele.panel({ style = style, raduis = PanelR })
    osd.z = 1001
    osd:update()
end

local function remove(id)
    osd.id = id
    osd:remove()
end

local function do_enable_keybindings()
    if open.keep then
        mp.enable_key_bindings("input")
    else
        mp.disable_key_bindings("input")
        mp.enable_key_bindings("mouse", "allow-vo-dragging+allow-hide-cursor")
    end
end

local function init()
    local W, H = mp.get_osd_size()
    local mainX = math.floor(W * 720 / H * 0.2)
    local mainY = math.floor(H * 720 / H * 0.8)
    local mainW = math.floor(W * 720 / H * 0.6)
    local mainH = PanelH
    local main = Element.new(mainX, mainY, mainW, mainH, Style.panel, '', PanelR)
    local Y = main.info.y + (main.info.h - FontSize) / 2
    local play = Element.new(main.info.x + Margin, Y, FontSize, FontSize, Style.text, Icons.pause)
    local audio = Element.new(play.info.x + play.info.w + Margin, Y, FontSize, FontSize, Style.text, Icons.audio)
    local sub = Element.new(audio.info.x + audio.info.w + Margin, Y, FontSize, FontSize, Style.text, Icons.sub)
    local volume = Element.new(sub.info.x + sub.info.w + Margin, Y, FontSize, FontSize, Style.text, VolIcon(state.volume))
    local quit = Element.new(main.info.x + main.info.w - FontSize - Margin, Y, FontSize, FontSize, Style.text, Icons.quit)
    local length = time.duration < 3600 and time.len1 or time.len2
    local ty = main.info.y + (main.info.h - FontSize2) / 2 + 1.5
    local _, sTime = TimeFormat(time.seconds)
    local _, eTime = TimeFormat(time.duration)
    local startT, endT = sTime, eTime
    if time.seconds < 3600 and time.duration > 3600 then
        startT = '00:' .. sTime
    end
    local startTime = Element.new(volume.info.x + volume.info.w + Margin, ty, length, FontSize2, Style.text, startT)
    local endTime = Element.new(quit.info.x - Margin - length, ty, length, FontSize2, Style.text, endT)
    local ssx = startTime.info.x + length + Margin
    local ssw = endTime.info.x - ssx - Margin - 5
    local by = main.info.y + (main.info.h - SliderH) / 2 + 1
    local videoLow = Element.new(ssx, by, ssw, SliderH, Style.low, '', SliderR)
    local distance = time.duration == 0 and 0 or math.floor(time.seconds * videoLow.info.w / time.duration)
    local videoUp = Element.new(ssx, by, distance, SliderH, Style.up, '', SliderR)
    local videoBar = Element.new(ssx - BarW / 2 + distance, by - (BarH - videoLow.info.h) / 2, BarW, BarH, Style.up,
        '', BarR)
    Elements = {}
    Elements['main'] = { id = 1, type = 'panel', ele = main }
    Elements['play'] = { id = 2, type = 'button', ele = play, click = true }
    Elements['audio'] = { id = 3, type = 'button', ele = audio, click = true }
    Elements['sub'] = { id = 4, type = 'button', ele = sub, click = true }
    Elements['volume'] = { id = 5, type = 'button', ele = volume, click = true }
    Elements['startTime'] = { id = 6, type = 'text', ele = startTime }
    Elements['videoLow'] = { id = 7, type = 'panel', ele = videoLow, click = true }
    Elements['endTime'] = { id = 8, type = 'text', ele = endTime }
    Elements['quit'] = { id = 9, type = 'button', ele = quit, click = true }
    Elements['videoUp'] = { id = 10, type = 'panel', ele = videoUp }
    Elements['videoBar'] = { id = 20, type = 'panel', ele = videoBar }
end

local function hover()
    local mouse_pos = mp.get_property_native('mouse-pos')
    local x = math.floor(mouse_pos.x * 720 / H)
    local y = math.floor(mouse_pos.y * 720 / H)
    local flag = false
    local ele
    for _, v in pairs(Elements) do
        if v.type == 'button' and v.ele.mouseIn(x, y) then
            -- local style = k == 'quit' and '{\\1c&H3E3EE5&\\1a&HE0&\\3a&HDF&\\bord0}' or Style.hover
            flag = true
            ele = v.ele
            break
        end
    end
    if open.volume and EleVol['volIcon'].ele.mouseIn(x, y) then
        flag = true
        ele = EleVol['volIcon'].ele
    end
    if not flag and open.sub then
        for _, v in pairs(EleSub) do
            if v.type == 'hover' and not v.selected and v.ele.mouseIn(x, y) then
                flag = true
                ele = v.ele
                break
            end
        end
    end

    if not flag and open.audio then
        for _, v in pairs(EleAudio) do
            if v.type == 'hover' and not v.selected and v.ele.mouseIn(x, y) then
                flag = true
                ele = v.ele
                break
            end
        end
    end

    if flag then hoverRender(ele, Style.hover) else remove(id.hover) end

    --thumbfast
    if time.duration ~= 0 and Elements['videoLow'].ele.mouseIn(x, y) then
        if not thumbfast.disabled then
            local len = x - Elements['videoLow'].ele.info.x
            local seconds = math.floor(len * time.duration / Elements['videoLow'].ele.info.w)
            local y = math.floor(H / 720 * Elements['main'].ele.info.y) - 10 - thumbfast.height
            mp.commandv("script-message-to", "thumbfast", "thumb",
                -- hovered time in seconds
                seconds,
                -- x
                math.floor(H / 720 * x) - thumbfast.width / 2,
                -- y
                y
            )
        end
    else
        if thumbfast.available then
            mp.commandv("script-message-to", "thumbfast", "clear")
        end
    end
end

local function volumeHide()
    remove(id.volume)
    open.volume = false
end

local function subHide()
    remove(id.sub)
    open.sub = false
end

local function audioHide()
    remove(id.audio)
    open.audio = false
end

local function hide()
    remove(id.main)
    remove(id.hover)
    volumeHide()
    subHide()
    audioHide()
    open.mainPanel = true
    state.enable = false
end

local function volumeRender()
    render(id.volume, EleVol)
end

local function subRender()
    render(id.sub, EleSub)
end

local function audioRender()
    render(id.audio, EleAudio)
end

local function volumeInit()
    if EleVol['volMain'] ~= nil then return end
    local x, y = Elements['volume'].ele.info.x, Elements['main'].ele.info.y
    local mainW = Margin * 4 + FontSize + 195 + state.volumeTextLen
    local mainX = x - mainW / 2
    local mainY = y - PanelH - 0.3
    local mainH = PanelH
    local main = Element.new(mainX, mainY, mainW, mainH, Style.panel, '', PanelR)
    local icon = Element.new(mainX + Margin, mainY + (mainH - FontSize) / 2, FontSize, FontSize, Style.text,
        VolIcon(state.volume))
    local low = Element.new(icon.info.x + icon.info.w + Margin, mainY + (mainH - SliderH) / 2 + 1.5, 195, SliderH,
        Style.low, '', SliderR)
    local w = state.volume * low.info.w / state.volumeMax
    local up = Element.new(low.info.x, low.info.y, w, SliderH, Style.up, '', SliderR)
    local bar = Element.new(low.info.x + w - BarW / 2, low.info.y - (BarH - low.info.h) / 2, BarW, BarH, Style.up, ''
        , BarR)
    local a_x = low.info.x + low.info.w + Margin
    local len = Bounds('' .. state.volume, FontSize)
    local text = Element.new(a_x + (state.volumeTextLen - len) / 2, mainY + (mainH - FontSize) / 2 + 1, len,
        FontSize,
        Style.text, state.volume)
    EleVol['volMain'] = { id = 1, type = 'panel', ele = main }
    EleVol['volIcon'] = { id = 2, type = 'button', ele = icon, click = true }
    EleVol['volLow'] = { id = 3, type = 'panel', ele = low, click = true }
    EleVol['volUp'] = { id = 4, type = 'panel', ele = up }
    EleVol['volBar'] = { id = 5, type = 'panel', ele = bar }
    EleVol['volText'] = { id = 6, type = 'text', ele = text }
end

local function subInit()
    if EleSub['subMain'] ~= nil then return end
    local x1, y1 = Elements['sub'].ele.info.x, Elements['main'].ele.info.y
    local maxLen = sub.data[1].len
    for _, v in pairs(sub.data) do
        if v.len > maxLen then maxLen = v.len end
    end
    local gap = 1
    local itemH = FontSize2 + Margin / 2
    local w = math.floor(maxLen) + Margin * 2
    local x = x1 - w / 2
    local h = sub.count * itemH + Margin + (sub.count - 1) * gap
    local y = y1 - h
    local main = Element.new(x, y, w, h, Style.panel, '', PanelR)
    EleSub['subMain'] = { id = 1, type = 'panel', ele = main }
    for i = 1, sub.count do
        if sub.data[i].selected then
            EleSub['selected'] = { id = 2, type = 'panel',
                ele = Element.new(x + Margin / 2, y + Margin / 2 + (itemH + gap) * (i - 1), math.floor(maxLen) + Margin,
                    itemH, Style.hover, '', PanelR)
            }
        end
        EleSub['subHover' .. (i + sub.count)] = { id = 2 + i + sub.count * 2, type = 'hover', click = true,
            selected = sub.data[i].selected, tId = sub.data[i].id,
            ele = Element.new(x + Margin / 2, y + Margin / 2 + (itemH + gap) * (i - 1), math.floor(maxLen) + Margin,
                itemH, Style.hover, '', PanelR)
        }
        EleSub['sub' .. i] = { id = 2 + i, type = 'text',
            ele = Element.new(x + Margin, y + Margin + (itemH + gap) * (i - 1) - (itemH - FontSize2) / 2, FontSize2,
                FontSize2, Style.text, sub.data[i].title)
        }
        EleSub['sub' .. (i + sub.count)] = { id = 2 + i + sub.count, type = 'text',
            ele = Element.new(x + w - Margin / 2 - sub.data[i].text_len,
                y + Margin + (itemH + gap) * (i - 1) - (itemH - FontSize2) / 2, FontSize2,
                FontSize2, Style.text, sub.data[i].text)
        }

    end
end

local function audioInit()
    if EleAudio['audioMain'] ~= nil then return end
    local x1, y1 = Elements['audio'].ele.info.x, Elements['main'].ele.info.y
    local maxLen = audio.data[1].len
    for _, v in pairs(audio.data) do
        if v.len > maxLen then maxLen = v.len end
    end
    local gap = 1
    local itemH = FontSize2 + Margin / 2
    local w = math.floor(maxLen) + Margin * 2
    local x = x1 - w / 2
    local h = audio.count * itemH + Margin + (audio.count - 1) * gap
    local y = y1 - h
    local main = Element.new(x, y, w, h, Style.panel, '', PanelR)
    EleAudio['audioMain'] = { id = 1, type = 'panel', ele = main }
    for i = 1, audio.count do
        if audio.data[i].selected then
            EleAudio['selected'] = { id = 2, type = 'panel',
                ele = Element.new(x + Margin / 2, y + Margin / 2 + (itemH + gap) * (i - 1), math.floor(maxLen) + Margin,
                    itemH, Style.hover, '', PanelR)
            }
        end
        EleAudio['audioHover' .. i] = { id = 2 + i + audio.count * 2, type = 'hover', click = true,
            selected = audio.data[i].selected, tId = audio.data[i].id,
            ele = Element.new(x + Margin / 2, y + Margin / 2 + (itemH + gap) * (i - 1), math.floor(maxLen) + Margin,
                itemH, Style.hover, '', PanelR)
        }
        EleAudio['audio' .. i] = { id = 2 + i, type = 'text',
            ele = Element.new(x + Margin, y + Margin + (itemH + gap) * (i - 1) - (itemH - FontSize2) / 2, FontSize2,
                FontSize2, Style.text, audio.data[i].title)
        }
        EleAudio['audio' .. (i + audio.count)] = { id = 2 + i + audio.count, type = 'text',
            ele = Element.new(x + w - Margin / 2 - audio.data[i].text_len,
                y + Margin + (itemH + gap) * (i - 1) - (itemH - FontSize2) / 2, FontSize2,
                FontSize2, Style.text, audio.data[i].text)
        }

    end
end

local function autoRender()
    if open.mainPanel then
        state.enable = true
        mainRender()
        state.timer = mp.add_timeout(0, hide)
        state.timer:kill()
        state.timer.timeout = 1
        state.timer:resume()
        open.mainPanel = false
    else
        local mouse_pos = mp.get_property_native('mouse-pos')
        local x = mouse_pos.x * 720 / H
        local y = mouse_pos.y * 720 / H
        open.keep = Elements['main'].ele.mouseIn(x, y)
            or (open.volume and EleVol['volMain'].ele.mouseIn(x, y))
            or (open.sub and EleSub['subMain'].ele.mouseIn(x, y))
            or (open.audio and EleAudio['audioMain'].ele.mouseIn(x, y))
        if open.keep then
            state.timer:kill()
        else
            state.timer:kill()
            state.timer.timeout = 1
            state.timer:resume()
        end
    end
    do_enable_keybindings()
end

local function button_click(name, x, y)
    local switchStr = {
        quit = function()
            mp.commandv('quit')
        end,
        play = function()
            mp.set_property_bool("pause", not mp.get_property_bool("pause"))
        end,
        videoLow = function()
            local len     = x - Elements['videoLow'].ele.info.x
            local seconds = math.floor(len * time.duration / Elements['videoLow'].ele.info.w)
            mp.commandv('seek', seconds, 'absolute+exact')
        end,
        audio = function()
            if audio.count < 2 then return end
            if open.audio then
                audioHide()
            else
                open.audio = true
                if open.volume then volumeHide() end
                if open.sub then subHide() end
                audioInit()
                audioRender()
            end
        end,
        sub = function()
            if open.sub then
                subHide()
            else
                open.sub = true
                if open.volume then volumeHide() end
                if open.audio then audioHide() end
                subInit()
                subRender()
            end
        end,
        volume = function()
            if open.volume then
                volumeHide()
            else
                open.volume = true
                if open.sub then subHide() end
                if open.audio then audioHide() end
                volumeInit()
                volumeRender()
            end
        end,
        volIcon = function()
            mp.commandv('cycle', 'mute')
        end,
        volLow = function()
            local len = x - EleVol['volLow'].ele.info.x
            local vol = math.floor(len * state.volumeMax / EleVol['volLow'].ele.info.w + 0.5)
            mp.commandv('set', 'volume', vol)
        end,
    }
    local isExit = switchStr[name]
    if isExit then
        switchStr[name]()
    end
end

local function subAudioSelect(tId, type)
    if tId == 'load' then
        OpenFileDialog()
    else
        mp.commandv('set', type, tId)
    end
    remove(id.hover)
end

local function click(action)
    local mouse_pos = mp.get_property_native('mouse-pos')
    local x = math.floor(mouse_pos.x * 720 / H)
    local y = math.floor(mouse_pos.y * 720 / H)
    if action == 'mbtn_left_up' and not press.vol and not press.video then
        for k, v in pairs(Elements) do
            if v.click and v.ele.mouseIn(x, y) then button_click(k, x, y) return end
        end
        if open.volume then
            for k, v in pairs(EleVol) do
                if v.click and v.ele.mouseIn(x, y) then button_click(k, x, y) return end
            end
        end
        if open.audio then
            for _, v in pairs(EleAudio) do
                if v.type == 'hover' and v.ele.mouseIn(x, y) then
                    subAudioSelect(v.selected and 'no' or v.tId, 'audio')
                    audioHide()
                    return
                end
            end
        end
        if open.sub then
            for _, v in pairs(EleSub) do
                if v.type == 'hover' and v.ele.mouseIn(x, y) then
                    subAudioSelect(v.selected and 'no' or v.tId, 'sub')
                    subHide()
                    return
                end
            end
        end
    end
    if action == 'mbtn_left_down' then
        if open.volume and EleVol['volBar'].ele.mouseIn(x, y) then
            press.vol = true
        end
        if time.duration ~= 0 and Elements['videoBar'].ele.mouseIn(x, y) then
            press.video = true
        end
    end

    if press.vol and action == 'mouse_move' then
        local len = x - EleVol['volLow'].ele.info.x
        if len < 0 then len = 0 end
        if len > EleVol['volLow'].ele.info.w then len = EleVol['volLow'].ele.info.w end
        local vol = math.floor(len * state.volumeMax / EleVol['volLow'].ele.info.w + 0.5)
        mp.commandv('set', 'volume', vol)
    end

    if press.vol and action == 'mbtn_left_up' then
        press.vol = false
        return
    end

    if press.video and action == 'mouse_move' then
        local length = x - Elements['videoLow'].ele.info.x
        local seconds = math.floor(length * time.duration / Elements['videoLow'].ele.info.w)
        if length < 0 then seconds = 0
            length = 0
        end
        if length > Elements['videoLow'].ele.info.w then seconds = time.duration
            length = Elements['videoLow'].ele.info.w
        end
        -- mp.commandv('seek', seconds, 'absolute+keyframes')

        time.seconds = seconds
        Elements['videoUp'].ele.info.w = length
        Elements['videoBar'].ele.info.x = Elements['videoLow'].ele.info.x + length -
            Elements['videoBar'].ele.info.w / 2
        local _, text = TimeFormat(seconds)
        if seconds < 3600 and time.duration > 3600 then text = '00:' .. text end
        Elements['startTime'].ele.info.text = text
        mainRender()
    end

    if press.video and action == 'mbtn_left_up' then
        press.video = false
        mp.commandv('seek', time.seconds, 'absolute+exact')
        return
    end

end

local function dispatch(source, what)
    local action = string.format("%s%s", source, what and ("_" .. what) or "")

    if action == 'mouse_move' then
        -- local mouse_pos = mp.get_property_native('mouse-pos')
        autoRender()
        if open.keep then hover() end
    end
    if open.keep then click(action) end
end

mp.set_key_bindings({
    { "mouse_move", function(e) dispatch("mouse_move", nil) end },
    { "mbtn_left_dbl", 'ignore' },
}, "mouse", "force")
mp.set_key_bindings({
    { "mbtn_left", function(e) dispatch("mbtn_left", "up") end, function(e) dispatch("mbtn_left", "down") end },
    { "mbtn_left_dbl", 'ignore' },
}, "input", "force")
mp.enable_key_bindings("input")

mp.observe_property('osd-dimensions', 'native', function(_, val)
    if val.w == 0 then return end
    W, H = val.w, val.h
    init()
    if state.enable then autoRender() end
end)

mp.observe_property("duration", "number", function(_, val)
    if val == nil then return end
    local _, e1 = TimeFormat(time.duration)
    time.duration = val
    local _, e = TimeFormat(val)
    if #e1 ~= #e then init() end
    Elements['endTime'].ele.info.text = e
    if state.enable then mainRender() end
end)

mp.observe_property("playback-time", "number", function(_, val)
    if val == nil or Elements['videoBar'].press then return end
    time.seconds = val
    local _, cTime = TimeFormat(val)
    local text = cTime
    if val < 3600 and time.duration > 3600 then
        text = '00:' .. cTime
    end
    Elements['startTime'].ele.info.text = text
    local length                        = math.floor(val * Elements['videoLow'].ele.info.w / time.duration)
    Elements['videoUp'].ele.info.w      = length
    Elements['videoBar'].ele.info.x     = Elements['videoLow'].ele.info.x + length -
        Elements['videoBar'].ele.info.w / 2
    if state.enable then mainRender() end
end)

mp.observe_property("pause", "bool", function(_, val)
    if Elements['play'] == nil then return end
    Elements['play'].ele.info.text = val and Icons.play or Icons.pause
    if not state.enable then return end
    mp.add_timeout(0.05, function() mainRender() end)
end)

mp.observe_property('volume-max', 'native', function(_, val)
    state.volumeMax = val
    state.volumeTextLen = math.floor(Bounds('' .. val, FontSize))
end)

mp.observe_property('volume', 'native', function(_, val)
    state.volume = val
    if Elements['volume'] == nil then return end
    Elements['volume'].ele.info.text = VolIcon(val)
    if EleVol['volMain'] ~= nil then
        local len = math.floor(val * EleVol['volLow'].ele.info.w / state.volumeMax)
        EleVol['volIcon'].ele.info.text = VolIcon(val)
        EleVol['volUp'].ele.info.w = len
        EleVol['volBar'].ele.info.x = EleVol['volLow'].ele.info.x + len - EleVol['volBar'].ele.info.w / 2
        local a_x = EleVol['volLow'].ele.info.x + EleVol['volLow'].ele.info.w + Margin
        local len = Bounds('' .. val, FontSize)
        EleVol['volText'].ele.info.x = a_x + (state.volumeTextLen - len) / 2
        EleVol['volText'].ele.info.text = val
    end
    if state.enable then
        volumeRender()
        mainRender()
    end

end)

mp.observe_property("mute", 'bool', function(_, _)
    if open.volume then
        EleVol['volIcon'].ele.info.text = VolIcon(state.volume)
        Elements['volume'].ele.info.text = VolIcon(state.volume)
        volumeRender()
        mainRender()
    end
end)

local function sub_pure(track)
    local title = track.title and track.title or 'Text'
    local text = track.codec
    local title_len = Bounds(title .. ',,', FontSize2)
    local text_len = Bounds(text, FontSize2)
    sub.data[track['id'] + 1] = {
        id = track['id'],
        selected = track.selected,
        title = title,
        text = text,
        len = title_len + text_len,
        text_len = text_len,
    }
    sub.count = sub.count + 1
end

local function audio_pure(track)
    local ch = track['audio-channels'] .. 'Ch'
    local rate = track['demux-samplerate'] / 1000 .. 'KHz'
    local title = track.title and track.title or ''
    local text = track.codec .. ' ' .. ch .. ' ' .. rate
    local title_len = title == '' and 0 or Bounds(title .. ',,', FontSize2)
    local text_len = Bounds(text, FontSize2)
    audio.data[track['id']] = {
        id = track['id'],
        selected = track.selected,
        title = title,
        text = text,
        len = title_len + text_len,
        text_len = text_len,
    }
    audio.count = audio.count + 1
end

mp.observe_property('track-list', 'native', function(_, val)
    sub = { count = 1, data = {
        [1] = {
            id = 'load', selected = false, title = '选择字幕文件...',
            text = '', len = Bounds('选择字幕文件...', FontSize2),
            text_len = 0
        }
    } }
    audio = { count = 0, data = {} }
    EleSub, EleAudio = {}, {}
    for _, track in pairs(val) do
        if track.type == 'sub' then sub_pure(track) end
        if track.type == 'audio' then audio_pure(track) end
    end
end)

mp.observe_property('demuxer-via-network', 'native', function(_, val)
    if not val then return end
    mp.observe_property('demuxer-cache-state', 'native', function(_, cache_state)
        if cache_state then
            local ranges = cache_state['seekable-ranges']
            for k, v in pairs(ranges) do
                --缓冲渲染
                local start_cache, end_cache = v['start'], v['end']
                local x = start_cache == 0 and Elements['videoLow'].ele.info.x or
                    Elements['videoLow'].ele.info.x +
                    math.floor(start_cache * Elements['videoLow'].ele.info.w / time.duration)
                local w = math.floor((end_cache - start_cache) * Elements['videoLow'].ele.info.w /
                    time.duration)
                Elements['videoCache' .. k] = { id = 11 + k, type = 'cache',
                    ele = Element.new(x, Elements['videoLow'].ele.info.y, w, SliderH, Style.cache, '', SliderR)
                }
            end
        end
    end)
end)

mp.register_script_message("thumbfast-info", function(json)
    local data = utils.parse_json(json)
    if type(data) ~= "table" or not data.width or not data.height then
        msg.error("thumbfast-info: received json didn't produce a table with thumbnail information")
    else
        thumbfast = data
    end
end)
