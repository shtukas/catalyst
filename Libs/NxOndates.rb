
class NxOndates

    # NxOndates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        date = CommonUtils::interactivelyMakeADate()
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "date", date)
        Items::setAttribute(uuid, "payload-37", UxPayloads::makeNewPayloadOrNull())
        Items::setAttribute(uuid, "mikuType", "NxOndate")
        item = Items::itemOrNull(uuid)
        item
    end

    # NxOndates::interactivelyIssueNewWithDetails(description, date)
    def self.interactivelyIssueNewWithDetails(description, date)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "date", date)
        Items::setAttribute(uuid, "payload-37", UxPayloads::makeNewPayloadOrNull())
        Items::setAttribute(uuid, "mikuType", "NxOndate")
        item = Items::itemOrNull(uuid)
        item
    end

    # NxOndates::icon(item)
    def self.icon(item)
        "🗓️ "
    end

    # NxOndates::toString(item)
    def self.toString(item)
        "#{NxOndates::icon(item)} [#{item["date"]}] #{item["description"]}"
    end

    # NxOndates::listingItemsTodayAbsolute()
    def self.listingItemsTodayAbsolute()
        if CommonUtils::today() != XCache::getOrNull("e61c25ae-3139-4ad7-8cc4-0b1142d4a6c8") then
            items = Items::mikuType("NxOndate").select{|item| item["date"] <= CommonUtils::today() }
            # We have not yet selected absolutes for today
            selected, _ = LucilleCore::selectZeroOrMore("today absolute", [], items, lambda {|item| PolyFunctions::toString(item) })
            selected.each{|item|
                Items::setAttribute(item["uuid"], "today-absolute", CommonUtils::today())
            }
            XCache::set("e61c25ae-3139-4ad7-8cc4-0b1142d4a6c8", CommonUtils::today())
        end
        Items::mikuType("NxOndate")
            .select{|item| item["date"] <= CommonUtils::today() }
            .select{|item| item["today-absolute"] == CommonUtils::today() }
    end

    # NxOndates::listingItems()
    def self.listingItems()
        Items::mikuType("NxOndate")
            .select{|item| item["date"] <= CommonUtils::today() }
    end
end
