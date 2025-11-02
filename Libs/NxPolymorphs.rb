
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
        behaviour = NxPolymorphs::uniqueListingOrFirstNonListingBehaviour(item)
        icon = TxBehaviour::behaviourToIcon(behaviour)

        runningTimespan = (lambda{
            nxball = NxBalls::getNxBallOrNull(item)
            return 0 if nxball.nil?
            NxBalls::ballRunningTime(nxball)
        }).call()

        "#{icon} #{TxBehaviour::behaviourToDescriptionLeft(behaviour)}#{item["description"]}#{TxBehaviour::behaviourToDescriptionRight(behaviour, runningTimespan)}"
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
            .select{|item| item["behaviours"][0]["btype"] == "listing-position" }
            .map{|item| item["behaviours"][0]["position"] }
        return 1 if positions.empty?
        positions.min
    end

    # NxPolymorphs::listingNthPosition(n)
    def self.listingNthPosition(n)
        positions = Items::items()
            .select{|item| item["mikuType"] == "NxPolymorph" }
            .select{|item| item["behaviours"][0]["btype"] == "listing-position" }
            .map{|item| item["behaviours"][0]["position"] }
            .sort
        if positions.size > n then
            return positions.drop(n).first
        end
        positions.max + 1
    end

    # NxPolymorphs::readItemListingPositionOrNull(item)
    def self.readItemListingPositionOrNull(item)
        behaviours = item["behaviours"]
        if behaviours[0]["btype"] == "listing-position" then
            return behaviours[0]["position"]
        end
        nil
    end

    # NxPolymorphs::decideItemListingPositionOrNull(item)
    def self.decideItemListingPositionOrNull(item)
        behaviours = item["behaviours"]
        if behaviours[0]["btype"] == "listing-position" then
            return behaviours[0]["position"]
        end
        behaviours = item["behaviours"].drop_while{|behaviour| behaviour["btype"] == "listing-position" }
        runningTimespan = (lambda{
            nxball = NxBalls::getNxBallOrNull(item)
            return 0 if nxball.nil?
            NxBalls::ballRunningTime(nxball)
        }).call()
        position = TxBehaviour::decideBehaviourListingPositionOrNull(behaviours.first, runningTimespan)
        return nil if position.nil?
        behaviour = {
            "btype" => "listing-position",
            "position" => position
        }
        Items::setAttribute(item["uuid"], "behaviours", [behaviour] + behaviours)
        position
    end

    # NxPolymorphs::uniqueListingOrFirstNonListingBehaviour(item)
    def self.uniqueListingOrFirstNonListingBehaviour(item)
        bs = item["behaviours"].drop_while{|behaviour| behaviour["btype"] == "listing-position" }
        if bs.size > 0 then
            return bs.first
        end
        item["behaviours"].first
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

    # NxPolymorphs::doNotShowUntil(item, unixtime)
    def self.doNotShowUntil(item, unixtime)
        behaviours = item["behaviours"]
        behaviour = {
            "btype" => "do-not-show-until",
            "unixtime" => unixtime
        }
        behaviours = [behaviour] + behaviours
        Items::setAttribute(item["uuid"], "behaviours", behaviours)
    end

    # NxPolymorphs::stop(item)
    def self.stop(item)
        behaviours = item["behaviours"].map{|behaviour| TxBehaviour::stop(behaviour) }.flatten
        Items::setAttribute(item["uuid"], "behaviours", behaviours)
        Items::itemOrNull(item["uuid"])
    end

    # NxPolymorphs::done(item)
    def self.done(item)
        behaviours = item["behaviours"].map{|behaviour| TxBehaviour::done(behaviour) }.flatten
        if behaviours.empty? then
            if LucilleCore::askQuestionAnswerAsBoolean("confirm destroy '#{PolyFunctions::toString(item).green}': ") then
                Items::deleteItem(item["uuid"])
            end
        else
            Items::setAttribute(item["uuid"], "behaviours", behaviours)
        end
    end

    # NxPolymorphs::getTheFirstNonListingPositionBehaviourOrNull(item)
    def self.getTheFirstNonListingPositionBehaviourOrNull(item)
        return nil if item["mikuType"] != "NxPolymorph"
        item["behaviours"].select{|behaviour| behaviour["btype"] != 'listing-position' }.first
    end
end
