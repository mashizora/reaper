-- @desc    Add take markers from video chapters
-- @author  mashizora
-- @version 0.1.0

-- check if ffprobe exists
if (reaper.ExecProcess('ffprobe -version', 0) == nil) then
    reaper.ShowMessageBox('ffprobe not found.', 'Error', 0)
    return
end


for item_idx = 0, (reaper.CountMediaItems(0) - 1) do
    local item = reaper.GetMediaItem(0, item_idx)

    if reaper.IsMediaItemSelected(item) then
        for take_idx = 0, (reaper.CountTakes(item) - 1) do
            local take = reaper.GetTake(item, take_idx)

            local source = reaper.GetMediaItemTake_Source(take)
            local file_name = reaper.GetMediaSourceFileName(source)

            local chapters = {}

            -- read chapters from source file
            local cmd = string.format('ffprobe -i "%s" -show_chapters -output_format compact -loglevel error', file_name)
            local result = reaper.ExecProcess(cmd, 0)
            local code, output = string.match(result, '(%d+)\n(.+)')

            if tonumber(code) == 0 then
                for line in string.gmatch(output, '[^\r\n]+') do
                    for time, name in string.gmatch(line, 'chapter|.-|start_time=([.0-9]+)|.-|tag:title=(.+)') do
                        table.insert(chapters, { time = tonumber(time), name = name })
                    end
                end
            else
                local message = string.format('ffprobe error: %s', output)
                reaper.ShowMessageBox(message, 'Error', 0)
            end

            -- set take markers when chapters found
            if next(chapters) ~= nil then
                for _ = 1, reaper.GetNumTakeMarkers(take) do
                    reaper.DeleteTakeMarker(take, 0)
                end

                for _, chapter in ipairs(chapters) do
                    reaper.SetTakeMarker(take, -1, chapter.name, chapter.time)
                end
            end
        end
    end
end
