
class NxFlightData

    # NxFlightData::affineProgression(x0, y0, x1, y1, x)
    def self.affineProgression(x0, y0, x1, y1, x)
        slope = (y1-y0).to_f/(x1-x0)
        (x - x0)*slope + y1 - (x1 - x0)*slope
    end

    # NxFlightData::landing(landingStartPosition, landingEndPosition, landingTimeInHours)
    def self.landing(landingStartPosition, landingEndPosition, landingTimeInHours)
        landingEndPosition + Math.exp(-landingTimeInHours)*(landingStartPosition - landingEndPosition)
    end

    # NxFlightData::dataToPosition(data)
    def self.dataToPosition(data)
        deltaTime = Time.new.to_f - data["startTime"]
        totalTime = data["targetTime"] - data["startTime"]
        if deltaTime <= 0.9*totalTime then
            return NxFlightData::affineProgression(data["startTime"], data["startPosition"], data["targetTime"], data["targetPosition"], Time.new.to_f)
        else
            landingStartPosition = data["startPosition"] + 0.9*(data["targetPosition"] - data["startPosition"])
            landingEndPosition = data["targetPosition"]
            landingStartTime = data["startTime"] + 0.9*totalTime
            landingTimeInHours = (Time.new.to_f - landingStartTime).to_f/3600
            return NxFlightData::landing(landingStartPosition, landingEndPosition, landingTimeInHours)
        end
    end

    # NxFlightData::itemToFlightData(item)
    def self.itemToFlightData(item)
        if item["mikuType"] == "NxAnniversary" then
            return {
                "version"        => 2,
                "startTime"      => Time.new.to_f,
                "startPosition"  => 0.5,
                "targetTime"     => Time.new.to_f + 3600*3,
                "targetPosition" => 0,
                "random"         => rand*0.001
            }
        end

        if item["mikuType"] == "Wave" and item["interruption"] then
            return {
                "version"        => 2,
                "startTime"      => Time.new.to_f,
                "startPosition"  => 0.5,
                "targetTime"     => Time.new.to_f + 3600*3,
                "targetPosition" => 0,
                "random"         => rand*0.001
            }
        end

        if item["mikuType"] == "NxDated" then
            return {
                "version"        => 2,
                "startTime"      => Time.new.to_f,
                "startPosition"  => 0.5,
                "targetTime"     => Time.new.to_f + 3600*6,
                "targetPosition" => 0.2,
                "random"         => rand*0.001
            }
        end

        if item["mikuType"] == "NxFloat" then
            return {
                "version"        => 2,
                "startTime"      => Time.new.to_f,
                "startPosition"  => 0.7,
                "targetTime"     => Time.new.to_f + 3600*6,
                "targetPosition" => 0.2,
                "random"         => rand*0.001
            }
        end

        if item["mikuType"] == "Wave" and !item["interruption"] then
            return {
                "version"        => 2,
                "startTime"      => Time.new.to_f,
                "startPosition"  => 1.0,
                "targetTime"     => Time.new.to_f + 3600*36,
                "targetPosition" => 0.2,
                "random"         => rand*0.001
            }
        end

        if item["mikuType"] == "NxBackup" then
            return {
                "version"        => 2,
                "startTime"      => Time.new.to_f,
                "startPosition"  => 1.0,
                "targetTime"     => Time.new.to_f + 3600*36,
                "targetPosition" => 0.2,
                "random"         => rand*0.001
            }
        end

        raise "(error: e391d4c9-ea1a) I do not know how to NxFlightData::itemToFlightData #{item}"
    end

    # NxFlightData::getFlightData(item)
    def self.getFlightData(item)
        return item["flight-1753"] if item["flight-1753"]
        flightdata = NxFlightData::itemToFlightData(item)
        Items::setAttribute(item["uuid"], "flight-1753", flightdata)
        flightdata
    end

    # NxFlightData::itemToListingMetric(item)
    def self.itemToListingMetric(item)
        flightdata = NxFlightData::getFlightData(item)
        NxFlightData::dataToPosition(flightdata) + flightdata["random"]
    end

    # NxFlightData::detatch(item)
    def self.detatch(item)
        return if item["mikuType"] == "NxLambda"
        Items::setAttribute(item["uuid"], "flight-1753", nil)
    end

    # NxFlightData::issueSituation(item, situation)
    def self.issueSituation(item, situation)
        data = {
            "version"   => 3,
            "unixtime"  => Time.new.to_f,
            "situation" =>  situation
        }
        Items::setAttribute(item["uuid"], "flight-1753", data)
    end

    # NxFlightData::interactivelyDetermineSituationOrNull()
    def self.interactivelyDetermineSituationOrNull()
        situations = Items::items()
                        .select{|item| item["flight-1753"] and item["flight-1753"]["version"] == 3 }
                        .map{|item| item["flight-1753"]["situation"] }
                        .uniq
        if situations.size > 0 then
            situation = LucilleCore::selectEntityFromListOfEntitiesOrNull("situation", situations)
            return situation if situation
        end
        situation = LucilleCore::askQuestionAnswerAsString("situation (empty to abort) : ")
        situation.size > 0 ? situation : nil
    end
end
