

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
        "🔹#{Tx8s::positionInParentSuffix(item)} #{item["description"]}#{CoreData::itemToSuffixString(item)}"
    end

    # NxTasks::toStringForMainListing(item)
    def self.toStringForMainListing(item)
        "🔹#{Tx8s::positionInParentSuffix(item)} #{item["description"]}#{CoreData::itemToSuffixString(item)}#{TxCores::coreSuffix(item)}"
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
end
