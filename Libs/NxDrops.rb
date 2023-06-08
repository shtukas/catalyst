
class NxDrops

    # NxDrops::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Solingen::init("NxDrop", uuid)
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::getItemOrNull(uuid)
    end

    # NxDrops::toString(item)
    def self.toString(item)
        "💧 #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
    end

    # NxDrops::program(item)
    def self.program(item)
        puts "NxDrops::program(#{JSON.pretty_generate(item)})"
        actions = [
            "start, access and done",
            "transmute"
        ]
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
        return if action.nil?
        if action == "start, access and done" then
            puts JSON.pretty_generate(item)
            NxBalls::start(item)
            CoreData::access(item["uuid"], item["field11"])
            puts "Waiting until you are done"
            LucilleCore::pressEnterToContinue()
            Solingen::destroy(item["uuid"])
        end
        if action == "transmute" then
            Transmutations::transmute(item)
        end
    end
end