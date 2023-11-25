
class DoNotShowUntil

    # DoNotShowUntil::instanceFilepath()
    def self.instanceFilepath()
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/DoNotShowUntil/DoNotShowUntil-#{Config::thisInstanceId()}.sqlite3"
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

    # DoNotShowUntil::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/DoNotShowUntil")
            .select{|location| location[-8, 8] == ".sqlite3" }
    end

    # DoNotShowUntil::getUnixtimeOrNull(id)
    def self.getUnixtimeOrNull(id)
        unixtime1 = XCache::getOrDefaultValue("747a75ad-05e7-4209-a876-9fe8a86c40dd:#{id}", "0").to_f

        unixtime2 = DoNotShowUntil::filepaths()
                        .map{|filepath|
                            unixtime = 0
                            db = SQLite3::Database.new(filepath)
                            db.busy_timeout = 117
                            db.busy_handler { |count| true }
                            db.results_as_hash = true
                            db.execute("select * from DoNotShowUntil where _id_=?", [id]) do |row|
                                unixtime = row["_unixtime_"]
                            end
                            db.close
                            unixtime
                        }
                        .max

        unixtime = [unixtime1, unixtime2].max
        return nil if unixtime == 0
        unixtime
    end

    # DoNotShowUntil::setUnixtime(id, unixtime)
    def self.setUnixtime(id, unixtime)
        item = Cubes::itemOrNull(id)
        if item then
            Ox1::detach(item)
        end

        filepath = DoNotShowUntil::instanceFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from DoNotShowUntil where _id_=?", [id]
        db.execute "insert into DoNotShowUntil (_id_, _unixtime_) values (?, ?)", [id, unixtime]
        db.close

        XCache::set("747a75ad-05e7-4209-a876-9fe8a86c40dd:#{id}", unixtime)
        puts "do not display '#{id}' until #{Time.at(unixtime).utc.iso8601}".yellow
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
