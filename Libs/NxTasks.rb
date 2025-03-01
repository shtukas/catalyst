
class NxTasks

    # NxTasks::interactivelyIssueNewOrNull(nx1941 = nil)
    def self.interactivelyIssueNewOrNull(nx1941 = nil)
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        payload = UxPayload::makeNewOrNull(uuid)
        nx1941 = nx1941 || NxCores::makeNx1941()
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "nx1941", nx1941)
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
    # Data (2)

    # NxTasks::toString(item, context)
    def self.toString(item, context = nil)
        px = "(#{item["nx1941"]["position"]} @ #{item["nx1941"]["core"]["description"]})".yellow
        "🔹 #{item["description"]} #{px}"
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
    # Ops

    # NxTasks::performItemPositioning(item)
    def self.performItemPositioning(item)
        nx1941 = NxCores::makeNx1941()
        Items::setAttribute(item["uuid"], "nx1941", nx1941)
    end
end
