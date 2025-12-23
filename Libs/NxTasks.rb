

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
        if $memory1503 and (Time.new.to_i - $memory1503["unixtime"]) < 1200 then
            $memory1503["items"] = $memory1503["items"].map{|item| Items::itemOrNull(item["uuid"]) }.compact
            return $memory1503["items"]
        end

        names = Cores::distinctNames()
        names = names.sort_by{|listname| BankDerivedData::recoveredAverageHoursPerDayCached("tlname-11:#{listname}") }
        name1 = names.first
        items = Items::mikuType("NxTask")
            .select{|item| item["tlname-11"] == name1 }
            .first(20)

        $memory1503 = {}
        $memory1503["items"] = items
        $memory1503["unixtime"] = Time.new.to_i
        $memory1503["items"]
    end
end
