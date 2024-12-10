
class NxFlightData

    # ----------------------------------------------------------------
    # Utils

    # NxFlightData::theNext6am(unixtime)
    def self.theNext6am(unixtime)
        cursor = unixtime + 3600
        loop {
            break  if Time.at(cursor).hour == 6
            cursor = cursor + 600
        }
        cursor
    end

    # NxFlightData::isNight(unixtime)
    def self.isNight(unixtime)
        Time.at(unixtime).hour > 21 or Time.at(unixtime).hour < 6
    end

    # NxFlightData::identityOrTheNext6Am(unixtime)
    def self.identityOrTheNext6Am(unixtime)
        if NxFlightData::isNight(unixtime) then
            NxFlightData::theNext6am(unixtime)
        else
            unixtime
        end
    end

    # ----------------------------------------------------------------
    # Intelligence

    # NxFlightData::itemToDuration(item)
    def self.itemToDuration(item)
        if item["mikuType"] == "NxAnniversary" then
            return 0
        end
        if item["mikuType"] == "Wave" then
            return 60*30 # 30 mins # we will refine that later, possibly by letting the item compute its average duration.
        end
        if item["mikuType"] == "NxBackup" then
            return 600 # 10 minutes
        end
        if item["mikuType"] == "NxDated" then
            return 3600
        end
        raise "I do not know how to compute flight data duration for #{item}"
    end

    # NxFlightData::itemToDeadline(item)
    def self.itemToDeadline(item)
        if item["mikuType"] == "NxAnniversary" then
            return Time.new.to_i + 3600*2 # 2 hours
        end
        if item["mikuType"] == "Wave" and item["interruption"] then
            return Time.new.to_i + 3600*2 # 2 hours
        end
        if item["mikuType"] == "Wave" and !item["interruption"] then
            return Time.new.to_i + 86400*1.5 # 1.5 days
        end
        if item["mikuType"] == "NxBackup" then
            return Time.new.to_i + 86400*3 # 3 days
        end
        if item["mikuType"] == "NxDated" then
            return Time.new.to_i + 3600*2 # 2 hours
        end
        raise "I do not know how to compute flight data duration for #{item}"
    end

    # ----------------------------------------------------------------
    # Data

    # NxFlightData::flyingItemsInOrder()
    def self.flyingItemsInOrder()
        Items::items()
            .select{|item| item["flight-data-27"] }
            .sort_by{|item| item["flight-data-27"]["calculated-start"] }
    end

    # NxFlightData::calculateStartTime(items, item, duration) # we return a calculated start time
    def self.calculateStartTime(items, item, duration)
        # Tries and fits the items as early as possible in the list, return the start time that makes it possible

        if item["mikuType"] == "Wave" and item["nx46"]["type"] == "sticky" then
            return Waves::nx46ToNextDisplayUnixtime(item["nx46"])
        end
        if items.empty? then
            return NxFlightData::identityOrTheNext6Am(Time.new.to_i)
        end
        if items.size == 1 then
            item = items[0]
            return NxFlightData::identityOrTheNext6Am(item["flight-data-27"]["calculated-start"] + item["flight-data-27"]["estimated-duration"] * 1.2) # +20 %
        end
        item1 = items[0]
        item2 = items[1]
        end1 = NxFlightData::identityOrTheNext6Am(item1["flight-data-27"]["calculated-start"] + item1["flight-data-27"]["estimated-duration"] * 1.1) # +10 %
        start2 = item2["flight-data-27"]["calculated-start"]
        if end1 + duration <= start2 then
            return end1
        end
        NxFlightData::calculateStartTime(items.drop(1), item, duration)
    end

    # NxFlightData::flightStartToString(item)
    def self.flightStartToString(item)
        flightdata = item["flight-data-27"]
        if flightdata.nil? then
            return "" 
        end
        if flightdata["calculated-start"] < Time.new.to_i then
            return " [#{Time.at(flightdata["calculated-start"]).utc.iso8601}]".red
        end
        if Time.at(flightdata["calculated-start"]).utc.iso8601[0, 10] == CommonUtils::today() then
            return " [#{Time.at(flightdata["calculated-start"]).utc.iso8601}]".yellow
        end
        " [#{Time.at(flightdata["calculated-start"]).utc.iso8601}]"
    end

    # NxFlightData::updateEstimatedStart(flightdata, unixtime)
    def self.updateEstimatedStart(flightdata, unixtime) # flightdata
        flightdata["calculated-start"] = unixtime
        flightdata
    end

    # ----------------------------------------------------------------
    # Ops

    # NxFlightData::ensureFlightData(item)
    def self.ensureFlightData(item)
        return if item["flight-data-27"]
        duration = NxFlightData::itemToDuration(item)
        start = NxFlightData::calculateStartTime(NxFlightData::flyingItemsInOrder(), item, duration)
        start = [start, NxFlightData::itemToDeadline(item)].min
        flightdata = {
            "calculated-start"   => start,
            "estimated-duration" => duration,
            "hasBeenResheduled"  => false
        }
        puts JSON.pretty_generate(flightdata)
        Items::setAttribute(item["uuid"], "flight-data-27", flightdata)
    end

    # NxFlightData::resheduleItemAtTheEnd(item)
    def self.resheduleItemAtTheEnd(item)
        flightdata1 = NxFlightData::flyingItemsInOrder().map{|i| i["flight-data-27"] }.reverse.first
        flightdata2 = {
            "calculated-start"   => flightdata1["calculated-start"] + flightdata1["estimated-duration"] + 3600,
            "estimated-duration" => item["flight-data-27"]["estimated-duration"],
            "flight-data-27"     => true
        }
        puts JSON.pretty_generate(item)
        puts JSON.pretty_generate(flightdata2)
        Items::setAttribute(item["uuid"], "flight-data-27", flightdata2)
    end

    # NxFlightData::rescheduleAllLateFlightData()
    def self.rescheduleAllLateFlightData()
        canBeAutomaticallyRescheduled = lambda {|item|
            return false if NxBalls::itemIsActive(item)
            return true if item["mikuType"] == "NxTimeCapsule"
            return true if item["mikuType"] == "Wave" and !item["interruption"]
            false
        }
        NxFlightData::flyingItemsInOrder().each {|item|
            next if item["flight-data-27"]["calculated-start"] >= Time.new.to_i
            next if !canBeAutomaticallyRescheduled.call(item)
            NxFlightData::resheduleItemAtTheEnd(item)
        }
    end

end

