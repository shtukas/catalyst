
class NxDelegates

    # NxDelegates::issue(line)
    def self.issue(line)
        description = line
        uuid = SecureRandom.uuid
        Cubes::init(nil, "NxDelegate", uuid)
        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute2(uuid, "description", description)
        Cubes::itemOrNull(uuid)
    end

    # NxDelegates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxDelegates::issue(description)
    end

    # NxDelegates::interactivelyIssueNewAtParentOrNull(parent)
    def self.interactivelyIssueNewAtParentOrNull(parent)
        position = Tx8s::interactivelyDecidePositionUnderThisParentOrNull(parent)
        return nil if position.nil?
        tx8 = Tx8s::make(parent["uuid"], position)
        delegate = NxDelegates::interactivelyIssueNewOrNull()
        return nil if delegate.nil?
        Cubes::setAttribute2(delegate["uuid"], "parent", tx8)
    end

    # NxDelegates::toString(item)
    def self.toString(item)
        "🐞 #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item)}#{Tx8s::suffix(item)}"
    end

    # NxDelegates::listingItems()
    def self.listingItems()
        Cubes::mikuType("NxDelegate")
    end

    # NxDelegates::maintenance()
    def self.maintenance()
        Cubes::mikuType("NxDelegate")
            .each{|delegate| 
                next if delegate["parent"].nil?
                if Cubes::itemOrNull(delegate["parent"]["uuid"]).nil? then
                    Cubes::setAttribute2(delegate["uuid"], "parent", nil)
                end
            }
    end

    # NxDelegates::program1()
    def self.program1()
        loop {
            delegate = LucilleCore::selectEntityFromListOfEntitiesOrNull("delegate", Cubes::mikuType("NxDelegate"), lambda{|delegate| NxDelegates::toString(delegate) })
            return if delegate.nil?
            puts JSON.pretty_generate(delegate)
            PolyActions::access(delegate)
        }
    end
end
