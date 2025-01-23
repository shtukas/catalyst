
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
    # Data (1)

    # NxTasks::isActive(item)
    def self.isActive(item)
        item["donation-1205"] or item["hours-2037"]
    end

    # NxTasks::isCoreItem(item)
    def self.isCoreItem(item)
        item["parentuuid-0014"]
    end

    # NxTasks::isOrphan(item)
    def self.isOrphan(item)
        !NxTasks::isActive(item) and !NxTasks::isCoreItem(item)
    end

    # ------------------
    # Data (2)

    # NxTasks::icon(item)
    def self.icon(item)
        if NxTasks::isActive(item) and item["hours-2037"] then
            return "🔥"
        end
        if NxTasks::isActive(item) and item["hours-2037"].nil? then
            return "🔺"
        end
        if NxTasks::isCoreItem(item) then
            return "🔹"
        end
        if NxTasks::isOrphan(item)then
            return "▫️ "
        end

        raise "(error: 2158-raiko)"
    end

    # NxTasks::activitySuffix(item)
    def self.activitySuffix(item)
        if item["donation-1205"] and item["hours-2037"] then
            target = Items::itemOrNull(item["donation-1205"])
            if target.nil? then
                Items::setAttribute(item["uuid"], "donation-1205", nil)
                return NxTasks::activitySuffix(item)
            end
            return " (#{item["hours-2037"]} hour/week for #{target["description"]})"
        end

        if item["donation-1205"] and item["hours-2037"].nil? then
            target = Items::itemOrNull(item["donation-1205"])
            if target.nil? then
                Items::setAttribute(item["uuid"], "donation-1205", nil)
                return NxTasks::activitySuffix(item)
            end
            return " (d: #{target["description"]})"
        end

        if item["donation-1205"].nil? and item["hours-2037"] then
            return " (commitment: #{item["hours-2037"]}/week)"
        end

        ""
    end

    # NxTasks::ratioPrelude(item)
    def self.ratioPrelude(item)
        return "" if !NxTasks::isActive(item)
        " (#{"%5.3f" % NxTasks::ratio(item)})".green
    end

    # NxTasks::toString(item, context)
    def self.toString(item, context = nil)
        "#{NxTasks::icon(item)}#{NxTasks::ratioPrelude(item)} #{item["description"]}#{NxTasks::activitySuffix(item).yellow}"
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

    # NxTasks::ratio(item)
    def self.ratio(item)
        raise "(error 1930) #{item}" if !NxTasks::isActive(item)
        hours = item["hours-2037"] ? item["hours-2037"] : 7
        [Bank1::recoveredAverageHoursPerDay(item["uuid"]), 0].max.to_f/(hours.to_f/7)
    end

    # NxTasks::activeItems()
    def self.activeItems()
        Items::mikuType("NxTask")
            .select{|item| NxTasks::isActive(item) }
    end

    # NxTasks::orphanItems()
    def self.orphanItems()
        Items::mikuType("NxTask")
            .select{|item| NxTasks::isOrphan(item) }
    end

    # ------------------
    # Ops

    # NxTasks::performItemPositioningInCore(item)
    def self.performItemPositioningInCore(item)
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

    # NxTasks::performActivation(item)
    def self.performActivation(item)
        parent = NxCores::interactivelySelectOrNull()
        if !parent.nil? then
            Items::setAttribute(item["uuid"], "parentuuid-0014", parent["uuid"])
            position = Operations::interactivelySelectGlobalPositionInParent(parent)
            Items::setAttribute(item["uuid"], "global-positioning-4233", position)
        end

        hours = LucilleCore::askQuestionAnswerAsString("set weekly hours (empty to void) : ")
        if hours != "" then
            hours = hours.to_f
            Items::setAttribute(item["uuid"], "hours-2037", hours)
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
            engine = NxTasks::interactivelyIssueNew()
            Items::setAttribute(item["uuid"], "engine-1706", engine)
        end
        if option == "storage in core" then
            NxTasks::performItemPositioningInCore(item)
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