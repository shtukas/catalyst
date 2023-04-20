
class TxDrops

    # TxDrops::items()
    def self.items()
        N3Objects::getMikuType("TxDrop")
    end

    # TxDrops::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # TxDrops::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # TxDrops::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        project = TxProjects::interactivelySelectOne()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "TxDrop",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "projectuuid" => project ? project["uuid"] : nil
        }
        puts JSON.pretty_generate(item)
        TxDrops::commit(item)
        item
    end

    # TxDrops::toString(item)
    def self.toString(item)
        "(drop) #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
    end

    # TxDrops::projectDrops(project)
    def self.projectDrops(project)
        TxDrops::items().select{|item| item["projectuuid"] == project["uuid"] }
    end

    # TxDrops::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = TxDrops::items()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", items, lambda{|item| TxDrops::toString(item) })
    end

end