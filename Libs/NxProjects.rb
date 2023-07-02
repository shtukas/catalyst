
class NxProjects

    # NxProjects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxProject", uuid)
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()
        engine = TxEngines::interactivelyMakeEngine()
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::patch(uuid, "engine", engine)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxProjects::toString(item)
    def self.toString(item)
        "⛵️ #{item["description"]}#{CoreData::itemToSuffixString(item)} #{TxEngines::toString(item["engine"])}"
    end

    # NxProjects::toStringForMainListing(item)
    def self.toStringForMainListing(item)
        "⛵️ #{item["description"]}#{CoreData::itemToSuffixString(item)}#{TxCores::coreSuffix(item)} #{TxEngines::toString(item["engine"])}"
    end

    # NxProjects::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxProject").select{|project|
            TxEngines::compositeCompletionRatio(project["engine"]) < 1
        }
    end

    # NxProjects::maintenance()
    def self.maintenance()
        DarkEnergy::mikuType("TxProject").each{|project|
            engine = project["engine"]
            engine = TxEngines::engine_maintenance(engine)
            next if engine.nil?
            DarkEnergy::patch(project["uuid"], "engine", engine)
        }
    end
end
