
class NxDateds

    # NxDateds::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
        payload = UxPayload::makeNewOrNull()
        Items::itemInit(uuid, "NxDated")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "date", datetime[0, 10])
        Items::itemOrNull(uuid)
    end

    # NxDateds::interactivelyIssueTodayOrNull()
    def self.interactivelyIssueTodayOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        payload = UxPayload::makeNewOrNull()
        Items::itemInit(uuid, "NxDated")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "date", CommonUtils::today())
        Items::itemOrNull(uuid)
    end

    # NxDateds::interactivelyIssueTomorrowOrNull()
    def self.interactivelyIssueTomorrowOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        payload = UxPayload::makeNewOrNull()
        Items::itemInit(uuid, "NxDated")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "date", (Time.new + 86400).to_s[0, 10])
        Items::itemOrNull(uuid)
    end

    # NxDateds::interactivelyIssueAtGivenDateOrNull(date)
    def self.interactivelyIssueAtGivenDateOrNull(date)
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        payload = UxPayload::makeNewOrNull()
        Items::itemInit(uuid, "NxDated")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "date", date)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxDateds::toString(item)
    def self.toString(item)
        "🗓️  [#{item["date"][0, 10]}] #{item["description"]}"
    end

    # NxDateds::listingItems()
    def self.listingItems()
        items = Items::mikuType("NxDated")
            .select{|item| item["date"][0, 10] <= CommonUtils::today() }
            .sort_by{|item| item["unixtime"] }
    end

    # ---------------
    # Ops

    # NxDateds::redate(item, datetime = nil)
    def self.redate(item, datetime = nil)
        NxBalls::stop(item)
        datetime = datetime || CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
        Items::setAttribute(item["uuid"], "date", datetime)
    end

    # NxDateds::processPastItems()
    def self.processPastItems()
        NxDateds::listingItems().each{|item|
            if item["date"] < CommonUtils::today() then
                puts "Past ondate: #{NxDateds::toString(item)}".yellow
                options = [
                    "already done",
                    "do now",
                    "today",
                    "redate",
                    "transmute (to task, float)"
                ]
                option = nil
                loop {
                    option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
                    break if option
                }
                if option == "already done" then
                    PolyActions::done(item)
                    Nx10::removeItemFromCache(item["uuid"])
                end
                if option == "do now" then
                    Operations::interactivelySetDonation(item)
                    item = Items::itemOrNull(item["uuid"])
                    PolyActions::double_dots(item)
                    Nx10::removeItemFromCache(item["uuid"])
                end
                if option == "today" then
                    NxDateds::redate(item, CommonUtils::nowDatetimeIso8601())
                    Nx10::removeItemFromCache(item["uuid"])
                end
                if option == "redate" then
                    NxDateds::redate(item, nil)
                    Nx10::removeItemFromCache(item["uuid"])
                end
                if option == "transmute (to task, float)" then
                    Transmutation::transmute2(item)
                    Nx10::removeItemFromCache(item["uuid"])
                end
            end
        } 

    end
end
