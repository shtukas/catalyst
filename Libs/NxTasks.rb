
class NxTasks

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        payload = UxPayload::makeNewOrNull(uuid)
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "global-positioning-4233", rand) # default value to ensure that the item has all the mandatory fields
        Items::itemOrNull(uuid)
    end

    # NxTasks::locationToTask(description, location)
    def self.locationToTask(description, location)
        uuid = SecureRandom.uuid
        payload = UxPayload::locationToPayload(uuid, location)
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "global-positioning-4233", rand) # default value to ensure that the item has all the mandatory fields
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxTasks::icon(item)
    def self.icon(item)
        if item["engine-1706"] then
            return item["engine-1706"]["version"] == 1 ? "🔺" : "🔹"
        end
        "▫️ "
    end

    # NxTasks::toString(item, context)
    def self.toString(item, context = nil)
        engine = item["engine-1706"] # can be null
        "#{NxTasks::icon(item)}#{NxEngines::toStringSuffix(item["uuid"], engine)} #{item["description"]}"
    end

    # NxTasks::taskInsertionPosition()
    def self.taskInsertionPosition()
        positions = Items::mikuType("NxTask")
                        .map{|item| item["global-positioning-4233"] }
                        .sort

        positions = positions.drop(10).take(10)

        if positions.size < 2 then
            return positions.last + 1
        end

        0.5 * (positions.first + positions.last)
    end

    # NxTasks::getItemsEngine(version)
    def self.getItemsEngine(version)
        Items::mikuType("NxTask")
            .select{|item| item["engine-1706"] and item["engine-1706"]["version"] == version }
    end

    # NxTasks::listingPhase1()
    def self.listingPhase1()
        NxTasks::getItemsEngine(1)
            .select{|item| item["listing-positioning-2141"].nil? or item["listing-positioning-2141"] < Time.new.to_i }
            .select{|item| NxEngines::ratio(item["uuid"], item["engine-1706"]) < 1 }
            .sort_by{|item| NxEngines::ratio(item["uuid"], item["engine-1706"]) }
    end

    # NxTasks::listingPhase2()
    def self.listingPhase2()
        activecoresuuids = NxCores::listingItems().map{|item| item["uuid"] }
        NxTasks::getItemsEngine(2)
            .select{|item| item["listing-positioning-2141"].nil? or item["listing-positioning-2141"] < Time.new.to_i }
            .select{|item| item["uuid"] != "b5c3c45c-0436-4f63-b443-227c20586100" or NxTaskSpecialCircumstances::bufferInHasItems() }
            .select{|item| activecoresuuids.include?(item["engine-1706"]["targetuuid"]) }
            .sort_by{|item| Bank1::recoveredAverageHoursPerDay(item["uuid"]) }
    end

    # NxTasks::listingPhase3()
    def self.listingPhase3()
        Items::mikuType("NxTask")
            .select{|item| item["engine-1706"].nil? and item["parentuuid-0014"].nil? }
            .sort_by{|item| item["global-positioning-4233"] }
            .take(10)
    end

    # NxTasks::activeItems()
    def self.activeItems()
        items1 = Items::mikuType("NxTask")
                .select{|item| item["engine-1706"] and item["engine-1706"]["version"] == 1 }
                .sort_by{|item| NxEngines::ratio(item["uuid"], item["engine-1706"]) }

        items2 = Items::mikuType("NxTask")
                .select{|item| item["engine-1706"] and item["engine-1706"]["version"] == 2 }
                .sort_by{|item| Bank1::recoveredAverageHoursPerDay(item["uuid"]) }

        items1 + items2
    end

    # ------------------
    # Ops

    # NxTasks::performItemPositioningInStack(item)
    def self.performItemPositioningInStack(item)
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["Infinity, 10 to 20 task (default)", "NxCore"])

        if option.nil? or option == "Infinity, 10 to 20 task (default)" then
            position = NxTasks::taskInsertionPosition()
            Items::setAttribute(item["uuid"], "global-positioning-4233", position)
        end

        if option == "NxCore" then
            parent = NxCores::interactivelySelectOrNull()
            return if parent.nil?
            Items::setAttribute(item["uuid"], "parentuuid-0014", parent["uuid"])
            position = Operations::interactivelySelectGlobalPositionInParent(parent)
            Items::setAttribute(item["uuid"], "global-positioning-4233", position)
        end
    end

    # NxTasks::performGeneralItemPositioning(item)
    def self.performGeneralItemPositioning(item)
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["activation", "storage in core"])
        if option.nil? then
            NxTasks::performGeneralItemPositioning(item)
            return
        end
        if option == "activation" then
            engine = NxEngines::interactivelyIssueNew()
            Items::setAttribute(item["uuid"], "engine-1706", engine)
        end
        if option == "storage in core" then
            NxTasks::performItemPositioningInStack(item)
        end
    end
end

class NxTaskSpecialCircumstances

    # NxTaskSpecialCircumstances::bufferInHasItems()
    def self.bufferInHasItems()
        directory = "#{Config::pathToGalaxy()}/DataHub/Buffer-In"
        LucilleCore::locationsAtFolder(directory).size > 0
    end
end