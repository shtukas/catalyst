
class YCache

    # YCache::repository()
    def self.repository()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/Catalyst/data/YCache"
    end

    # YCache::set(key, value)
    def self.set(key, value)
        hash1 = Digest::SHA1.hexdigest(key)
        LucilleCore::locationsAtFolder(YCache::repository())
            .select{|filepath| File.basename(filepath).start_with?(hash1) }
            .each{|filepath|
                FileUtils.rm(filepath)
            }
        hash1 = Digest::SHA1.hexdigest(key)
        hash2 = Digest::SHA1.hexdigest(JSON.generate(value))
        filepath = "#{YCache::repository()}/#{hash1}-#{hash2}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(value)) }
    end

    # YCache::getOrNull(key)
    def self.getOrNull(key)
        hash1 = Digest::SHA1.hexdigest(key)
        filepaths = LucilleCore::locationsAtFolder(YCache::repository())
                        .select{|filepath| File.basename(filepath).start_with?(hash1) }
        return nil if filepaths.empty?
        data = JSON.parse(IO.read(filepaths.first))
        filepaths.drop(1).each{|filepath|
            FileUtils.rm(filepath)
        }
        data
    end

    # YCache::getOrDefaultValue(key, defaultValue)
    def self.getOrDefaultValue(key, defaultValue)
        value = YCache::getOrNull(key)
        return value if value
        defaultValue
    end

    # YCache::trueNoMoreOftenThanNSeconds(key, timeSpanInSeconds)
    def self.trueNoMoreOftenThanNSeconds(key, timeSpanInSeconds)
        unixtime = YCache::getOrDefaultValue(key, 0)
        (Time.new.to_i - unixtime) > timeSpanInSeconds
    end
end
