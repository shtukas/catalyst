
class DoNotShowUntil1

    # ----------------------------------
    # Core

    # DoNotShowUntil1::setUnixtimeToDatabase(id, unixtime)
    def self.setUnixtimeToDatabase(id, unixtime)
        db = SQLite3::Database.new("#{Config::pathToCatalystDataRepository()}/DoNotShowUntil/20240607-182821-455389.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("delete from DoNotShowUntil where _id_=?", [id])
        db.execute("insert into DoNotShowUntil (_id_, _unixtime_) values (?, ?)", [id, unixtime])
        db.close
    end

    # DoNotShowUntil1::processJournal()
    def self.processJournal()
        LucilleCore::locationsAtFolder("#{Config::pathToCatalystDataRepository()}/DoNotShowUntil")
            .select{|location| location[-5, 5] == ".json" }
            .map{|filepath| 
                record = JSON.parse(IO.read(filepath))
                DoNotShowUntil1::setUnixtimeToDatabase(record["id"], record["unixtime"])
                FileUtils.rm(filepath)
            }
    end

    # ----------------------------------
    # Interface

    # DoNotShowUntil1::getUnixtimeOrNull(id)
    def self.getUnixtimeOrNull(id)
        unixtime = nil
        db = SQLite3::Database.new("#{Config::pathToCatalystDataRepository()}/DoNotShowUntil/20240607-182821-455389.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from DoNotShowUntil where _id_=?", [id]) do |row|
            unixtime = row["_unixtime_"]
        end
        db.close

        LucilleCore::locationsAtFolder("#{Config::pathToCatalystDataRepository()}/DoNotShowUntil")
            .select{|location| location[-5, 5] == ".json" }
            .each{|filepath|
                record = JSON.parse(IO.read(filepath))
                if record["id"] == id then
                    unixtime = [unixtime, record["unixtime"]].compact.max
                end
            }

        unixtime = [unixtime, XCache::getOrDefaultValue("747a75ad-05e7-4209-a876-9fe8a86c40dd:#{id}", "0").to_f].compact.max

        unixtime
    end

    # DoNotShowUntil1::setUnixtime(id, unixtime)
    def self.setUnixtime(id, unixtime)
        puts "do not display '#{id}' until #{Time.at(unixtime).utc.iso8601}".yellow

        update = {
            "id"       => id,
            "unixtime" => unixtime
        }
        filepath = "#{Config::pathToCatalystDataRepository()}/DoNotShowUntil/#{CommonUtils::timeStringL22()}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(update)) }

        XCache::set("747a75ad-05e7-4209-a876-9fe8a86c40dd:#{id}", unixtime)
    end

    # DoNotShowUntil1::isVisible(item)
    def self.isVisible(item)
        Time.new.to_i >= (DoNotShowUntil1::getUnixtimeOrNull(item["uuid"]) || 0)
    end

    # DoNotShowUntil1::suffixString(item)
    def self.suffixString(item)
        unixtime = (DoNotShowUntil1::getUnixtimeOrNull(item["uuid"]) || 0)
        return "" if unixtime.nil?
        return "" if Time.new.to_i > unixtime
        " (not shown until: #{Time.at(unixtime).to_s})"
    end
end
