
class NxFlightData

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
        if item["mikuType"] == "NxCore" then
            return  3600 # We need to refine that later by looking at how much time the core actually needs.
        end
        raise "I do not know how to compute flight data duration for #{item}"
    end

    # NxFlightData::itemToDeadline(item)
    def self.itemToDeadline(item)
        todayAt12DateTime = Time.at(CommonUtils::unixtimeAtLastMidnightAtLocalTimezone()+12*3600).utc.iso8601
        todayAt18DateTime = Time.at(CommonUtils::unixtimeAtLastMidnightAtLocalTimezone()+18*3600).utc.iso8601
        dateTimeIn2Hours = Time.at(Time.new.to_i+3600*2).utc.iso8601
        dateTimeIn24Hours = Time.at(Time.new.to_i+86400).utc.iso8601

        if item["mikuType"] == "NxAnniversary" then
            return todayAt12DateTime
        end

        if item["mikuType"] == "Wave" and item["interruption"] then
            return dateTimeIn2Hours
        end

        if item["mikuType"] == "Wave" and !item["interruption"] then
            return dateTimeIn24Hours
        end

        if item["mikuType"] == "NxBackup" then
            return dateTimeIn24Hours
        end

        if item["mikuType"] == "NxCore" then
            return todayAt18DateTime
        end

        if item["mikuType"] == "NxDated" then
            return todayAt12DateTime
        end

        raise "I do not know how to compute flight data deadline for #{item}"
    end

    # ----------------------------------------------------------------
    # Listing support

    # NxFlightData::constructFlightData(items, item)
    def self.constructFlightData(items, item)
        {
            "uuid"       => SecureRandom.hex,
            "mikuType"   => "NxFlightData",
            "position"   => 10 * rand,
            "duration"   => NxFlightData::itemToDuration(item),
            "deadline"   => NxFlightData::itemToDeadline(item)
        }
    end

    # NxFlightData::prepareForListing(items)
    def self.prepareForListing(items)
        p1, p2 = items.partition{|item| item["flight-data-25"] }
        loop {
            break if p2.empty?
            item = p2.shift
            flightdata = NxFlightData::constructFlightData(p1, item)
            item["flight-data-25"] = flightdata
            #Items::setAttribute(item["uuid"], "flight-data-25", flightdata)
            p1 << item
        }

        p1 = p1.sort_by{|item| item["flight-data-25"]["position"] }

        # We are now going to publish the various known ETAs for the various flightdatas

        cursorETA = Time.new.to_i
        p1
            .map{|item| item["flight-data-25"] }
            .each{|flightdata|
                cursorETA = cursorETA + flightdata["duration"]
                XCache::set("f1e2d0bb-6e3e-4381-8c79-d4732488da9c:#{flightdata["uuid"]}", Time.at(cursorETA).utc.iso8601)
            }
        p1
    end

    # NxFlightData::deadlineToString(item)
    def self.deadlineToString(item)
        flightdata = item["flight-data-25"]
        if flightdata.nil? then
            return "" 
        end
        s = " (#{"%.2f" % flightdata["position"]}) [#{flightdata["deadline"]}]"
        cursorETA = XCache::getOrNull("f1e2d0bb-6e3e-4381-8c79-d4732488da9c:#{flightdata["uuid"]}")
        if cursorETA then
            if cursorETA > flightdata["deadline"] then
                s = s.red
            end
        end
        s
    end
end

