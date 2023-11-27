
class NxEffects

    # NxEffects::issue(uuid, description, behaviour, coredataReference)
    def self.issue(uuid, description, behaviour, coredataReference)
        DataCenter::itemInit(uuid, "NxEffect")
        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "behaviour", behaviour)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::setAttribute(uuid, "field11", coredataReference)
        DataCenter::setAttribute(uuid, "stack", [])
        DataCenter::itemOrNull(uuid)
    end

    # NxEffects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        NxEffects::interactivelyIssueNewOrNull2(uuid)
    end

    # NxEffects::interactivelyIssueNewOrNull2(uuid)
    def self.interactivelyIssueNewOrNull2(uuid)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        behaviour = TxBehaviours::interactivelyMakeNewOnNull()
        return if behaviour.nil?
        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
        NxEffects::issue(uuid, description, behaviour, coredataref)
    end

    # ------------------
    # Data

    # NxEffects::toString(item)
    def self.toString(item)
        "#{TxBehaviours::toIcon(item["behaviour"])} #{TxBehaviours::toString(item["behaviour"])} #{item["description"]}"
    end

    # NxEffects::listingItems(selector)
    def self.listingItems(selector)
        DataCenter::mikuType("NxEffect")
            .select{|item| selector.call(item) }
            .select{|item| TxBehaviours::shouldDisplayInListing(item["behaviour"]) }
    end

    # NxEffects::listingItemsTail()
    def self.listingItemsTail()
        DataCenter::mikuType("NxEffect")
            .select{|item| TxBehaviours::shouldDisplayInListing(item["behaviour"]) }
    end

    # ------------------
    # Ops

    # NxEffects::access(item)
    def self.access(item)
        CoreDataRefStrings::accessAndMaybeEdit(item["uuid"], item["field11"])
    end

    # NxEffects::program(selector, order)
    def self.program(selector, order)
        items = DataCenter::mikuType("NxEffect")
                    .select{|item| selector.call(item) }
                    .sort_by{|item| order.call(item) }
        Catalyst::program2(items)
    end

    # NxEffects::done(item)
    def self.done(item)
        if item["behaviour"]["type"] == "ondate" and item["stack"].size == 0 then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{NxEffects::toString(item).green}' ? ", true) then
                DataCenter::destroy(item["uuid"])
            end
            return
        end
        if item["behaviour"]["type"] == "ondate" and item["stack"].size > 0 then
            puts "You cannot done a NxEffect ondate with a non empty stack"
            LucilleCore::pressEnterToContinue()
            return
        end
        raise "(error: 8e77b5e6-43e7-49ee-a1ac-d76a8c74300d) item: #{item}"
    end
end
