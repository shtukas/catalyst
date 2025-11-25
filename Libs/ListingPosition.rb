
class ListingPosition

    # ---------------------------------------------------------------
    # Functions & Data

    # ListingPosition::realLineTo01Increasing(x)
    def self.realLineTo01Increasing(x)
        (2 + Math.atan(x)).to_f/10
    end

    # ListingPosition::firstListingPositionForPriorities()
    def self.firstListingPositionForPriorities()
        positions = Items::objects()
            .select{|item| item["nx41"] }
            .map{|item| item["nx41"]["position"] }
        ([-1] + positions).min
    end

    # ListingPosition::decideRatioListingOrNull(behaviour, nx41)
    def self.decideRatioListingOrNull(behaviour, nx41)
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
        if behaviour["btype"] == "anniversary" then
            return 0.150
        end
        raise "(error d8e9d7a7) I do not know how to compute ratio for behaviour: #{behaviour}"
    end

    # ListingPosition::decideItemListingPositionOrNull(item)
    def self.decideItemListingPositionOrNull(item)
        if item["nx41"] and (Time.new.to_i - item["nx41"]["unixtime"]) < 3600 then
            return item["nx41"]["position"]
        end
        if item["mikuType"] == "NxProject" then
            position = NxProjects::listingPosition(item)
            Items::setAttribute(item["uuid"], "nx41", {
                "unixtime" => Time.new.to_f,
                "position" => position
            })
            return position
        end
        if item["mikuType"] == "NxTask" then
            position = 0.2 + 0.4 * BankDerivedData::recoveredAverageHoursPerDay(item["uuid"]) + 0.4 * BankDerivedData::recoveredAverageHoursPerDay("task-account-8e7fa41a").to_f/2
            Items::setAttribute(item["uuid"], "nx41", {
                "unixtime" => Time.new.to_f,
                "position" => position
            })
            return position
        end
        if item["mikuType"] == "NxPolymorph" then
            ratio = ListingPosition::decideRatioListingOrNull(item["bx42"], item["nx41"])
            if ratio.nil? then
                Items::setAttribute(item["uuid"], "nx41", nil)
                return nil
            end
            position = ratio
            Items::setAttribute(item["uuid"], "nx41", {
                "unixtime" => Time.new.to_f,
                "position" => position
            })
            return position
        end
        if item["mikuType"] == "NxPriority" then
            return item["position-09"]
        end
        raise "[error: 4DC6AEBD] I do not know how to decide the listing position for item: #{item}"
    end

    # ListingPosition::delistItemAndSimilar(item)
    def self.delistItemAndSimilar(item)
        Items::setAttribute(item["uuid"], "nx41", nil)
        if item["mikuType"] == "NxProject" then
            Items::mikuType("NxProject").each{|item|
                Items::setAttribute(item["uuid"], "nx41", nil)
            }
        end
        if item["mikuType"] == "NxTask" then
            NxTasks::listingItems().each{|item|
                Items::setAttribute(item["uuid"], "nx41", nil)
            }
        end
    end
end
