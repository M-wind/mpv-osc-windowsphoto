local utils = require 'mp.utils'

function hit(x, y, x1, y1, x2, y2)
	return x1 <= x and x <= x2 and y1 <= y and y <= y2
end

function open_file_dialog()
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

function timeFormat(seconds)
	if seconds < 3600 then
		return '00:00', os.date("%M:%S", seconds)
	else
		-- 最大长度23:59:59
		return '00:00:00', os.date("%H:%M:%S", seconds + 3600 * 16)
	end
end
