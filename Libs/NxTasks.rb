

$memory1503 = nil

class NxTasks

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "payload-37", UxPayloads::makeNewPayloadOrNull())
        Items::setAttribute(uuid, "mikuType", "NxTask")
        item = Items::itemOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # ----------------------
    # Data

    # NxTasks::icon()
    def self.icon()
        "🔹"
    end

    # NxTasks::toString(item)
    def self.toString(item)
        "#{NxTasks::icon()} #{item["description"]}#{Cores::suffix(item)}"
    end

    # NxTasks::listingItems()
    def self.listingItems()
        memory = JSON.parse(XCache::getOrDefaultValue("89d69959-2a82-411d-b980-98986113bb3d", "null"))
        if memory and (Time.new.to_i - memory["unixtime"]) < 1200 then
            memory["items"] = memory["items"].map{|item| Items::itemOrNull(item["uuid"]) }.compact
            if memory["items"].size > 0 then
                XCache::set("89d69959-2a82-411d-b980-98986113bb3d", JSON.generate(memory))
                return memory["items"]
            end
        end

        names = Cores::distinctNames()
        names = names.sort_by{|listname| BankDerivedData::recoveredAverageHoursPerDayCached("tlname-11:#{listname}") }
        name1 = names.first
        items = Items::mikuType("NxTask")
            .select{|item| item["tlname-11"] == name1 }
            .first(20)

        memory = {
            "unixtime" => Time.new.to_i,
            "items" => items
        }
        XCache::set("89d69959-2a82-411d-b980-98986113bb3d", JSON.generate(memory))
        memory["items"]
    end
end
