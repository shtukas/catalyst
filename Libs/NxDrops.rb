
class NxDrops

    # NxDrops::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxDrop", uuid)
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::itemOrNull(uuid)
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
            puts "Next step is destruction"
            LucilleCore::pressEnterToContinue()
            DarkEnergy::destroy(item["uuid"])
        end
        if action == "transmute" then
            Transmutations::transmute(item)
        end
    end
end