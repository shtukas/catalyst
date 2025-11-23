
class ListingPosition

    # ---------------------------------------------------------------
    # Functions & Data

    # ListingPosition::realLineTo01Increasing(x)
    def self.realLineTo01Increasing(x)
        (2 + Math.atan(x)).to_f/10
    end

    # ListingPosition::firstListingPositionForSortingSpecialPositioning()
    def self.firstListingPositionForSortingSpecialPositioning()
        positions = Items::objects()
            .select{|item| item["nx41"] }
            .map{|item| item["nx41"]["position"] }
        ([1] + positions).min
    end

    # ListingPosition::decideRatioListingOrNull(behaviour, nx41, runningTimespan)
    def self.decideRatioListingOrNull(behaviour, nx41, runningTimespan)
        if behaviour["btype"] == "positioned-priority" then
            return nx41["position"]
        end
        if behaviour["btype"] == "ondate" then
            return nil if CommonUtils::today() < behaviour["date"]
            return 0.200
        end
        if behaviour["btype"] == "NxAwait" then
            return 0.250
        end
        if behaviour["btype"] == "backup" then
            return 0.300
        end
        if behaviour["btype"] == "wave" then
            if behaviour["interruption"] then
                return 0.050
            end
            hash1 = Digest::SHA1.hexdigest(behaviour.to_s)
            digits = hash1.gsub(/\D/, '')
            return 0.100 + 0.8 * "0.#{digits}".to_f
        end
        if behaviour["btype"] == "task" then
            return nil if BankDerivedData::recoveredAverageHoursPerDay("task-account-8e7fa41a") >= 1
            return 0.500
        end
        if behaviour["btype"] == "anniversary" then
            return 0.150
        end
        raise "(error d8e9d7a7) I do not know how to compute ratio for behaviour: #{behaviour}"
    end

    # ListingPosition::recomputeItemListingPositionOrNull(item)
    def self.recomputeItemListingPositionOrNull(item)
        runningTimespan = (lambda{
            nxball = NxBalls::getNxBallOrNull(item)
            return 0 if nxball.nil?
            NxBalls::ballRunningTime(nxball)
        }).call()
        ratio = ListingPosition::decideRatioListingOrNull(item["bx42"], item["nx41"], runningTimespan)
        if ratio.nil? then
            Items::setAttribute(item["uuid"], "nx41", nil)
            return nil
        end
        position = 1 + ratio
        Items::setAttribute(item["uuid"], "nx41", {
            "unixtime"     => Time.new.to_f,
            "position"     => position,
            "keepPosition" => false
        })
        position
    end

    # ListingPosition::decideItemListingPositionOrNull(item)
    def self.decideItemListingPositionOrNull(item)
        if item["mikuType"] == "NxProject" then
            return NxProjects::listingPosition(item)
        end
        if item["nx41"] and item["nx41"]["keepPosition"] then
            return item["nx41"]["position"]
        end
        if item["nx41"] and (Time.new.to_i - item["nx41"]["unixtime"]) < 3600 then
            return item["nx41"]["position"]
        end
        ListingPosition::recomputeItemListingPositionOrNull(item)
    end
end
