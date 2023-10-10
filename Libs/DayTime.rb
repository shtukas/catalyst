

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
        Time.at( Time.new.to_i + DayTime::cummulatedDayTimeLeft()*3600 + DayTime::getTodayUnproductiveHours()*3600 ).to_s
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

    # DayTime::issueUnproductive()
    def self.issueUnproductive()
        hours = LucilleCore::askQuestionAnswerAsString("unproductive in hours: ").to_f
        item = {
            "uuid"     => "511ebde8-5d25-48b0-a84f-444f216581ee",
            "mikuType" => "DayTimeUnproductive",
            "date"     => CommonUtils::today(),
            "hours"    => hours
        }
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/Items.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from Items where _uuid_=?", [item["uuid"]]
        db.execute "insert into Items (_uuid_, _mikuType_, _item_) values (?, ?, ?)", [item["uuid"], item["mikuType"], JSON.generate(item)]
        db.close
    end

    # DayTime::getTodayUnproductiveHours()
    def self.getTodayUnproductiveHours()
        unproductive = Catalyst::itemOrNull("511ebde8-5d25-48b0-a84f-444f216581ee")
        return 0 if unproductive.nil?
        return 0 if unproductive["date"] != CommonUtils::today()
        unproductive["hours"]
    end
end
