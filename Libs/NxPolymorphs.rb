
class NxPolymorphs

    # --------------------------------------
    # Issue

    # NxPolymorphs::issueNew(uuid, description, behaviours, payload or null)
    def self.issueNew(uuid, description, behaviours, payload)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "behaviours", behaviours)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "mikuType", "NxPolymorph")
        item = Items::itemOrNull(uuid)
        Fsck::fsckOrError(item)
        item
    end

    # --------------------------------------
    # Data

    # NxPolymorphs::toString(item)
    def self.toString(item)
        behaviour = item["behaviours"].first
        icon = TxBehaviour::behaviourToIcon(behaviour)
        "#{icon} #{TxBehaviour::behaviourToDescriptionLeft(behaviour)}#{item["description"]}#{TxBehaviour::behaviourToDescriptionRight(behaviour)}"
    end

    # NxPolymorphs::itemHasBehaviour(item, btype)
    def self.itemHasBehaviour(item, btype)
        item["behaviours"].any?{|behaviour| behaviour["btype"] == btype }
    end

    # NxPolymorphs::behavioursBankAccountNumbers(item)
    def self.behavioursBankAccountNumbers(item)
        return [] if item["mikuType"] != "NxPolymorph"
        item["behaviours"].map{|behaviour| TxBehaviour::bankAccountsNumbers(behaviour) }.flatten
    end

    # NxPolymorphs::listingFirstPosition()
    def self.listingFirstPosition()
        positions = Items::items()
            .select{|item| item["mikuType"] == "NxPolymorph" }
            .map{|item| TxBehaviour::behaviourToListingPositionOrNull(item["behaviours"].first) }
            .compact
        return 1 if positions.empty?
        positions.min
    end

    # --------------------------------------
    # Ops

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

    # NxPolymorphs::removeAnyCalendarItem(item) # Item -> Item
    def self.removeAnyCalendarItem(item)
        return item if item["mikuType"] != "NxPolymorph"
        return item if item["behaviours"].first["btype"] != "DayCalendarItem" 
        item["behaviours"] = item["behaviours"].drop(1)
        Items::setAttribute(item["uuid"], "behaviours", item["behaviours"])
        item
    end

    # NxPolymorphs::doNotShowUntil(item, unixtime)
    def self.doNotShowUntil(item, unixtime)
        item = NxPolymorphs::removeAnyCalendarItem(item)
        behaviours = item["behaviours"]
        behaviour = {
            "btype" => "do-not-show-until",
            "unixtime" => unixtime
        }
        behaviours = [behaviour] + behaviours
        Items::setAttribute(item["uuid"], "behaviours", behaviours)
    end

end
