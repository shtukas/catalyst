
class ListingPosition

    # ---------------------------------------------------------------
    # Functions & Data

    # ListingPosition::realLineTo01Increasing(x)
    def self.realLineTo01Increasing(x)
        (2 + Math.atan(x)).to_f/10
    end

    # ListingPosition::firstListingPositionForSortingSpecialPositioning()
    def self.firstListingPositionForSortingSpecialPositioning()
        positions = Items::items()
            .select{|item| item["nx41"] }
            .map{|item| item["nx41"]["position"] }
        ([1] + positions).min
    end

    # ListingPosition::decideRatioListingOrNull(behaviour, runningTimespan)
    def self.decideRatioListingOrNull(behaviour, runningTimespan)
        if behaviour["btype"] == "positioned-priority" then
            raise "(error: 5489613f) this case should not happen"
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
        if behaviour["btype"] == "project" then
            ratio1 = Project::ratio(behaviour, runningTimespan)
            ratio2 = BankDerivedData::recoveredAverageHoursPerDay("projects-4798-96c5-0e5fe723633a").to_f/8
            return nil if ratio1 >= 1
            return (0.100 + 0.8 * ratio2) + 0.9 * ratio1
        end
        if behaviour["btype"] == "wave" then
            if behaviour["interruption"] then
                return 0.050
            end
            return 0.400
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

    # ListingPosition::decideItemListingPositionOrNull(item) # [position: null or float, item]
    def self.decideItemListingPositionOrNull(item)
        if item["nx41"] and item["nx41"]["unixtime"].nil? then
            return [item["nx41"]["position"], item]
        end
        if item["nx41"] and (Time.new.to_i - item["nx41"]["unixtime"]) < 3600 then
            return [item["nx41"]["position"], item]
        end
        runningTimespan = (lambda{
            nxball = NxBalls::getNxBallOrNull(item)
            return 0 if nxball.nil?
            NxBalls::ballRunningTime(nxball)
        }).call()
        ratio = ListingPosition::decideRatioListingOrNull(item["bx42"], runningTimespan)
        if ratio.nil? then
            ListingPosition::delist(item)
            return [nil, item]
        end
        position = 1 + ratio
        ListingPosition::setNx41(item, {
            "unixtime" => Time.new.to_i,
            "position" => position
        })
        item = Items::itemOrNull(item["uuid"])
        [position, item]
    end

    # ---------------------------------------------------------------
    # Functions & Data

    # ListingPosition::setNx41(item, nx41 or null)
    def self.setNx41(item, nx41)
        Items::setAttribute(item["uuid"], "nx41", nx41)
    end

    # ListingPosition::delist(item)
    def self.delist(item)
        Items::setAttribute(item["uuid"], "nx41", nil)
    end
end
