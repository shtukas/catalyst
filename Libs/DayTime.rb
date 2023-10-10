

class DayTime

    # DayTime::issue(item)
    def self.issue(item)
        hours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
        data = {
            "date"  => CommonUtils::today(),
            "hours" => hours
        }
        Broadcasts::publishItemAttributeUpdate(item["uuid"], "da-ti-ex-0726", data)
    end

    # DayTime::dayTimeLeft(item)
    def self.dayTimeLeft(item)
        return 0 if item["da-ti-ex-0726"].nil?
        return 0 if item["da-ti-ex-0726"]["date"] != CommonUtils::today()
        left = item["da-ti-ex-0726"]["hours"] - Bank::getValueAtDate(item["uuid"], CommonUtils::today()).to_f/3600
        [left, 0].max
    end

    # DayTime::suffix(item)
    def self.suffix(item)
        left = DayTime::dayTimeLeft(item)
        return "" if left == 0
        " (day time left: #{left.round(2)})"
    end

    # DayTime::cummulatedDayTimeLeft()
    def self.cummulatedDayTimeLeft()
        Catalyst::catalystItems().reduce(0){|sum, item|
            sum + DayTime::dayTimeLeft(item)
        }
    end

    # DayTime::completionETA()
    def self.completionETA()
        Time.at( Time.new.to_i + DayTime::cummulatedDayTimeLeft()*3600 ).to_s
    end

    # DayTime::listingItems()
    def self.listingItems()
        Catalyst::catalystItems()
            .select{|item|
                (lambda{|item|
                    return false if item["da-ti-ex-0726"].nil?
                    return false if item["da-ti-ex-0726"]["date"] != CommonUtils::today()
                    true
                }).call(item)
            }
            .sort_by{|item| DayTime::dayTimeLeft(item) }
    end
end
