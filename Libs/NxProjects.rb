

class NxProjects

    # --------------------------------------------------
    # Makers

    # NxProjects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        Events::publishItemInit("NxProject", uuid)

        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
        rt = LucilleCore::askQuestionAnswerAsString("hours per week (will be converted into a rt): ").to_f/7

        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "field11", coredataref)
        Events::publishItemAttributeUpdate(uuid, "rt", rt)

        Catalyst::itemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxProjects::completionRatio(item)
    def self.completionRatio(item)
        Bank::recoveredAverageHoursPerDayCached(item["uuid"]).to_f/item["rt"]
    end

    # NxProjects::toString(item)
    def self.toString(item)
        prefix = "(rt: #{"%5.2f" % (100*NxProjects::completionRatio(item)) } % of #{"%4.2f" % item["rt"]} hours)".green
        "⛵️ #{prefix} #{item["description"]}#{TxCores::suffix(item)}"
    end

    # NxProjects::listingItems()
    def self.listingItems()
        Catalyst::mikuType("NxProject")
            .select{|item| NxProjects::completionRatio(item) < 1 }
    end

    # --------------------------------------------------
    # Operations

    # NxProjects::access(item)
    def self.access(item)
        CoreDataRefStrings::access(item["uuid"], item["field11"])
    end

    # NxProjects::fsck()
    def self.fsck()
        Catalyst::mikuType("NxProject").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end
end
