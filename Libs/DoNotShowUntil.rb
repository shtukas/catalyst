
class DoNotShowUntil1

    # DoNotShowUntil1::instanceFilepath()
    def self.instanceFilepath()
        filepath = "#{Config::pathToCatalystDataRepository()}/DoNotShowUntil/DoNotShowUntil-#{Config::thisInstanceId()}.sqlite3"
        if !File.exist?(filepath) then
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("create table DoNotShowUntil (_id_ string primary key, _unixtime_ float)")
            db.close
        end
        filepath
    end

    # DoNotShowUntil1::record_filepaths()
    def self.record_filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToCatalystDataRepository()}/DoNotShowUntil")
            .select{|location| location[-7, 7] == ".record" }
    end

    # DoNotShowUntil1::maintenance()
    def self.maintenance()
        LucilleCore::locationsAtFolder("#{Config::pathToCatalystDataRepository()}/DoNotShowUntil")
            .select{|location| location[-7, 7] == ".record" }
            .each{|filepath|
                record = JSON.parse(IO.read(filepath))
                if record["unixtime"] < Time.new.to_i or Cubes2::itemOrNull(record["id"]).nil? then
                    FileUtils.rm(filepath)
                end
            }
    end

    # DoNotShowUntil1::getUnixtimeOrNull(id)
    def self.getUnixtimeOrNull(id)
        # not implemented
    end

    # DoNotShowUntil1::setUnixtime(id, unixtime)
    def self.setUnixtime(id, unixtime)
        item = Cubes1::itemOrNull(id)
        if item then
            Ox1::detach(item)
        end

        record = {
            "id" => id,
            "unixtime" => unixtime
        }
        filename = "#{CommonUtils::timeStringL22()}.record"
        filepath = "#{Config::pathToCatalystDataRepository()}/DoNotShowUntil/#{filename}"
        File.open(filepath, "w"){|f| f.puts(JSON.generate(record)) }

        XCache::set("747a75ad-05e7-4209-a876-9fe8a86c40dd:#{id}", unixtime)
        puts "do not display '#{id}' until #{Time.at(unixtime).utc.iso8601}".yellow
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
