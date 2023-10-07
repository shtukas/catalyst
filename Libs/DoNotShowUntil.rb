
class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(id, unixtime)
    def self.setUnixtime(id, unixtime)
        Broadcasts::publishDoNotShowUntil(id, unixtime)
        XCache::set("747a75ad-05e7-4209-a876-9fe8a86c40dd:#{id}", unixtime)
        puts "do not display '#{id}' until #{Time.at(unixtime).utc.iso8601}"
    end

    # DoNotShowUntil::getUnixtimeOrNull(id)
    def self.getUnixtimeOrNull(id)
        unixtime = nil
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/DoNotShowUntil.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from DoNotShowUntil where _id_=?", [id]) do |row|
            unixtime = row["_unixtime_"]
        end
        db.close
        unixtime

        unixtime = XCache::getOrNull("747a75ad-05e7-4209-a876-9fe8a86c40dd:#{id}")
        return unixtime.to_i if unixtime
        nil
    end

    # DoNotShowUntil::isVisible(item)
    def self.isVisible(item)
        Time.new.to_i >= (DoNotShowUntil::getUnixtimeOrNull(item["uuid"]) || 0)
    end

    # DoNotShowUntil::suffixString(item)
    def self.suffixString(item)
        unixtime = (DoNotShowUntil::getUnixtimeOrNull(item["uuid"]) || 0)
        return "" if unixtime.nil?
        return "" if Time.new.to_i > unixtime
        " (not shown until: #{Time.at(unixtime).to_s})"
    end
end
