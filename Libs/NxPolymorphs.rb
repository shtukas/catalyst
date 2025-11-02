
class NxPolymorphs

    # --------------------------------------
    # Issue

    # NxPolymorphs::issueNew(uuid, description, behaviour, payload or null)
    def self.issueNew(uuid, description, behaviour, payload)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "bx42", behaviour)
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
        icon = TxBehaviour::behaviourToIcon(item["bx42"])
        runningTimespan = (lambda{
            nxball = NxBalls::getNxBallOrNull(item)
            return 0 if nxball.nil?
            NxBalls::ballRunningTime(nxball)
        }).call()
        "#{icon} #{TxBehaviour::behaviourToDescriptionLeft(item["bx42"])}#{item["description"]}#{TxBehaviour::behaviourToDescriptionRight(item["bx42"], runningTimespan)}"
    end

    # NxPolymorphs::listingFirstPosition()
    def self.listingFirstPosition()
        positions = Items::items()
            .select{|item| item["mikuType"] == "NxPolymorph" }
            .map{|item| item["listing-position-2141"] }
            .compact
        return 1 if positions.empty?
        positions.min
    end

    # NxPolymorphs::listingNthPosition(n)
    def self.listingNthPosition(n)
        positions = Items::items()
            .select{|item| item["mikuType"] == "NxPolymorph" }
            .map{|item| item["listing-position-2141"] }
            .compact
            .sort
        if positions.size > n then
            return positions.drop(n).first
        end
        positions.max + 1
    end

    # NxPolymorphs::decideItemListingPositionOrNull(item)
    def self.decideItemListingPositionOrNull(item)
        if item["listing-position-2141"] then
            return item["listing-position-2141"]
        end
        runningTimespan = (lambda{
            nxball = NxBalls::getNxBallOrNull(item)
            return 0 if nxball.nil?
            NxBalls::ballRunningTime(nxball)
        }).call()
        position = TxBehaviour::decideListingPositionOrNull(item["bx42"], runningTimespan)
        return nil if position.nil?
        Items::setAttribute(item["uuid"], "listing-position-2141", position)
        position
    end

    # --------------------------------------
    # Ops

    # NxPolymorphs::doNotShowUntil(item, unixtime)
    def self.doNotShowUntil(item, unixtime)
        Items::setAttribute(item["uuid"], "do-not-show-until-51", Time.at(unixtime).utc.iso8601)
    end

    # NxPolymorphs::stop(item)
    def self.stop(item)
        Items::setAttribute(item["uuid"], "listing-position-2141", nil)
        Items::itemOrNull(item["uuid"])
    end

    # NxPolymorphs::done(item)
    def self.done(item)
        packet = TxBehaviour::done(item["bx42"]) # null or { "behaviour" => behaviour, "do-not-show-until" => unixtime }
        if packet then
            Items::setAttribute(item["uuid"], "listing-position-2141", nil)
            Items::setAttribute(item["uuid"], "do-not-show-until-51", Time.at(packet["do-not-show-until"]).utc.iso8601)
            Items::setAttribute(item["uuid"], "bx42", packet["behaviour"])
        else
            if LucilleCore::askQuestionAnswerAsBoolean("confirm destroy '#{PolyFunctions::toString(item).green}': ") then
                Items::deleteItem(item["uuid"])
            end
        end
    end
end
