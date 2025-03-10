
$ActiveItems1735 = nil

class NxTasks

    # NxTasks::interactivelyIssueNewOrNull(nx1941 = nil)
    def self.interactivelyIssueNewOrNull(nx1941 = nil)
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        payload = UxPayload::makeNewOrNull(uuid)
        nx1941 = nx1941 || NxCores::makeNx1941()
        nx1608 = NxTasks::interactivelyMakeNx1608OrNull()
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "nx1941", nx1941)
        Items::setAttribute(uuid, "nx1608", nx1608)
        Items::itemOrNull(uuid)
    end

    # NxTasks::locationToTask(description, location, nx1941)
    def self.locationToTask(description, location, nx1941)
        uuid = SecureRandom.uuid
        payload = UxPayload::locationToPayload(uuid, location)
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "nx1941", nx1941)
        Items::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask(description, nx1941)
    def self.descriptionToTask(description, nx1941)
        uuid = SecureRandom.uuid
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "nx1941", nx1941)
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
        px2 = " (#{item["nx1941"]["position"]} @ #{item["nx1941"]["core"]["description"]})".yellow
        "#{NxTasks::icon(item)} #{item["description"]}#{px1}#{px2}"
    end

    # NxTasks::itemsForListing()
    def self.itemsForListing()

        struct_zero = {
            "coreShouldShow" => {},
            "items" => []
        }

        struct_final = Items::mikuType("NxTask")
            .sort_by{|item| item["nx1941"]["position"] }
            .reduce(struct_zero){|struct, item|
                if struct["items"].size >= 10 then
                    # nothing happens
                else
                    core = item["nx1941"]["core"]
                    if struct["coreShouldShow"][core["uuid"]].nil? then
                        struct["coreShouldShow"][core["uuid"]] = NxCores::shouldShow(core)
                    end
                    if NxBalls::itemIsActive(item) or (struct["coreShouldShow"][core["uuid"]] and DoNotShowUntil::isVisible(item["uuid"])) then
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

    # NxTasks::activeItemsCached()
    def self.activeItemsCached()
        if $ActiveItems1735 and Time.new.to_i - $ActiveItems1735['unixtime'] < 3600 then
            return $ActiveItems1735["items"]
        end
        $ActiveItems1735  = {
            "unixtime" => Time.new.to_i,
            "items" => NxTasks::activeItems()
        }
        $ActiveItems1735["items"]
    end

    # NxTasks::activeItemsForListing()
    def self.activeItemsForListing()
        NxTasks::activeItemsCached()
            .sort_by{|item| NxTasks::activeItemRatio(item) }
            .select{|item| NxTasks::activeItemRatio(item) < 1 }
    end

    # ------------------
    # Ops

    # NxTasks::performItemPositioning(item)
    def self.performItemPositioning(item)
        nx1941 = NxCores::makeNx1941()
        Items::setAttribute(item["uuid"], "nx1941", nx1941)
    end
end
