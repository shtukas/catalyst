
class Calendar

    # Calendar::pathToCalendarItems()
    def self.pathToCalendarItems()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Calendar/Items"
    end

    # Calendar::today()
    def self.today()
        Time.new.to_s[0, 10]
    end

    # Calendar::dates()
    def self.dates()
        Dir.entries(Calendar::pathToCalendarItems())
            .select{|filename| filename[-4, 4] == ".txt" }
            .sort
            .map{|filename| filename[0, 10] }
    end

    # Calendar::dateToFilepath(date)
    def self.dateToFilepath(date)
        "#{Calendar::pathToCalendarItems()}/#{date}.txt"
    end

    # Calendar::filePathToCatalystObject(date, indx)
    def self.filePathToCatalystObject(date, indx)
        filepath = Calendar::dateToFilepath(date)
        content = IO.read(filepath).strip
        uuid = "8413-9d175a593282-#{date}"
        {
            "uuid"            => uuid,
            "body"            => "🗓️  " + date + "\n" + content,
            "metric"          => KeyValueStore::flagIsTrue(nil, "63bbe86e-15ae-4c0f-93b9-fb1b66278b00:#{Time.new.to_s[0, 10]}:#{date}") ? 0 : 0.93 - indx.to_f/10000,
            "execute" => lambda { Calendar::execute(date) }
        }
    end

    # Calendar::catalystObjects()
    def self.catalystObjects()
        Calendar::dates()
            .each{|date|
                filepath = Calendar::dateToFilepath(date)
                content = IO.read(filepath).strip
                next if content.size > 0
                CatalystCommon::copyLocationToCatalystBin(filepath)
                FileUtils.rm(filepath)
            }

        Calendar::dates()
            .map
            .with_index{|date, indx| Calendar::filePathToCatalystObject(date, indx) }
    end

    # Calendar::execute(date)
    def self.execute(date)
        options = ["reviewed", "open"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        return option.nil?
        if option == "reviewed" then
            KeyValueStore::setFlagTrue(nil, "63bbe86e-15ae-4c0f-93b9-fb1b66278b00:#{Time.new.to_s[0, 10]}:#{date}")
        end
        if option == "open" then
            filepath = Calendar::dateToFilepath(date)
            system("open '#{filepath}'")
        end
    end

end


