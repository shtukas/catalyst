
class NxOrbitals

    # NxOrbitals::items()
    def self.items()
        N3Objects::getMikuType("NxOrbital")
    end

    # NxOrbitals::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxOrbitals::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # NxOrbitals::interactivelyIssueNullOrNull(useCoreData: true)
    def self.interactivelyIssueNullOrNull(useCoreData: true)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxOrbital",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref
        }
        puts JSON.pretty_generate(item)
        NxOrbitals::commit(item)
        item
    end

    # NxOrbitals::toString(item)
    def self.toString(item)
        "(orbital) #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
    end

    # NxOrbitals::listingItems(board)
    def self.listingItems(board)
        NxOrbitals::items()
            .select{|item| BoardsAndItems::belongsToThisBoard(item, board) }
    end
end