
class Performance

    # Performance::getDataForTodayOrNull()
    def self.getDataForTodayOrNull()
        return nil if Time.new.hour >= 22
        today = CommonUtils::today()
        filepath = "#{Config::pathToGalaxy()}/DataHub/catalyst/Performance/#{today}.json"
        if File.exist?(filepath) then
            return JSON.parse(IO.read(filepath))
        end
        return {
            "initial-prediction"         => nil, # seconds
            "time-of-initial-prediction" => nil, # unixtime
            "timespan-initial-prediction-to-10pm" => nil, # seconds
            "timespan-since-initial-prediction" => nil, # seconds
            "current-prediction"         => nil, # seconds
            "done"                       => nil, # seconds
            "ideal-done-at-this-time"    => nil, # seconds
            "performance"                => nil  # percentage
        }
    end

    # Performance::commitDataToDisk(data)
    def self.commitDataToDisk(data)
        today = CommonUtils::today()
        filepath = "#{Config::pathToGalaxy()}/DataHub/catalyst/Performance/#{today}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(data)) }
    end

    # Performance::itemPrediction(item)
    def self.itemPrediction(item)
        if item["mikuType"] == "NxEffect" then
            return NxEffects::requiredTimeInSeconds(item)
        end
        10*60 # 10 mins
    end

    # Performance::itemsPrediction(items)
    def self.itemsPrediction(items)
        items.reduce(0){|total, item| total + Performance::itemPrediction(item) }
    end

    # Performance::updateDataFileOrNull(items)
    def self.updateDataFileOrNull(items)
        return nil if Time.new.hour >= 22
        return nil if Time.new.hour < 8
        data = Performance::getDataForTodayOrNull()
        performance = Performance::itemsPrediction(items)
        return nil if data.nil?
        if data["initial-prediction"].nil? then
            data["initial-prediction"] = performance
        end
        if data["time-of-initial-prediction"].nil? then
            data["time-of-initial-prediction"] = Time.new.to_i
        end
        if data["timespan-initial-prediction-to-10pm"].nil? then
            data["timespan-initial-prediction-to-10pm"] = CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()) - 3600*2 - data["time-of-initial-prediction"]
        end
        data["timespan-since-initial-prediction"] = Time.new.to_i - data["time-of-initial-prediction"]
        data["current-prediction"] = performance
        data["done"] = data["initial-prediction"] - data["current-prediction"]
        data["ideal-done-at-this-time"] = (data["timespan-since-initial-prediction"] * data["initial-prediction"]).to_f/data["timespan-initial-prediction-to-10pm"]
        Performance::commitDataToDisk(data)
        return nil if data["ideal-done-at-this-time"] == 0
        data["performance"] = 100*data["done"].to_f/data["ideal-done-at-this-time"]
        Performance::commitDataToDisk(data)
        data
    end

    # Performance::updateDataFileAndGetPerformamce(items)
    def self.updateDataFileAndGetPerformamce(items)
        data = Performance::updateDataFileOrNull(items)
        return -1 if data.nil?
        data["performance"]
    end
end