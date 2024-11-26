
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
        Items::setAttribute(uuid, "global-positioning", rand) # default value to ensure that the item has all the mandatory fields
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
        Items::setAttribute(uuid, "global-positioning", rand) # default value to ensure that the item has all the mandatory fields
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxTasks::toString(item, context)
    def self.toString(item, context = nil)
        "🔹 #{item["description"]}"
    end

    # NxTasks::between10And20InfinityPosition()
    def self.between10And20InfinityPosition()
        items = Items::mikuType("NxTask")
                .sort_by{|item| item["global-positioning"] }
        items = items.drop(10).take(10)
        if items.size == 0 then
            return 1
        end
        if items.size <= 10 then
            return items.last["global-positioning"] + 1
        end
        a = items.first["global-positioning"]
        b = items.last["global-positioning"]
        a + rand * (b - 1)
    end

    # NxTasks::performItemPositioning(item)
    def self.performItemPositioning(item)
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["infinity, 10 to 20 task (default)", "hierarchical"])

        if option.nil? or option == "infinity, 10 to 20 task (default)" then
            position = NxTasks::between10And20InfinityPosition()
            Items::setAttribute(item["uuid"], "global-positioning", position)
        end

        if option == "hierarchical" then
            parent = Operations::interactivelySelectParentInHierarchyOrNull(nil)
            return if parent.nil?
            Items::setAttribute(item["uuid"], "parentuuid-0014", parent["uuid"])
            position = Operations::interactivelySelectPositionInParent(parent)
            Items::setAttribute(item["uuid"], "global-positioning", position)
        end
    end

    # -------------------------------------

    # NxTasks::listingItems()
    def self.listingItems()
        r0 = Bank1::recoveredAverageHoursPerDay("054ec562-1166-4d7b-a646-b5695298c032") # Infinity Zero
        r1 = Bank1::recoveredAverageHoursPerDay("1df84f80-8546-476f-9ed9-84fa84d30a5e") # Infinity One

        items = Items::mikuType("NxTask")
                .select{|item| item["parentuuid-0014"].nil? }
                .sort_by{|item| item["global-positioning"] }

        if r0 < r1 then
            # We want the Zero items, 5 of them
            items
                .reduce([]){|collection, item|
                    if collection.size < 5 then
                        if Bank1::getValue(item["uuid"]) == 0  then
                            collection + [item]
                        else
                            collection
                        end
                    else
                        collection
                    end
                }
        else
            # We want the first 5 One items, in recovery order
            items
                .reduce([]){|collection, item|
                    if collection.size < 5 then
                        if Bank1::getValue(item["uuid"]) > 0  then
                            collection + [item]
                        else
                            collection
                        end
                    else
                        collection
                    end
                }
                .sort_by{|item| Bank1::recoveredAverageHoursPerDay(item["uuid"]) }
        end
    end
end
