# encoding: UTF-8

class NxTasks

    # NxTasks::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType") != "NxTask"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "description"),
            "nx111"       => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "nx111"),
        }
    end

    # NxTasks::items()
    def self.items()
        Fx256WithCache::mikuTypeToItems("NxTask")
    end

    # NxTasks::items2(count)
    def self.items2(count)
        Fx256WithCache::mikuTypeToItems2("NxTask", count)
    end

    # NxTasks::destroy(uuid)
    def self.destroy(uuid)
        Fx256::deleteObjectLogically(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)
        Fx18Attributes::setJsonEncoded(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncoded(uuid, "mikuType",    "NxTask")
        Fx18Attributes::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setJsonEncoded(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::setJsonEncoded(uuid, "description", description)
        Fx18Attributes::setJsonEncoded(uuid, "nx111",       nx111) # possibly null
        FileSystemCheck::fsckObjectErrorAtFirstFailure(uuid)
        Fx256::broadcastObjectEvents(uuid)
        item = NxTasks::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: ec1f1b6f-62b4-4426-bfe3-439a51cf76d4) How did that happen ? 🤨"
        end
        item
    end

    # NxTasks::issueViennaURL(url)
    def self.issueViennaURL(url)
        uuid        = SecureRandom.uuid
        description = "(vienna) #{url}"
        nx111 = {
            "uuid" => SecureRandom.uuid,
            "type" => "url",
            "url"  => url
        }
        Fx18Attributes::setJsonEncoded(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncoded(uuid, "mikuType",    "NxTask")
        Fx18Attributes::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setJsonEncoded(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::setJsonEncoded(uuid, "description", description)
        Fx18Attributes::setJsonEncoded(uuid, "nx111",       nx111)
        FileSystemCheck::fsckObjectErrorAtFirstFailure(uuid)
        Fx256::broadcastObjectEvents(uuid)
        item = NxTasks::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: f78008bf-12d4-4483-b4bb-96e3472d46a2) How did that happen ? 🤨"
        end
        item
    end

    # NxTasks::issueUsingLocation(location)
    def self.issueUsingLocation(location)
        if !File.exists?(location) then
            raise "(error: 52b8592f-a61a-45ef-a886-ed2ab4cec5ed)"
        end
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nx111 = Nx111::locationToAionPointNx111(uuid, location)
        Fx18Attributes::setJsonEncoded(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncoded(uuid, "mikuType",    "NxTask")
        Fx18Attributes::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setJsonEncoded(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::setJsonEncoded(uuid, "description", description)
        Fx18Attributes::setJsonEncoded(uuid, "nx111",       nx111) # possibly null, in principle, although not in the case of a location
        FileSystemCheck::fsckObjectErrorAtFirstFailure(uuid)
        Fx256::broadcastObjectEvents(uuid)
        item = NxTasks::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: 7938316c-cb54-4d60-a480-f161f19718ef) How did that happen ? 🤨"
        end
        item
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        builder = lambda{
            nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : " (line)"
            "(task)#{nx111String} #{item["description"]}"
        }
        builder.call()
    end

    # NxTasks::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(task) #{item["description"]}"
    end

    # NxTasks::section2()
    def self.section2()
        NxTasks::items2(10)
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .select{|item| ItemToGroupMapping::itemuuidToGroupuuids(item["uuid"]).empty? }
    end

    # NxTasks::topUnixtime()
    def self.topUnixtime()
        ([Time.new.to_f] + NxTasks::items().map{|item| item["unixtime"] }).min - 1
    end
end
