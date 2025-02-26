
class NxTasks

    # NxTasks::interactivelyIssueNewOrNull(nx1940 = nil)
    def self.interactivelyIssueNewOrNull(nx1940 = nil)
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        payload = UxPayload::makeNewOrNull(uuid)
        nx1940 = nx1940 || NxTasks::makeNx1940()
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "nx1940", nx1940)
        Items::itemOrNull(uuid)
    end

    # NxTasks::locationToTask(description, location, nx1940)
    def self.locationToTask(description, location, nx1940)
        uuid = SecureRandom.uuid
        payload = UxPayload::locationToPayload(uuid, location)
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "nx1940", nx1940)
        Items::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask(description, nx1940)
    def self.descriptionToTask(description, nx1940)
        uuid = SecureRandom.uuid
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "nx1940", nx1940)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data (2)

    # NxTasks::icon(item)
    def self.icon(item)
        "🔹"
    end

    # NxTasks::toString(item, context)
    def self.toString(item, context = nil)
        px = "(#{item["nx1940"]["position"]})".yellow
        "#{NxTasks::icon(item)} #{item["description"]} #{px}"
    end

    # NxTasks::itemsForListing()
    def self.itemsForListing()
        activecoreuuids = NxCores::listingItems().map{|core| core["uuid"] }
        Items::mikuType("NxTask")
            .sort_by{|item| item["nx1940"]["position"] }
            .reduce([]){|items, item|
                if items.size >= 10 then
                    items
                else
                    if activecoreuuids.include?(item["nx1940"]["coreuuid"]) and DoNotShowUntil::isVisible(item["uuid"]) and Bank1::recoveredAverageHoursPerDay(item["uuid"]) < 1 then
                        items + [item]
                    else
                        items
                    end
                end
            }
    end

    # ------------------
    # Ops

    # NxTasks::makeNx1940()
    def self.makeNx1940()
        parent = nil
        loop {
            parent = NxCores::interactivelySelectOrNull()
            break if parent
        }
        position = Operations::interactivelySelectGlobalPositionInParent(parent)
        {
            "position" => position,
            "coreuuid" => parent["uuid"]
        }
    end

    # NxTasks::performItemPositioning(item)
    def self.performItemPositioning(item)
        nx1940 = NxTasks::makeNx1940()
        Items::setAttribute(item["uuid"], "nx1940", nx1940)
    end
end
