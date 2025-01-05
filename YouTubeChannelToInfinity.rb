# encoding: UTF-8
require_relative "Libs/loader.rb"

=begin
yt-dlp \
    -o '%(upload_date)s-%(title)s-%(id)s.%(ext)s' \
    -f 'bestvideo[height<=720]+bestaudio/best[height<=720]' \
    "https://www.youtube.com/@veritasium/videos"
=end

youTubeURL = "https://www.youtube.com/@jomakaze/videos"
tmpDirectoryName = SecureRandom.hex(5)

puts "Downloading videos"

query = <<-QUERY
mkdir /Users/pascal/Desktop/#{tmpDirectoryName}
cd /Users/pascal/Desktop/#{tmpDirectoryName}

yt-dlp \
    -o '%(upload_date)s-%(title)s-%(id)s.%(ext)s' \
    -f 'bestvideo[height<=720]+bestaudio/best[height<=720]' \
    "#{youTubeURL}"
QUERY

system(query)

positions = Items::mikuType("NxTask")
            .select{|item| item["parentuuid-0014"].nil? }
            .sort_by{|item| item["global-positioning-4233"] }
            .map{|item| item["global-positioning-4233"] }

insertions = positions.zip(positions.drop(1))
    .select{|pair| pair.compact.size == 2 }
    .map{|pair| 0.5 * (pair[0] + pair[1]) }
    .drop(10) # we skip the first 10 positions

filepaths = LucilleCore::locationsAtFolder("/Users/pascal/Desktop/#{tmpDirectoryName}")

while insertions.size < filepaths.size do
    insertions << insertions.last + 1
end

coordinates = filepaths.zip(insertions)

coordinates.each{|filepath, position|
    item = NxTasks::locationToTask(File.basename(filepath), filepath)
    Items::setAttribute(item["uuid"], "global-positioning-4233", position)
    Items::setAttribute(item["uuid"], "x:filepath", filepath)
    item = Items::itemOrNull(item["uuid"])
    puts JSON.pretty_generate(item)
}

LucilleCore::removeFileSystemLocation("/Users/pascal/Desktop/#{tmpDirectoryName}")

puts "process completed"