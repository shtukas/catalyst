# encoding: UTF-8

class Dx02s

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

    # Dx02s::stringToDx03(str)
    def self.stringToDx03(str)
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

    # Dx02s::issueDx02(item, directive)
    def self.issueDx02(item, directive)
        item = {
            "uuid"      => SecureRandom.uuid,
            "mikuType"  => "Dx02",
            "itemuuid"  => item["uuid"],
            "directive" => directive
        }
        filepath = "#{Dx02s::storeFolderpath()}/Dx02-#{SecureRandom.uuid}"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
        item
    end

    # Dx02s::listingItems()
    def self.listingItems()
        Dx02s::items()
    end

    # Dx02s::directiveToString(directive)
    def self.directiveToString(directive)
        if directive["type"] == "appointment" then
            return "#{directive["startTime"]} to #{directive["endTime"]}"
        end
        if directive["type"] == "fluid" then
            return "#{directive["ordinal"]}"
        end
        raise "(error: 521cebb2-5e28-44e1-8f5a-5fd5d078350d)"
    end

    # Dx02s::toString(item)
    def self.toString(item)
        "(#{"Dx02".green}) #{Dx02s::directiveToString(item["directive"])}"
    end
end
