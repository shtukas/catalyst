

class NxCases

    # --------------------------------------------------
    # Makers

    # NxCases::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreData::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        DarkEnergy::init("NxCase", uuid)

        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()

        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)

        DarkEnergy::itemOrNull(uuid)
    end

    # NxCases::interactivelyIssueNewAtParentOrNull(parent)
    def self.interactivelyIssueNewAtParentOrNull(parent)

        position = Tx8s::interactivelyDecidePositionUnderThisParent(parent)
        tx8 = Tx8s::make(parent["uuid"], position)

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreData::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        DarkEnergy::init("NxCase", uuid)

        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()

        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::patch(uuid, "parent", tx8)

        DarkEnergy::itemOrNull(uuid)
    end

    # NxCases::interactivelyIssueNewAtTopAtParentOrNull(parent)
    def self.interactivelyIssueNewAtTopAtParentOrNull(parent)

        tx8 = Tx8s::make(parent["uuid"], Tx8s::newFirstPositionAtThisParent(parent))

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreData::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        DarkEnergy::init("NxCase", uuid)

        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()

        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::patch(uuid, "parent", tx8)

        DarkEnergy::itemOrNull(uuid)
    end

    # NxCases::urlToTask(url)
    def self.urlToTask(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid

        DarkEnergy::init("NxCase", uuid)

        nhash = DarkMatter::putBlob(url)
        coredataref = "url:#{nhash}"

        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxCases::descriptionToTask(description)
    def self.descriptionToTask(description)
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxCase", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::itemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxCases::toString(item)
    def self.toString(item)
        "🔺#{Tx8s::positionInParentSuffix(item)} #{item["description"]}#{CoreData::itemToSuffixString(item)}"
    end

    # --------------------------------------------------
    # Operations

    # NxCases::pile(case_)
    def self.pile(case_)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text.lines.to_a.map{|line| line.strip }.select{|line| line != ""}.reverse.each {|line|
            t1 = NxCases::descriptionToTask(line)
            next if t1.nil?
            puts JSON.pretty_generate(t1)
            t1["parent"] = Tx8s::make(case_["uuid"], Tx8s::newFirstPositionAtThisParent(case_))
            puts JSON.pretty_generate(t1)
            DarkEnergy::commit(t1)
        }
    end

    # NxCases::access(case_)
    def self.access(case_)
        CoreData::access(case_["uuid"], case_["field11"])
    end

    # NxCases::maintenance()
    def self.maintenance()
        # Ensuring consistency of case_ parenting targets
        DarkEnergy::mikuType("NxCase").each{|case_|
            next if case_["parent"].nil?
            if DarkEnergy::itemOrNull(case_["parent"]["uuid"]).nil? then
                DarkEnergy::patch(uuid, "parent", nil)
            end
        }

        # Move orphan case_s to Infinity
        DarkEnergy::mikuType("NxCase").each{|case_|
            next if case_["parent"]
            parent = DarkEnergy::itemOrNull(NxThreads::infinityuuid())
            case_["parent"] = Tx8s::make(parent["uuid"], Tx8s::newFirstPositionAtThisParent(parent))
            DarkEnergy::commit(case_)
        }

        # Feed Infinity using NxIce
        if DarkEnergy::mikuType("NxCase").size < 100 then
            DarkEnergy::mikuType("NxIce").take(10).each{|item|
                item["mikuType"] == "NxCase"
                parent = DarkEnergy::itemOrNull(NxThreads::infinityuuid())
                item["parent"] = Tx8s::make(parent["uuid"], Tx8s::nextPositionAtThisParent(parent))
                DarkEnergy::commit(item)
            }
        end
    end
end
