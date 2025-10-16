
class NxPolymorphs

    # NxPolymorphs::issueNew(description, behaviour, null | payload)
    def self.issueNew(description, behaviour, payload)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "behaviours", [behaviour])
        Items::setAttribute(uuid, "payload-1310", payload)
        Items::setAttribute(uuid, "mikuType", "NxPolymorph")
        Items::itemOrNull(uuid)
    end

    # NxPolymorphs::toString(item)
    def self.toString(item)
        behaviour = item["behaviours"].first
        icon = TxBehaviour::behaviourToIcon(behaviour)
        "#{icon} #{TxBehaviour::behaviourToDescriptionLeft(behaviour)}#{item["description"]}#{TxBehaviour::behaviourToDescriptionRight(behaviour)}"
    end

    # NxPolymorphs::doNotShowUntil(item, unixtime)
    def self.doNotShowUntil(item, unixtime)
        behaviour = {
            "btype" => "do-not-show-until",
            "unixtime" => unixtime
        }
        behaviours = [behaviour] + item["behaviours"]
        Items::setAttribute(item["uuid"], "behaviours", behaviours)
    end

    # NxPolymorphs::itemHasBehaviour(item, btype)
    def self.itemHasBehaviour(item, btype)
        item["behaviours"].any?{|behaviour| behaviour["btype"] == btype }
    end

    # NxPolymorphs::identityOrSimilarWithUpdatedBehaviours(item)
    def self.identityOrSimilarWithUpdatedBehaviours(item)
        trace1 = JSON.generate(item["behaviours"])
        item["behaviours"] = item["behaviours"]
            .map{|behaviour| TxBehaviour::preDisplayProcessing(behaviour) }
            .flatten
        trace2 = JSON.generate(item["behaviours"])
        return item if trace1 == trace2
        Items::setAttribute(item["uuid"], "behaviours", item["behaviours"])
        item
    end

    # NxPolymorphs::behavioursBankAccountNumbers(item)
    def self.behavioursBankAccountNumbers(item)
        return [] if item["mikuType"] != "NxPolymorph"
        item["behaviours"].map{|behaviour| TxBehaviour::bankAccountsNumbers(behaviour) }.flatten
    end
end
