# encoding: UTF-8
require_relative "Libs/loader.rb"

=begin
yt-dlp \
    -o '%(upload_date)s-%(title)s-%(id)s.%(ext)s' \
    -f 'bestvideo[height<=720]+bestaudio/best[height<=720]' \
    "https://www.youtube.com/@veritasium/videos"
=end

positions = Items::mikuType("NxTask")
            .select{|item| item["parentuuid-0014"].nil? }
            .sort_by{|item| item["global-positioning"] }
            .map{|item| item["global-positioning"] }

insertions = positions.zip(positions.drop(1))
    .select{|pair| pair.compact.size == 2 }
    .map{|pair| 0.5 * (pair[0] + pair[1]) }
    .drop(10) # we skip the first 10 positions

filepaths = LucilleCore::locationsAtFolder("/Users/pascal/Desktop/tmp1")

while insertions.size < filepaths.size do
    insertions << insertions.last + 1
end

coordinates = filepaths.zip(insertions)

coordinates.each{|filepath, position|
    item = NxTasks::locationToTask(File.basename(filepath), filepath)
    Items::setAttribute(item["uuid"], "global-positioning", position)
    Items::setAttribute(item["uuid"], "x:filepath", filepath)
    item = Items::itemOrNull(item["uuid"])
    puts JSON.pretty_generate(item)
    LucilleCore::removeFileSystemLocation(filepath)
}

puts "process completed"