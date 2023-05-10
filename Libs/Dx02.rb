# encoding: UTF-8

class Dx02s

    # ------------------------
    # IO

    # Dx02s::storeFolderpath()
    def self.storeFolderpath()
        "#{Config::pathToCatalystData()}/Dx02s"
    end

    # Dx02s::items()
    def self.items()
        LucilleCore::locationsAtFolder(Dx02s::storeFolderpath())
            .select{|location| File.basename(location).start_with?("Dx02-") }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # ------------------------
    # Makers

    # Dx02s::userInputToDx03(str)
    def self.userInputToDx03(str)
        # "HH:MM HH:MM (appointment); <ordinal:float> (fluid)"
        if str.include?(':') then
            startTime, endTime = str.split(" ")
            {
               "type"      => "appointment",
               "startTime" => startTime,
               "endTime"   => endTime
            }
        else
            ordinal = str.to_f
            {
               "type"    => "fluid",
               "ordinal" => ordinal
            }
        end
    end

    # Dx02s::itemToDx04(item)
    def self.itemToDx04(item)
        {
            "type" => "item",
            "item" => item
        }
    end

    # Dx02s::issueDx02(item, positioning, payload)
    def self.issueDx02(item, positioning, payload)
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Dx02",
            "positioning" => positioning,
            "payload"     => payload
        }
        filepath = "#{Dx02s::storeFolderpath()}/Dx02-#{SecureRandom.uuid}"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
        item
    end

    # ------------------------
    # Data

    # Dx02s::positioningToString(positioning)
    def self.positioningToString(positioning)
        if positioning["type"] == "appointment" then
            return "#{positioning["startTime"]} to #{positioning["endTime"]}"
        end
        if positioning["type"] == "fluid" then
            return "#{positioning["ordinal"]}"
        end
        raise "(error: 521cebb2-5e28-44e1-8f5a-5fd5d078350d)"
    end

    # Dx02s::toString(item)
    def self.toString(item)
        "(#{"Dx02".green}) #{Dx02s::positioningToString(item["positioning"])}"
    end

    # Dx02s::listingItems()
    def self.listingItems()
        Dx02s::items()
    end
end
