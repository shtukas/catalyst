#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require 'json'
require 'date'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')
require 'find'
require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
require "/Galaxy/local-resources/Ruby-Libraries/FIFOQueue.rb"
require_relative "Commons.rb"
# -------------------------------------------------------------------------------------

VIENNA_PATH_TO_DATA = "/Users/pascal/Library/Application Support/Vienna/messages.db"

# select link from messages where read_flag=0;
# update messages set read_flag=1 where link="https://www.schneier.com/blog/archives/2018/04/security_vulner_14.html"

# Vienna::upgradeFlockUsingObjectAndCommand(flock, object, command)
# Vienna::getUnreadLinks()

class Vienna

    def self.agentuuid()
        "2ba71d5b-f674-4daf-8106-ce213be2fb0e"
    end

    def self.upgradeFlockUsingObjectAndCommand(flock, object, command)
        return [flock, []]
        if command=='open' then
            system("open '#{object["item-data"]["link"]}'")
        end
        if command=='done' then
            Vienna::setLinkAsRead(object["item-data"]["link"])
            FIFOQueue::push(nil, "timestamps-f0dc-44f8-87d0-f43515e7eba0", Time.new.to_i)
        end
    end

    def self.getUnreadLinks()
        query = "select link from messages where read_flag=0;"
        `sqlite3 '#{VIENNA_PATH_TO_DATA}' '#{query}'`.lines.map{|line| line.strip }
    end

    def self.getUnreadLinkOrNull()
        Vienna::getUnreadLinks().first
    end

    def self.getUnreadLinks()
        query = "select link from messages where read_flag=0;"
        `sqlite3 '#{VIENNA_PATH_TO_DATA}' '#{query}'`.lines.map{|line| line.strip }
    end

    def self.setLinkAsRead(link)
        query = "update messages set read_flag=1 where link=\"#{link}\""
        system("sqlite3 '#{VIENNA_PATH_TO_DATA}' '#{query}'")
    end

    def self.metric(uuid, unreadlinks)
        FIFOQueue::takeWhile(nil, "timestamps-f0dc-44f8-87d0-f43515e7eba0", lambda{|unixtime| (Time.new.to_i - unixtime)>86400 })
        metric = 0.195 + 0.6*Saturn::realNumbersToZeroOne(unreadlinks.count, 100, 50)*Math.exp(-FIFOQueue::size(nil, "timestamps-f0dc-44f8-87d0-f43515e7eba0").to_f/20) + Saturn::traceToMetricShift(uuid)
    end

    def self.flockGeneralUpgrade(flock)
        return [flock, []]
        return [flock, []] if !Saturn::isPrimaryComputer()
        links = Vienna::getUnreadLinks()
        return [flock, []] if links.empty?
        link = links.first
        uuid = Digest::SHA1.hexdigest("cc8c96fe-efa3-4f8a-9f81-5c61f12d6872:#{link}")[0,8]
        metric = Vienna::metric(uuid, links)
        objects = [
            {
                "uuid" => uuid,
                "agent-uid" => self.agentuuid(),
                "metric" => metric,
                "announce" => "vienna: #{link}",
                "commands" => ['open', 'done'],
                "default-expression" => "open done",
                "item-data" => {
                    "link" => link
                }
            }
        ]
        flock["objects"] = flock["objects"] + objects
        [
            flock,
            objects.map{|o|  
                {
                    "event-type" => "Catalyst:Catalyst-Object:1",
                    "object"     => o
                }                
            }   
        ]
    end

    def self.interface()
        
    end
end
