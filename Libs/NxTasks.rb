

class NxTasks

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreData::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        DarkEnergy::init("NxTask", uuid)

        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()

        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)

        DarkEnergy::itemOrNull(uuid)
    end

    # NxTasks::interactivelyIssueNewAtParentOrNull(parent)
    def self.interactivelyIssueNewAtParentOrNull(parent)

        position = Tx8s::interactivelyDecidePositionUnderThisParent(parent)
        tx8 = Tx8s::make(parent["uuid"], position)

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreData::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        DarkEnergy::init("NxTask", uuid)

        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()

        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::patch(uuid, "parent", tx8)

        DarkEnergy::itemOrNull(uuid)
    end

    # NxTasks::interactivelyIssueNewAtTopAtParentOrNull(parent)
    def self.interactivelyIssueNewAtTopAtParentOrNull(parent)

        tx8 = Tx8s::make(parent["uuid"], Tx8s::newFirstPositionAtThisParent(parent))

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreData::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        DarkEnergy::init("NxTask", uuid)

        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()

        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::patch(uuid, "parent", tx8)

        DarkEnergy::itemOrNull(uuid)
    end

    # NxTasks::urlToTask(url)
    def self.urlToTask(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid

        DarkEnergy::init("NxTask", uuid)

        nhash = DarkMatter::putBlob(url)
        coredataref = "url:#{nhash}"

        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask(description)
    def self.descriptionToTask(description)
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxTask", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::itemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        "🔺#{Tx8s::positionInParentSuffix(item)} #{item["description"]}#{CoreData::itemToSuffixString(item)}"
    end

    # NxTasks::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxTask")
            .select{|item| item["parent"].nil? or item["show"] }
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::pile(task)
    def self.pile(task)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text.lines.to_a.map{|line| line.strip }.select{|line| line != ""}.reverse.each {|line|
            t1 = NxTasks::descriptionToTask(line)
            next if t1.nil?
            puts JSON.pretty_generate(t1)
            t1["parent"] = Tx8s::make(task["uuid"], Tx8s::newFirstPositionAtThisParent(task))
            puts JSON.pretty_generate(t1)
            DarkEnergy::commit(t1)
        }
    end

    # NxTasks::access(task)
    def self.access(task)
        CoreData::access(task["uuid"], task["field11"])
    end

    # NxTasks::maintenance()
    def self.maintenance()
        # Ensuring consistency of task parenting targets
        DarkEnergy::mikuType("NxTask").each{|task|
            next if task["parent"].nil?
            if DarkEnergy::itemOrNull(task["parent"]["uuid"]).nil? then
                DarkEnergy::patch(uuid, "parent", nil)
            end
        }

        # Move orphan tasks to Infinity
        DarkEnergy::mikuType("NxTask").each{|task|
            next if task["parent"]
            parent = DarkEnergy::itemOrNull(NxThreads::infinityuuid())
            task["parent"] = Tx8s::make(parent["uuid"], Tx8s::newFirstPositionAtThisParent(parent))
            DarkEnergy::commit(task)
        }

        # Feed Infinity using NxIce
        if DarkEnergy::mikuType("NxTask").size < 100 then
            DarkEnergy::mikuType("NxIce").take(10).each{|item|
                item["mikuType"] == "NxTask"
                parent = DarkEnergy::itemOrNull(NxThreads::infinityuuid())
                item["parent"] = Tx8s::make(parent["uuid"], Tx8s::nextPositionAtThisParent(parent))
                DarkEnergy::commit(item)
            }
        end
    end
end
