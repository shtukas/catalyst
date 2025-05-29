
class NxTasks

    # NxTasks::interactivelyIssueNewOrNull(nx1949 = nil)
    def self.interactivelyIssueNewOrNull(nx1949 = nil)
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        payload = UxPayload::makeNewOrNull()
        nx1949 = nx1949 || Operations::makeNx1949OrNull(NxCores::interactivelySelectOneOrNull())
        nx1608 = NxTasks::interactivelyMakeNx1608OrNull()
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "nx1949", nx1949)
        Items::setAttribute(uuid, "nx1608", nx1608)
        Items::itemOrNull(uuid)
    end

    # NxTasks::locationToTask(description, location, nx1949)
    def self.locationToTask(description, location, nx1949)
        uuid = SecureRandom.uuid
        payload = UxPayload::locationToPayload(location)
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "nx1949", nx1949)
        Items::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask(description, nx1949)
    def self.descriptionToTask(description, nx1949)
        uuid = SecureRandom.uuid
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "nx1949", nx1949)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Standard Items

    # NxTasks::icon(item)
    def self.icon(item)
        return "🔺" if item["nx1608"]
        "🔹"
    end

    # NxTasks::toString(item, context)
    def self.toString(item, context = nil)
        px1 = item["nx1608"] ? " (#{NxTasks::activeItemRatio(item)})".yellow : ''
        core = Items::itemOrNull(item["nx1949"]["parentuuid"]) # we assume that it's not null
        px2 = " (#{item["nx1949"]["position"]} @ #{core["description"]})".yellow
        "#{NxTasks::icon(item)} #{item["description"]}#{px1}#{px2}"
    end

    # NxTasks::itemsInPositionOrder()
    def self.itemsInPositionOrder()
        Items::mikuType("NxTask")
            .sort_by{|item| item["nx1949"]["position"] }
    end

    # NxTasks::itemsForListing()
    def self.itemsForListing()

        struct_zero = {
            "coreShouldShow" => {},
            "items" => []
        }

        struct_final = Items::mikuType("NxTask")
            .sort_by{|item| item["nx1949"]["position"] }
            .reduce(struct_zero){|struct, item|
                if struct["items"].size >= 10 then
                    # nothing happens
                else
                    core = Items::itemOrNull(item["nx1949"]["parentuuid"]) # we assume that it's not null
                    if struct["coreShouldShow"][core["uuid"]].nil? then
                        struct["coreShouldShow"][core["uuid"]] = NxCores::shouldShow(core)
                    end
                    if NxBalls::itemIsActive(item) or (struct["coreShouldShow"][core["uuid"]] and DoNotShowUntil::isVisible(item["uuid"]) and Bank1::recoveredAverageHoursPerDay(item["uuid"]) < 1) then
                        struct["items"] = struct["items"] + [item]
                    end
                end
                struct
            }

        struct_final["items"]
    end

    # ------------------
    # Active Items

    # NxTasks::interactivelyMakeNx1608OrNull()
    def self.interactivelyMakeNx1608OrNull()
        hours = LucilleCore::askQuestionAnswerAsString("(active ?) hours per week (empty for none): ")
        return nil if hours == ""
        hours = hours.to_f
        return nil if hours == 0
        {
            "hours" => hours
        }
    end

    # NxTasks::activeItemRatio(item)
    def self.activeItemRatio(item)
        hours = item["nx1608"]["hours"]
        Bank1::recoveredAverageHoursPerDay(item["uuid"]).to_f/(hours/7)
    end

    # NxTasks::activeItems()
    def self.activeItems()
        Items::mikuType("NxTask")
            .select{|item| item["nx1608"] }
    end

    # NxTasks::activeItemsInRatioOrder()
    def self.activeItemsInRatioOrder()
        NxTasks::activeItems()
            .sort_by{|item| NxTasks::activeItemRatio(item) }
    end

    # NxTasks::activeItemsForListing()
    def self.activeItemsForListing()
        NxTasks::activeItemsInRatioOrder()
            .select{|item| NxTasks::activeItemRatio(item) < 1 }
    end

    # ------------------
    # Ops

    # NxTasks::performItemPositioning(item, parentOpt)
    def self.performItemPositioning(item, parentOpt)
        return if parentOpt.nil?
        nx1949 = Operations::makeNx1949OrNull(item, parentOpt)
        return if nx1949.nil?
        Items::setAttribute(item["uuid"], "nx1949", nx1949)
    end
end
