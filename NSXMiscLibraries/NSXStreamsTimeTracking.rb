
# encoding: UTF-8

require 'fileutils'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'json'

require 'find'

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
KeyValueStore::set(repositorylocation or nil, key, value)
KeyValueStore::getOrNull(repositorylocation or nil, key)
KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ----------------------------------------------------------------------

class NSXStreamsTimeTracking

    # NSXStreamsTimeTracking::currentDate()
    def self.currentDate()
        Time.now.utc.iso8601[0,10]
    end

    # NSXStreamsTimeTracking::addTimeInSecondsToStream(streamuuid, seconds)
    def self.addTimeInSecondsToStream(streamuuid, seconds)
        existingtime = KeyValueStore::getOrDefaultValue(nil, "[pascal Catalyst] 2019-03-31 09:17:01 #{NSXStreamsTimeTracking::currentDate()} #{streamuuid}", "0").to_f
        KeyValueStore::set(nil, "[pascal Catalyst] 2019-03-31 09:17:01 #{NSXStreamsTimeTracking::currentDate()} #{streamuuid}", existingtime+seconds)
    end

    # NSXStreamsTimeTracking::getTimeInSecondsForStream(streamuuid)
    def self.getTimeInSecondsForStream(streamuuid)
        KeyValueStore::getOrDefaultValue(nil, "[pascal Catalyst] 2019-03-31 09:17:01 #{NSXStreamsTimeTracking::currentDate()} #{streamuuid}", "0").to_f
    end

    # NSXStreamsTimeTracking::streamWideDisplayRatioForItemsTrueCompute(streamuuid)
    def self.streamWideDisplayRatioForItemsTrueCompute(streamuuid)
        return 1 if NSXStreamsUtils::streamuuidToPriorityFlagOrNull(streamuuid)
        commitmentInHours = NSXStreamsUtils::streamuuidToTimeControlInHours(streamuuid)
        doneTimeInHours = NSXStreamsTimeTracking::getTimeInSecondsForStream(streamuuid).to_f/3600
        if doneTimeInHours < commitmentInHours then
            1
        else
            Math.exp(-(doneTimeInHours-commitmentInHours))
        end
    end

    # NSXStreamsTimeTracking::streamWideDisplayRatioForItems(streamuuid)
    def self.streamWideDisplayRatioForItems(streamuuid)
        value = KeyValueStore::getOrNull(nil, "fda35a65-e960-4a92-8dfb-4fafba1d0032:#{NSXMiscUtils::currentHour()}:#{streamuuid}")
        return value.to_f if value
        value = NSXStreamsTimeTracking::streamWideDisplayRatioForItemsTrueCompute(streamuuid)
        KeyValueStore::set(nil, "fda35a65-e960-4a92-8dfb-4fafba1d0032:#{NSXMiscUtils::currentHour()}:#{streamuuid}", value)
        value
    end
end
