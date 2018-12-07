#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

# -------------------------------------------------------------------------------------

# NSXAgentStreams::getObjects()

class NSXAgentStreams

    # NSXAgentStreams::agentuuid()
    def self.agentuuid()
        "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1"
    end

    # NSXAgentStreams::getObjects()
    def self.getObjects()
        # This agent doesn't generate its own objects but it handles the commands. 
        # The objects are generated by the LightThreads's agent
        # When a command is executed we reload the NSXAgentLightThread's objects
        # NSXAgentLightThread calls the stream objects with the right metric.
        return []
    end

    # NSXAgentStreams::stopObject(object)
    def self.stopObject(object)
        streamItemUUID = object["data"]["stream-item"]["uuid"]
        timespanInSeconds = NSXStreamsUtils::stopStreamItem(streamItemUUID)
        NSXStreamsUtils::stopPostProcessing(streamItemUUID)
        if timespanInSeconds == 0 then
            # happens when we done an item that had not been started NSXStreamsUtils::stopStreamItem returns 0
            timespanInSeconds = 300 # 5 minutes
        end
        lightThreadUUID = object["data"]["light-thread"]["uuid"]
        puts "Notification: NSXAgentStreams, adding #{timespanInSeconds} seconds to LightThread '#{object["data"]["light-thread"]["description"]}'"
        NSXLightThreadUtils::issueLightThreadTimeRecordItem(lightThreadUUID, Time.new.to_i, timespanInSeconds)
    end

    # NSXAgentStreams::doneObject(object)
    def self.doneObject(object)
        NSXAgentStreams::stopObject(object)
        NSXStreamsUtils::destroyItem(object["data"]["stream-item"]["filename"])
    end

    def self.processObjectAndCommand(object, command)
        if command == "open" then
            NSXStreamsUtils::viewItem(object["data"]["stream-item"]["filename"])
        end
        if command == "start" then
            NSXStreamsUtils::startStreamItem(object["data"]["stream-item"]["uuid"])
            NSXMiscUtils::setStandardListingPosition(1)
        end
        if command == "stop" then
            NSXAgentStreams::stopObject(object)
        end
        if command == "done" then
            NSXAgentStreams::doneObject(object)
        end
        if command == "recast" then
            item = object["data"]["stream-item"]
            lightThread = NSXLightThreadUtils::interactivelySelectLightThreadOrNull()
            return if lightThread.nil?
            item["streamuuid"] = lightThread["streamuuid"]
            NSXStreamsUtils::sendItemToDisk(item)
        end

        if command == "process" then
            puts "Viewing..."
            NSXStreamsUtils::viewItem(object["data"]["stream-item"]["filename"])
            subcommands = ["done", "datecode"]
            subcommand = LucilleCore::selectEntityFromListOfEntitiesOrNull("sub-command:", subcommands)
            if subcommand == "done" then
                NSXAgentStreams::doneObject(object)
            end
            if subcommand == "datecode" then
                loop {
                    datecode = LucilleCore::askQuestionAnswerAsString("datecode: ")
                    datetime = NSXMiscUtils::codeToDatetimeOrNull(datecode)
                    next if datetime.nil?
                    NSXDoNotShowUntilDatetime::setDatetime(object["uuid"], datetime)
                    break
                }
            end
        end

        if command == "description:" then
            item = object["data"]["stream-item"]
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            NSXStreamsUtils::setItemDescription(item["uuid"], description)
            lightThread = object["data"]["light-thread"]
        end

    end

    def self.interface()

    end

end