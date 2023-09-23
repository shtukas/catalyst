

class NxCruises

    # --------------------------------------------------
    # Makers

    # NxCruises::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        Events::publishItemInit("NxCruise", uuid)

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

    # NxCruises::completionRatio(item)
    def self.completionRatio(item)
        Bank::recoveredAverageHoursPerDayCached(item["uuid"]).to_f/item["rt"]
    end

    # NxCruises::toString(item)
    def self.toString(item)
        "⛵️ (#{"%5.2f" % 100*NxCruises::completionRatio(item) } %) #{item["description"]}#{TxCores::suffix(item)}"
    end

    # NxCruises::listingItems()
    def self.listingItems()
        Catalyst::mikuType("NxCruise")
            .select{|item| NxCruises::completionRatio(item) < 1 }
    end

    # --------------------------------------------------
    # Operations

    # NxCruises::access(item)
    def self.access(item)
        CoreDataRefStrings::access(item["uuid"], item["field11"])
    end

    # NxCruises::fsck()
    def self.fsck()
        Catalyst::mikuType("NxCruise").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end
end
