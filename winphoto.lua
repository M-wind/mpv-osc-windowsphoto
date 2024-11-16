-- mp.set_property("osd-font", "JetBrains Mono")
local utils = require("mp.utils")
local assdraw = require("mp.assdraw")
local osd = mp.create_osd_overlay("ass-events")
local ass = assdraw.ass_new()

local state = {
  visibility = false,
  sub_visibility = false,
  audio_visibility = false,
  vol_visibility = false,
  keep = false,
  press = {
    time_pointer = false,
    vol_pointer = false,
  },
}

local size = {
  w = 0,
  h = 0,
  iconsize = 30,
  textsize = 18,
  panel_raduis = 4,
  panel_x = 0,
  panel_y = 0,
  panel_w = 0,
  panel_h = 44,
  icon_y = 0,
  text_y = 0,
  bar_y = 0,
  margin = 12,
  time_bar_h = 4,
  time_bar_raduis = 2,
  time_pointer_h = 8,
  time_pointer_raduis = 4,
  vol_panel_x = 0,
  vol_panel_y = 0,
  vol_panel_w = 240,
  vol_low_w = 130,
  vol_panel_h = 40,
  item_h = 24,
  item_gap = 4,
  sub_panel_x = 0,
  sub_panel_y = 0,
  sub_panel_w = 130,
  sub_panel_h = 0,
  audio_panel_x = 0,
  audio_panel_y = 0,
  audio_panel_w = 225,
  audio_panel_h = 0,
}

local vol = { cur = 0, max = 0, mute = false }

local time = { playback = 0, duration = 0, len = 45 }

local id = { panel = 1, hover = 2, thumb = 3, vol = 4, sub = 5, audio = 6 }

local sub_list = {}
local audio_list = {}

local icons = {
  play = "\xee\x99\xae",
  pause = "\xee\x98\x80",
  audio = "\xee\x98\x8e",
  vol_low = "\xee\xa1\x90",
  vol_mute = "\xee\xa1\x8f",
  vol_full = "\xee\xa1\x8e",
  sub = "\xee\x9a\xa0",
  quit = "\xee\x98\x9b",
}


local style = {
  hover = "\\1c&HFFFFFF&\\1a&HE0&\\3a&HDF&\\bord0",
  panel = "\\1c&H2C2C2C&\\1a&H10&\\3a&H15&\\bord0.3",
  bar_low = "\\1c&H808080&\\bord0",
  bar_up = "\\1c&HFFFFFF&\\bord0",
  bar_cache = "\\1c&HD0D5B5&\\bord0",
  icon = "\\rDefault\\bord0\\fnmpv-icon",
  text = "\\rDefault\\bord0\\fnJetBrains Mono",
}

local element = function(x, y, w, h, style, text, raduis)
  local self = { x = x, y = y, w = w, h = h, style = style, text = text or "", raduis = raduis }
  local text = function(props)
    local have = props ~= nil
    local style = have and props.style or self.style
    local text = have and "" or self.text
    ass.text = ""
    ass:new_event()
    ass:pos(self.x, self.y)
    ass:append("{" .. style .. "\\fs" .. self.h .. "}" .. text)
    if have or self.raduis ~= nil then
      ass:draw_start()
      ass:round_rect_cw(0, 0, self.w, self.h, have and props.raduis or self.raduis)
      ass:draw_stop()
    end
    return ass.text
  end
  local mouse_in = function(x, y)
    local dx = math.max(self.x - x, 0, x - (self.x + self.w))
    local dy = math.max(self.y - y, 0, y - (self.y + self.h))
    return dx + dy == 0
  end
  return {
    info = self,
    text = text,
    mouse_in = mouse_in,
  }
end

local render = function(id, z, text)
  osd.id = id
  osd.z = z
  osd.data = text
  osd.hidden = false
  osd:update()
end

local sort_by_id = function(t)
  local a = {}
  for _, v in pairs(t) do
    if v.ele == nil then
      goto continue
    end
    a[v.id] = v
    ::continue::
  end
  return a
end

local hide = function(id)
  osd.id = id
  osd.hidden = true
  osd:update()
end

local time_format = function(seconds)
  if seconds < 3600 then
    local text = os.date("%M:%S", seconds)
    if time.len > 45 then
      text = "00:" .. text
    end
    return text
  else
    return os.date("%H:%M:%S", seconds + 3600 * 16)
  end
end

local panel = function()
  return element(size.panel_x, size.panel_y, size.panel_w, size.panel_h, style.panel, nil, size.panel_raduis)
end

local play = function()
  return element(size.panel_x + size.margin, size.icon_y, size.iconsize, size.iconsize, style.icon, icons.pause)
end

local audio = function()
  local x = size.panel_x + size.margin * 2 + size.iconsize
  return element(x, size.icon_y, size.iconsize, size.iconsize, style.icon, icons.audio)
end

local sub = function()
  local x = size.panel_x + size.margin * 3 + size.iconsize * 2
  return element(x, size.icon_y, size.iconsize, size.iconsize, style.icon, icons.sub)
end

local volume = function()
  local x = size.panel_x + size.margin * 4 + size.iconsize * 3
  local icon = icons.vol_full
  if vol.mute or vol.cur == 0 then
    icon = icons.vol_mute
  elseif vol.cur < 50 then
    icon = icons.vol_low
  end
  return element(x, size.icon_y, size.iconsize, size.iconsize, style.icon, icon)
end

local time_start = function()
  local x = size.panel_x + size.margin * 5 + size.iconsize * 4
  return element(x, size.text_y, time.len, size.textsize, style.text, time_format(time.playback))
end

local time_bar_low = function()
  local x = size.panel_x + size.margin * 6 + size.iconsize * 4 + time.len
  local w = size.panel_x + size.panel_w - size.margin * 3 - size.iconsize - time.len - x
  return element(x, size.bar_y, w, size.time_bar_h, style.bar_low, nil, size.time_bar_raduis)
end

local time_bar_up = function()
  local x = size.panel_x + size.margin * 6 + size.iconsize * 4 + time.len
  local w = size.panel_x + size.panel_w - size.margin * 3 - size.iconsize - time.len - x
  w = time.playback * (w / time.duration)
  if time.duration == 0 then
    w = 0
  end
  return element(x, size.bar_y, w, size.time_bar_h, style.bar_up, nil, size.time_bar_raduis)
end

local time_pointer = function()
  local x = size.panel_x + size.margin * 6 + size.iconsize * 4 + time.len
  local w = size.panel_x + size.panel_w - size.margin * 3 - size.iconsize - time.len - x
  w = time.playback * (w / time.duration)
  if time.duration == 0 then
    w = 0
  end
  x = x + w - size.time_pointer_h / 2
  local y = size.bar_y - (size.time_pointer_h - size.time_bar_h) / 2
  return element(x, y, size.time_pointer_h, size.time_pointer_h, style.text, nil, size.time_pointer_raduis)
end

local time_end = function()
  local x = size.panel_x + size.panel_w - size.margin * 2 - size.iconsize - time.len + 4
  return element(x, size.text_y, w, size.textsize, style.text, time_format(time.duration))
end

local quit = function()
  local x = size.panel_x + size.panel_w - size.margin - size.iconsize
  return element(x, size.icon_y, size.iconsize, size.iconsize, style.icon, icons.quit)
end

local elements = {
  panel = { id = 1, ele = nil, hover = false, click = false },
  play = { id = 2, ele = nil, hover = true, click = true },
  audio = { id = 3, ele = nil, hover = true, click = true },
  sub = { id = 4, ele = nil, hover = true, click = true },
  volume = { id = 45, ele = nil, hover = true, click = true },
  time_start = { id = 6, ele = nil, hover = false, click = false },
  time_bar_low = { id = 7, ele = nil, hover = false, click = true },
  time_bar_up = { id = 8, ele = nil, hover = false, click = false },
  time_bar_cache = { id = 9, ele = nil, hover = false, click = false },
  time_pointer = { id = 10, ele = nil, hover = false, click = false },
  time_end = { id = 11, ele = nil, hover = false, click = false },
  quit = { id = 12, ele = nil, hover = true, click = true },
}

local vol_panel = function()
  return element(
    size.vol_panel_x,
    size.vol_panel_y,
    size.vol_panel_w,
    size.vol_panel_h,
    style.panel,
    nil,
    size.panel_raduis
  )
end

local vol_icon = function()
  local x = size.vol_panel_x + size.margin
  local center_y = size.vol_panel_y + size.vol_panel_h / 2
  local icon = icons.vol_full
  if vol.mute or vol.cur == 0 then
    icon = icons.vol_mute
  elseif vol.cur < 50 then
    icon = icons.vol_low
  end
  return element(x, center_y - size.iconsize / 2, size.iconsize, size.iconsize, style.icon, icon)
end

local vol_bar_low = function()
  local x = size.vol_panel_x + size.margin * 2 + size.iconsize
  local center_y = size.vol_panel_y + size.vol_panel_h / 2
  local y = center_y - size.time_bar_h / 2
  return element(x, y, size.vol_low_w, size.time_bar_h, style.bar_low, nil, size.time_bar_raduis)
end

local vol_bar_up = function()
  local w = vol.cur * (size.vol_low_w / vol.max)
  local x = size.vol_panel_x + size.margin * 2 + size.iconsize
  local center_y = size.vol_panel_y + size.vol_panel_h / 2
  local y = center_y - size.time_bar_h / 2
  return element(x, y, w, size.time_bar_h, style.bar_up, nil, size.time_bar_raduis)
end

local vol_pointer = function()
  local w = vol.cur * (size.vol_low_w / vol.max)
  local x = size.vol_panel_x + size.margin * 2 + size.iconsize
  x = x + w - size.time_pointer_h / 2
  local center_y = size.vol_panel_y + size.vol_panel_h / 2
  local y = center_y - size.time_pointer_h / 2
  return element(x, y, size.time_pointer_h, size.time_pointer_h, style.text, nil, size.time_pointer_raduis)
end

local vol_text = function()
  local len = vol.cur < 10 and 9 or vol.cur > 99 and 27 or 18
  local x = size.vol_panel_x
    + size.margin * 3
    + size.iconsize
    + size.vol_low_w
    + (27 - len) / 2
    + size.time_pointer_h / 2
  local center_y = size.vol_panel_y + size.vol_panel_h / 2
  local y = center_y - size.textsize / 2
  return element(x, y, 27, size.textsize, style.text, vol.cur)
end

local vol_elements = nil

local gen_vol_elements = function()
  if size.vol_panel_x == 0 or size.vol_panel_y == 0 then
    return
  end
  vol_elements = {
    vol_panel = { id = 1, ele = vol_panel(), hover = false, click = false },
    vol_icon = { id = 2, ele = vol_icon(), hover = true, click = true },
    vol_bar_low = { id = 3, ele = vol_bar_low(), hover = false, click = true },
    vol_bar_up = { id = 4, ele = vol_bar_up(), hover = false, click = false },
    vol_pointer = { id = 5, ele = vol_pointer(), hover = false, click = false },
    vol_text = { id = 6, ele = vol_text(), hover = false, click = false },
  }
end

local gen_clip = function(x, y, w, h)
  return "{\\clip(".. x .. "," .. y .. "," .. x + w .. "," .. y + h .. ")}" 
end

local sub_elements = {}

local gen_sub_elements = function()
  sub_elements = {}
  local id = 1
  local panel =
    element(size.sub_panel_x, size.sub_panel_y, size.sub_panel_w, size.sub_panel_h, style.panel, nil, size.panel_raduis)
  sub_elements["sub_panel"] = { id = id, ele = panel, hover = false, click = false, selected = false }
  local x = size.sub_panel_x + size.item_gap
  local fy = size.sub_panel_y + size.item_gap
  local w = size.sub_panel_w - size.item_gap * 2
  local h = size.item_h
  local type_len = 27
  local title_len = 75
  for k, v in ipairs(sub_list) do
    id = id + 1
    local y = fy + (k - 1) * (size.item_h + size.item_gap)
    local sy = y + (size.item_h - size.textsize) / 2
    local title = element(
      x + size.item_gap,
      sy,
      title_len,
      size.textsize,
      style.text,
      v.title
    ).text()
    title= gen_clip(x + size.item_gap, sy, title_len, size.textsize) .. title
    local typetext = string.lower(v.type)
    typetext = typetext == "hdmv_pgs_subtitle" and "pgs" or typetext
    local real_type_len = #typetext * 9
    local type = element(
      x + w - real_type_len,
      sy,
      type_len,
      size.textsize,
      style.text,
      typetext
    ).text()
    local hover = v.selected and element(x, y, w, h, style.hover, nil, size.panel_raduis).text() or ""
    local ele = element(x, y, w, h, "", hover .. "\n" .. title .. "\n" .. type)
    sub_elements[k] = { id = id, tid = v.id, ele = ele, hover = true, click = true, selected = v.selected }
  end
end

local audio_elements = {}

local gen_audio_elements = function()
  audio_elements = {}
  local id = 1
  local panel = element(
    size.audio_panel_x,
    size.audio_panel_y,
    size.audio_panel_w,
    size.audio_panel_h,
    style.panel,
    nil,
    size.panel_raduis
  )
  audio_elements["audio_panel"] = { id = id, ele = panel, hover = false, click = false, selected = false }
  local x = size.audio_panel_x + size.item_gap
  local fy = size.audio_panel_y + size.item_gap
  local w = size.audio_panel_w - size.item_gap * 2
  local h = size.item_h
  local gap = size.item_gap
  local sp_gap = 10
  local max_ch_len = 0
  local max_rate_len = 0
  local max_type_len = 0
  for _, v in pairs(audio_list) do
    local ch_len = #v.channels * 9
    local rate_len = #v.rate * 9
    local type_len = #v.type * 9
    if ch_len > max_ch_len then
      max_ch_len = ch_len
    end
    if rate_len > max_rate_len then
      max_rate_len = rate_len
    end
    if type_len > max_type_len then
      max_type_len = type_len
    end
  end
  local title_len = size.audio_panel_w - size.item_gap * 4 - gap * 2 - sp_gap - max_ch_len - max_rate_len - max_type_len
  for k, v in ipairs(audio_list) do
    id = id + 1
    local y = fy + (k - 1) * (size.item_h + size.item_gap)
    local sy = y + (size.item_h - size.textsize) / 2
    local real_ch_len = #v.channels * 9
    local sw = x + w - real_ch_len
    local ch = element(sw, sy, max_ch_len, size.textsize, style.text, v.channels).text()
    local real_rate_len = #v.rate * 9
    sw = x + w - max_ch_len - gap - real_rate_len
    local rate = element(sw, sy, max_rate_len, size.textsize, style.text, v.rate).text()
    local real_type_len = #v.type * 9
    sw = x + w - max_ch_len - gap - max_rate_len - gap - real_type_len
    local type = element(sw, sy, max_type_len, size.textsize, style.text, v.type).text()
    local title = element(x + size.item_gap, sy, title_len, size.textsize, style.text, v.title).text()
    title = gen_clip(x + size.item_gap, sy, title_len, size.textsize) .. title
    local hover = v.selected and element(x, y, w, h, style.hover, nil, size.panel_raduis).text() or ""
    local ele = element(x, y, w, h, "", hover .. "\n" .. title .. "\n" .. type .. "\n" .. ch .. "\n" .. rate)
    audio_elements[k] = { id = id, tid = v.id, ele = ele, hover = true, click = true, selected = v.selected }
  end
end

local refresh_all = function()
  if size.w == 0 or size.h == 0 then
    return
  end
  elements["panel"].ele = panel()
  elements["play"].ele = play()
  elements["audio"].ele = audio()
  elements["sub"].ele = sub()
  elements["volume"].ele = volume()
  elements["time_start"].ele = time_start()
  elements["time_bar_low"].ele = time_bar_low()
  elements["time_bar_up"].ele = time_bar_up()
  elements["time_pointer"].ele = time_pointer()
  elements["time_end"].ele = time_end()
  elements["quit"].ele = quit()
end

local render_all = function(id, ele)
  local text = ""
  local a = sort_by_id(ele)
  for _, v in pairs(a) do
    text = text .. v.ele.text() .. "\n"
  end
  render(id, 1000, text)
end

local hide_all = function()
  hide(id.panel)
  hide(id.hover)
  hide(id.vol)
  hide(id.sub)
  hide(id.audio)
  state.visibility = false
  state.vol_visibility = false
  state.sub_visibility = false
  state.audio_visibility = false
end

mp.observe_property("volume", "native", function(_, val) end)

mp.observe_property("pause", "bool", function(_, val)
  if elements.play.ele == nil then
    return
  end
  elements.play.ele.info.text = val and icons.play or icons.pause
  if not state.visibility then
    return
  end
  mp.add_timeout(0.05, function()
    render_all(id.panel, elements)
  end)
end)

local auto_render = function()
  if not state.visibility then
    state.visibility = true
    render_all(id.panel, elements)
    state.timer = mp.add_timeout(0, hide_all)
    state.timer:kill()
    state.timer.timeout = 1
    state.timer:resume()
  else
    local mouse_pos = mp.get_property_native("mouse-pos")
    local x = mouse_pos.x * 720 / size.h
    local y = mouse_pos.y * 720 / size.h
    state.keep = elements["panel"].ele.mouse_in(x, y)
      or (state.vol_visibility and vol_elements["vol_panel"].ele.mouse_in(x, y))
      or (state.sub_visibility and sub_elements["sub_panel"].ele.mouse_in(x, y))
      or (state.audio_visibility and audio_elements["audio_panel"].ele.mouse_in(x, y))
    state.timer:kill()
    if not state.keep then
      state.timer.timeout = 1
      state.timer:resume()
    end
  end
end

local function hover_render(ele, style)
  render(id.hover, 1001, ele.text({ style = style, raduis = size.panel_raduis }))
end

local show_or_hide_current = function(k)
  local part = "_visibility"
  local vs = { "vol", "sub", "audio" }
  if state[k .. part] then
    hide(id[k])
    state[k .. part] = false
    return false
  end
  for _, v in pairs(vs) do
    if v == k then goto continue end
    if state[v .. part] then
      hide(id[v])
      state[v .. part] = false
    end
    ::continue::
  end
  return true
end

local switch = {
  quit = function()
    mp.commandv("quit")
  end,
  play = function()
    mp.set_property_bool("pause", not mp.get_property_bool("pause"))
  end,
  time_bar_low = function(x, _)
    local info = elements["time_bar_low"].ele.info
    local len = x - info.x
    local seconds = math.floor(len * time.duration / info.w)
    mp.commandv("seek", seconds, "absolute+exact")
  end,
  audio = function()
    if #audio_list == 0 then return end
    local continue = show_or_hide_current("audio") 
    if not continue then return end
    local h = (#audio_list + 1) * size.item_gap + #audio_list * size.item_h
    local info = elements["audio"].ele.info
    local x = info.x + info.w / 2 - size.audio_panel_w / 2
    local y = elements["panel"].ele.info.y - h
    if size.audio_panel_h ~= h or x ~= size.audio_panel_x then
      size.audio_panel_x = x
      size.audio_panel_y = y
      size.audio_panel_h = h
      gen_audio_elements()
    end
    render_all(id.audio, audio_elements)
    state.audio_visibility = true
  end,
  sub = function()
    if #sub_list == 0 then return end
    local continue = show_or_hide_current("sub") 
    if not continue then return end
    local h = (#sub_list + 1) * size.item_gap + #sub_list * size.item_h
    local info = elements["sub"].ele.info
    local x = info.x + info.w / 2 - size.sub_panel_w / 2
    local y = elements["panel"].ele.info.y - h
    if size.sub_panel_h ~= h or x ~= size.sub_panel_x then
      size.sub_panel_x = x
      size.sub_panel_y = y
      size.sub_panel_h = h
      gen_sub_elements()
    end
    render_all(id.sub, sub_elements)
    state.sub_visibility = true
  end,
  volume = function()
    local continue = show_or_hide_current("vol") 
    if not continue then return end
    local info = elements["volume"].ele.info
    local x = info.x + info.w / 2 - size.vol_panel_w / 2
    local y = elements["panel"].ele.info.y - size.vol_panel_h
    if vol_elements == nil or x ~= size.vol_panel_x or y ~= size.vol_panel_y then
      size.vol_panel_x = x
      size.vol_panel_y = y
      gen_vol_elements()
    end
    render_all(id.vol, vol_elements)
    state.vol_visibility = true
  end,
  vol_icon = function()
    mp.commandv("cycle", "mute")
  end,
  vol_bar_low = function(x, _)
    local info = vol_elements["vol_bar_low"].ele.info
    local len = x - info.x
    local vol = math.floor(len * vol.max / info.w)
    mp.commandv("set", "volume", vol)
  end,
}

local click = function(action)
  local mouse_pos = mp.get_property_native("mouse-pos")
  local x = math.floor(mouse_pos.x * 720 / size.h)
  local y = math.floor(mouse_pos.y * 720 / size.h)
  if action == "mbtn_left_up" and not state.press.vol_pointer and not state.press.time_pointer then
    for k, v in pairs(elements) do
      if v.click and v.ele.mouse_in(x, y) then
        switch[k](x, y)
        return
      end
    end
    if state.vol_visibility then
      for k, v in pairs(vol_elements) do
        if v.click and v.ele.mouse_in(x, y) then
          switch[k](x, y)
          return
        end
      end
    end
    if state.audio_visibility then
      for _, v in pairs(audio_elements) do
        if v.click and v.ele.mouse_in(x, y) then
          mp.commandv("set", "audio", v.selected and "no" or v.tid)
          hide(id.audio)
          hide(id.hover)
          state.audio_visibility = false
          mp.disable_key_bindings("input")
          state.timer:kill()
          state.timer.timeout = 1
          state.timer:resume()
          return
        end
      end
    end
    if state.sub_visibility then
      for _, v in pairs(sub_elements) do
        if v.click and v.ele.mouse_in(x, y) then
          mp.commandv("set", "sub", v.selected and "no" or v.tid)
          hide(id.sub)
          hide(id.hover)
          state.sub_visibility = false
          mp.disable_key_bindings("input")
          state.timer:kill()
          state.timer.timeout = 1
          state.timer:resume()
          return
        end
      end
    end
  end
  if action == "mbtn_left_down" then
    if state.vol_visibility and vol_elements["vol_pointer"].ele.mouse_in(x, y) then
      state.press.vol_pointer = true
    end
    if time.duration ~= 0 and elements["time_pointer"].ele.mouse_in(x, y) then
      state.press.time_pointer = true
    end
  end

  if state.press.vol_pointer and action == "mouse_move" then
    local info = vol_elements["vol_bar_low"].ele.info
    local length = x - info.x
    if length < 0 then
      length = 0
    end
    if length > info.w then
      length = info.w
    end
    local vol = math.floor(length * vol.max / info.w)
    mp.commandv("set", "volume", vol)
    return
  end

  if state.press.vol_pointer and action == "mbtn_left_up" then
    state.press.vol_pointer = false
    return
  end

  if state.press.time_pointer and action == "mouse_move" then
    local info = elements["time_bar_low"].ele.info
    local length = x - info.x
    local seconds = math.floor(length * time.duration / info.w)
    if length < 0 then
      seconds = 0
      length = 0
    end
    if length > info.w then
      seconds = time.duration
      length = info.w
    end
    time.playback = seconds
    elements["time_bar_up"].ele.info.w = length
    elements["time_pointer"].ele.info.x = info.x + length - size.time_pointer_h / 2
    elements["time_start"].ele.info.text = time_format(seconds)
    render_all(id.panel, elements)
    return
  end

  if state.press.time_pointer and action == "mbtn_left_up" then
    state.press.time_pointer = false
    mp.commandv("seek", time.playback, "absolute+exact")
    return
  end
end

local hover = function()
  local mouse_pos = mp.get_property_native("mouse-pos")
  local x = math.floor(mouse_pos.x * 720 / size.h)
  local y = math.floor(mouse_pos.y * 720 / size.h)
  local flag = false
  local ele
  for _, v in pairs(elements) do
    if v.hover and v.ele.mouse_in(x, y) then
      flag = true
      ele = v.ele
      break
    end
  end
  if state.vol_visibility and vol_elements["vol_icon"].ele.mouse_in(x, y) then
    flag = true
    ele = vol_elements["vol_icon"].ele
  end
  if not flag and state.sub_visibility then
    for _, v in pairs(sub_elements) do
      if v.hover and not v.selected and v.ele.mouse_in(x, y) then
        flag = true
        ele = v.ele
        break
      end
    end
  end
  if not flag and state.audio_visibility then
    for _, v in pairs(audio_elements) do
      if v.hover and not v.selected and v.ele.mouse_in(x, y) then
        flag = true
        ele = v.ele
        break
      end
    end
  end
  if flag then
    hover_render(ele, style.hover)
    return
  end
  hide(id.hover)
  -- thumbfast
  if time.duration ~= 0 and elements["time_bar_low"].ele.mouse_in(x, y) then
    if not thumbfast.disabled then
      local info = elements["time_bar_low"].ele.info
      local len = x - info.x
      local seconds = math.floor(len * time.duration / info.w)
      local y = math.floor(size.h / 720 * size.panel_y) - 10 - thumbfast.height
      mp.commandv(
        "script-message-to",
        "thumbfast",
        "thumb",
        seconds,
        math.floor(size.h / 720 * x) - thumbfast.width / 2,
        y
      )
      local t = time_format(seconds)
      local text = element(x - time.len / 2 + 2, size.panel_y, size.textsize, size.textsize, style.text, t).text()
      render(id.thumb, 1001, text)
    end
  else
    if thumbfast.available then
      mp.commandv("script-message-to", "thumbfast", "clear")
      hide(id.thumb)
    end
  end
end

local dispatch = function(source, what)
  local action = string.format("%s%s", source, what and ("_" .. what) or "")
  if action == "mouse_move" then
    auto_render()
    if state.keep then
      hover()
      mp.enable_key_bindings("input")
    else
      mp.disable_key_bindings("input")
    end
  end
  if state.keep then
    click(action)
  else
    if state.press.time_pointer then
      state.press.time_pointer = false
    end
    if state.press.vol_pointer then
      state.press.vol_pointer = false
    end
  end
end

local enable_key_bingding = function()
  mp.enable_key_bindings("mouse", "allow-vo-dragging+allow-hide-cursor")
end

mp.set_key_bindings({
  {
    "mouse_move",
    function(e)
      dispatch("mouse_move", nil)
    end,
  },
}, "mouse", "force")

mp.set_key_bindings({
  {
    "mbtn_left",
    function(e)
      dispatch("mbtn_left", "up")
    end,
    function(e)
      dispatch("mbtn_left", "down")
    end,
  },
  { "mbtn_left_dbl", "ignore" },
  { "wheel_up", "ignore" },
  { "wheel_down", "ignore" },
}, "input", "force")

enable_key_bingding()

mp.observe_property("duration", "number", function(_, val)
  if val == nil then
    return
  end
  if val ~= time.duration then
    time.duration = val
    time.len = val < 3600 and 45 or 72
    refresh_all()
  end
  if state.visibility and not state.press.time_pointer then
    render_all(id.panel, elements)
  end
end)

mp.observe_property("playback-time", "number", function(_, val)
  if val == nil then
    return
  end
  if not state.press.time_pointer then
    time.playback = val
    elements["time_bar_up"].ele = time_bar_up()
    elements["time_start"].ele = time_start()
    elements["time_pointer"].ele = time_pointer()
  end
  if state.visibility and not state.press.time_pointer then
    render_all(id.panel, elements)
  end
end)

mp.observe_property("volume-max", "native", function(_, val)
  vol.max = val
end)

mp.observe_property("volume", "native", function(_, val)
  vol.cur = val
  elements["volume"].ele = volume()
  gen_vol_elements()
  if vol_elements ~= nil and state.vol_visibility then
    render_all(id.vol, vol_elements)
  end
  if state.visibility then
    render_all(id.panel, elements)
  end
end)

mp.observe_property("mute", "bool", function(_, val)
  vol.mute = val
  elements["volume"].ele = volume()
  if vol_elements ~= nil then
    vol_elements["vol_icon"].ele = vol_icon()
    if state.vol_visibility then
      render_all(id.vol, vol_elements)
    end
  end
  if state.visibility then
    render_all(id.panel, elements)
  end
end)

mp.observe_property("osd-dimensions", "native", function(_, val)
  if val.w == 0 or val.h == 0 then
    return
  end
  if val.w == size.w and val.h == size.h then
    return
  end
  size.w = val.w
  size.h = val.h
  size.panel_x = math.ceil(val.w * 720 / val.h * 0.15)
  size.panel_y = math.ceil(val.h * 720 / val.h * 0.8)
  size.panel_w = math.ceil(val.w * 720 / val.h * 0.7)
  size.icon_y = size.panel_y + (size.panel_h - size.iconsize) / 2
  size.text_y = size.icon_y + (size.iconsize - size.textsize) / 2 + 1.5
  size.bar_y = size.panel_y + (size.panel_h - size.time_bar_h) / 2 + 1.5
  refresh_all()
  if state.visibility then
    render_all(id.panel, elements)
  end
end)

mp.register_script_message("thumbfast-info", function(json)
  local data = utils.parse_json(json)
  if type(data) ~= "table" or not data.width or not data.height then
    msg.error("thumbfast-info: received json didn't produce a table with thumbnail information")
  else
    thumbfast = data
  end
end)

local function sub_pure(track)
  local title = track.title and track.title or track.lang or "Sub"
  local type = track.codec
  local id = track.id
  local selected = track.selected
  table.insert(sub_list, { id = id, title = title, type = type, selected = selected })
end

local function audio_pure(track)
  local ch = track["audio-channels"] .. "Ch"
  local rate = track["demux-samplerate"] / 1000 .. "KHz"
  local title = track.title and track.title or track.lang or "Audio"
  local type = track.codec
  local id = track.id
  local selected = track.selected
  table.insert(audio_list, { id = id, title = title, rate = rate, channels = ch, type = type, selected = selected })
end

mp.observe_property("track-list", "native", function(_, val)
  sub_list = {}
  audio_list = {}
  for _, track in pairs(val) do
    if track.type == "sub" then
      sub_pure(track)
    end
    if track.type == "audio" then
      audio_pure(track)
    end
  end
  if size.sub_panel_h ~= 0 then
    local info = elements["sub"].ele.info
    local h = (#sub_list + 1) * size.item_gap + #sub_list * size.item_h
    local x = info.x + info.w / 2 - size.sub_panel_w / 2
    local y = elements["panel"].ele.info.y - h
    size.sub_panel_x = x
    size.sub_panel_y = y
    size.sub_panel_h = h
    gen_sub_elements()
  end
  if size.audio_panel_h ~= 0 then
    local info = elements["audio"].ele.info
    local x = info.x + info.w / 2 - size.audio_panel_w / 2
    local h = (#audio_list + 1) * size.item_gap + #audio_list * size.item_h
    local y = elements["panel"].ele.info.y - h
    size.audio_panel_x = x
    size.audio_panel_y = y
    size.audio_panel_h = h
    gen_audio_elements()
  end
  if state.sub_visibility then
    render_all(id.sub, sub_elements)
  end
  if state.audio_visibility then
    render_all(id.audio, audio_elements)
  end
end)

mp.observe_property("demuxer-cache-state", "native", function(_, cache_state)
  if cache_state == nil or elements["time_bar_low"].ele == nil then return end
  local ranges = cache_state["seekable-ranges"]
  local text = ""
  local info = elements["time_bar_low"].ele.info
  for k, v in pairs(ranges) do
    local start_cache, end_cache = v["start"], v["end"]
    local x = info.x + start_cache * info.w / time.duration
    local w = (end_cache - start_cache) * info.w / time.duration
    text = text .. "\n" .. element(x, info.y, w, info.h, style.bar_cache, nil, size.time_bar_raduis).text()
  end
  elements["time_bar_cache"].ele = element(0, 0, 0, 0, "", text) 
  if state.visibility then
    render_all(id.panel, elements)
  end
end)

