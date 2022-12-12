function VolIcon(volume)
	local icon = Icons.vol_full
	if volume < 50 then
		icon = Icons.vol_low
	end
	if volume == 0 or mp.get_property_bool('mute') then
		icon = Icons.vol_mute
	end
	return icon
end

function SortById(t)
	local a = {}
	for k, v in pairs(t) do a[v.id] = k end
	return a
end

local osd = mp.create_osd_overlay("ass-events")
function Bounds(text, h)
	local tags = '\\bord0'
	tags = tags .. '\\fnmpv-icon'
	tags = tags .. '\\fs' .. h
	osd.data = '{' .. tags .. '}' .. text
	osd.id = 63
	osd.compute_bounds = true
	osd.hidden = true
	local res = osd:update()
	osd:remove()
	-- return res.x1 - res.x0, res.y1 - res.y0
	return res.x1 - res.x0
end

function TimeFormat(seconds)
	if seconds < 3600 then
		return os.date("%M:%S", seconds)
	else
		-- 最大长度23:59:59
		return os.date("%H:%M:%S", seconds + 3600 * 16)
	end
end

local utils = require 'mp.utils'

function OpenFileDialog()
	local was_ontop = mp.get_property_native("ontop")
	if was_ontop then mp.set_property_native("ontop", false) end
	local res = utils.subprocess({
		args = { 'powershell', '-NoProfile', '-Command', [[& {
			Trap {
				Write-Error -ErrorRecord $_
				Exit 1
			}
			Add-Type -AssemblyName PresentationFramework

			$u8 = [System.Text.Encoding]::UTF8
			$out = [Console]::OpenStandardOutput()

			$ofd = New-Object -TypeName Microsoft.Win32.OpenFileDialog
			$ofd.Multiselect = $false
            $ofd.Title = '选择字幕文件'
            $ofd.Filter = 'Batch files (*.srt;*.ass)|*.srt;*.ass'

			If ($ofd.ShowDialog() -eq $true) {
				ForEach ($filename in $ofd.FileNames) {
					$u8filename = $u8.GetBytes("$filename`n")
					$out.Write($u8filename, 0, $u8filename.Length)
				}
			}
		}]] },
		cancellable = false,
	})
	if was_ontop then mp.set_property_native("ontop", true) end
	if (res.status ~= 0) then return end

	for filename in string.gmatch(res.stdout, '[^\n]+') do
		mp.commandv('sub-add', filename)
	end
end
