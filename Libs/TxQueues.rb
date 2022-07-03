
# encoding: UTF-8

class TxQueues

    # ----------------------------------------------------------------------
    # IO

    # TxQueues::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxQueue")
    end

    # TxQueues::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyClique(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # TxQueues::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        ax39 = Ax39::interactivelyCreateNewAx("TxQueue")

        item = {
            "uuid"        => SecureRandom.uuid,
            "variant"     => SecureRandom.uuid,
            "mikuType"    => "TxQueue",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
            "ax39"        => ax39
        }
        Librarian::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # TxQueues::toString(item)
    def self.toString(item)
        count = Nx07::principaluuidToTaskuuids(item["uuid"]).size
        "(queue) #{item["description"]} #{Ax39::toString(item)} (#{count})"
    end

    # TxQueues::tasks(queue)
    def self.tasks(queue)
        Nx07::principaluuidToTaskuuids(queue["uuid"])
            .map{|uuid| Librarian::getObjectByUUIDOrNullEnforceUnique(uuid) }
            .compact
    end

    # TxQueues::nx20s()
    def self.nx20s()
        TxQueues::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{TxQueues::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end

    # TxQueues::getFirstTaskOrNull(queue)
    def self.getFirstTaskOrNull(queue)
        Nx07::principaluuidToTaskuuids(queue["uuid"]).each{|uuid|
            task = Librarian::getObjectByUUIDOrNullEnforceUnique(uuid)
            next if task.nil?
            if task["mikuType"] != "NxTask" then
                # Some maintenance:
                # Happens when the task has been transformed to a Nyx node, but the link between
                # the queue and the task still exists.
                Nx07::unlink(queue["uuid"], task["uuid"])
                next
            end
            return task if task
        }
        nil
    end

    # TxQueues::itemsForMainListing()
    def self.itemsForMainListing()
        # We are not displaying the queues (they are independently displayed in section 1, for landing)
        # Instead we are displaying the first element of any queue that has not yet met they target
        TxQueues::items()
            .select{|item| Ax39::itemShouldShow(item) }
            .map{|queue| TxQueues::getFirstTaskOrNull(queue) }
            .compact
    end

    # ------------------------------------------------
    # Operations

    # TxQueues::diving(queue)
    def self.diving(queue)
        loop {
            tasks = TxQueues::tasks(queue)
                        .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
                        .first(10)
            if tasks.size == 0 then
                puts "no tasks found for '#{project["description"]}'"
                LucilleCore::pressEnterToContinue()
                return
            end
            task = LucilleCore::selectEntityFromListOfEntitiesOrNull("task", tasks, lambda{|task| NxTasks::toString(task) })
            break if task.nil?
            Landing::implementsNx111Landing(task)
        }
    end

    # TxQueues::landing(queue)
    def self.landing(queue)
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["update description", "access tasks"])
        return if action.nil?
        if action == "update description" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            queue["description"] = description
            Librarian::commit(queue)
        end
        if action == "access tasks" then
            TxQueues::diving(queue)
        end
    end
end
