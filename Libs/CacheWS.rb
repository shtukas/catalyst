# encoding: UTF-8

$CacheWS_AD64B8EA = {}
$CacheWS_PrimaryKey = "0EF7E9F4-CA6D-4710-8C3D-BB86CC4F5146"
$CacheWS_useCache = true

class CacheWS

    # -- private ---------------------------------------

    # CacheWS::registration(signal, key)
    def self.registration(signal, key)
        filepath = XCache::filepath("6347a51a-14ca-4406-95d0-945354ca98e6:#{signal}")
        if !File.exist?(filepath) then
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("create table _mapping_ (_signal_ string, _key_ string);")
            db.close
        end

        flag = false
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from _mapping_ where _signal_=? and _key_=?", [signal, key]) do |row|
            flag = true
        end
        db.close
        return if flag

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into _mapping_ (_signal_, _key_) values (?, ?)", [signal, key]
        db.close
    end

    # CacheWS::getKeysForSignal(signal)
    def self.getKeysForSignal(signal)
        filepath = XCache::filepath("6347a51a-14ca-4406-95d0-945354ca98e6:#{signal}")
        return [] if !File.exist?(filepath)
        keys = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from _mapping_ where _signal_=?", [signal]) do |row|
            keys << row["_key_"]
        end
        db.close
        keys
    end

    # -- public ---------------------------------------

    # This signature is to be read as:
    # We are storing this value against this key, but the value should be decached if one of those signals are issued
    # Note: we are ensuring this by having a one to many mapping from signals to keys
    # Additionaly values automatically decache after 24 hours

    # CacheWS::set(key, value, signals)
    def self.set(key, value, signals)
        return if !$CacheWS_useCache
        XCache::set("#{$CacheWS_PrimaryKey}:#{key}", JSON.generate(value))
        $CacheWS_AD64B8EA[key] = value
        signals.each{|signal|
            #puts "signal: #{signal}"
            CacheWS::registration(signal, key)
        }
    end

    # CacheWS::getOrNull(key)
    def self.getOrNull(key)
        return nil if !$CacheWS_useCache

        value = $CacheWS_AD64B8EA[key]
        return value if value

        value = XCache::getOrNull("#{$CacheWS_PrimaryKey}:#{key}")
        return nil if value.nil?
        value = JSON.parse(value)

        $CacheWS_AD64B8EA[key] = value

        value
    end

    # CacheWS::emit(signal)
    def self.emit(signal)
        return if !$CacheWS_useCache
        CacheWS::getKeysForSignal(signal).each{|key|
            XCache::destroy("#{$CacheWS_PrimaryKey}:#{key}")
            $CacheWS_AD64B8EA[key] = nil
        }
    end
end
