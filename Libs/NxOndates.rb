
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
        Items::setAttribute(uuid, "payload-uuid-1141", UxPayloads::interactivelyIssueNewGetReferenceOrNull())
        Items::setAttribute(uuid, "mikuType", "NxOndate")
        item = Items::itemOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
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
        Items::setAttribute(uuid, "payload-uuid-1141", UxPayloads::interactivelyIssueNewGetReferenceOrNull())
        Items::setAttribute(uuid, "mikuType", "NxOndate")
        item = Items::itemOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # NxOndates::icon()
    def self.icon()
        "🗓️ "
    end

    # NxOndates::toString(item)
    def self.toString(item)
        "#{NxOndates::icon()} [#{item["date"]}] #{item["description"]}"
    end

    # NxOndates::transmutePastDays()
    def self.transmutePastDays()

        # return true if there has been a successful transform
        performUpdate = lambda{|item|
            string = "#{PolyFunctions::toString(item).green}#{UxPayloads::suffixString(item)}"
            puts "past day transform: #{string.green}"
            choice = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("choice", ["access", "done", "description", "payload", "redate", "absolutely today", "soon", "NxTask"])
            if choice == "access" then
                PolyActions::access(item)
                return false
            end
            if choice == "done" then
                PolyActions::done(item)
                return true
            end
            if choice == "description" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                Items::setAttribute(item["uuid"], "description", description)
                return false
            end
            if choice == "payload" then
                UxPayloads::payloadProgram(item)
                return false
            end
            if choice == "soon" then
                Items::setAttribute(item["uuid"], "mikuType", "NxProject")
                return true
            end
            if choice == "redate" then
                date = CommonUtils::interactivelyMakeADate()
                Items::setAttribute(item["uuid"], "date", date)
                return true
            end
            Transmute::transmuteTo(item, choice)
            true
        }

        past_days = Items::mikuType("NxOndate")
                        .select{|item| item["date"] < CommonUtils::today() }
                        .sort_by{|item| item["unixtime"] }

        return if past_days.empty?

        past_days.each{|item|
            loop {
                item = Items::itemOrNull(item["uuid"])
                status = performUpdate.call(item)
                break if status
            }
        }
    end

    # NxOndates::listingItems()
    def self.listingItems()
        NxOndates::transmutePastDays()
        Items::mikuType("NxOndate").select{|item| item["date"] <= CommonUtils::today() }
    end
end
