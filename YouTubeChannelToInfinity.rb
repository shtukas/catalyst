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

raise "This script needs updating, we are no longer using global-positioning-4233 or parentuuid-0014"

positions = []

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
    Blades::setAttribute(item["uuid"], "global-positioning-4233", position)
    item = Blades::itemOrNull(item["uuid"])
    puts JSON.pretty_generate(item)
}

LucilleCore::removeFileSystemLocation("/Users/pascal/Desktop/#{tmpDirectoryName}")

puts "process completed"