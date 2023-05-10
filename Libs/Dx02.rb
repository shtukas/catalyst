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

    # Dx02s::destroy(uuid)
    def self.destroy(uuid)
        LucilleCore::locationsAtFolder(Dx02s::storeFolderpath())
            .select{|location| File.basename(location).start_with?("Dx02-") }
            .each{|filepath|
                item = JSON.parse(IO.read(filepath))
                if item["uuid"] == uuid then
                    FileUtils.rm(filepath)
                end
            }
    end

    # ------------------------
    # Makers

    # Dx02s::itemToDx04(item)
    def self.itemToDx04(item)
        {
            "type" => "item",
            "item" => item
        }
    end

    # Dx02s::generatorToDx04(generator) # board or NxMonitor1
    def self.generatorToDx04(generator)
        {
            "type"          => "topItem",
            "generatoruuid" => generator["uuid"],
            "periodInHours" => 1
        }
    end

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

    # Dx02s::ordinalToDx03Fluid(ordinal)
    def self.ordinalToDx03Fluid(ordinal)
        {
           "type"    => "fluid",
           "ordinal" => ordinal
        }
    end

    # Dx02s::issueDx02(payload, positioning)
    def self.issueDx02(payload, positioning)
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "Dx02",
            "payload"     => payload,
            "positioning" => positioning,
        }
        filepath = "#{Dx02s::storeFolderpath()}/Dx02-#{SecureRandom.uuid}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
        item
    end

    # ------------------------
    # Data

    # Dx02s::payloadToString(payload)
    def self.payloadToString(payload)
        if payload["type"] == "item" then
            item = payload["item"]
            return PolyFunctions::toString(item)
        end
        if payload["type"] == "topItem" then
            topItem = PolyFunctions::topItemOfCollectionOrNull(payload["generatoruuid"])
            return PolyFunctions::toString(topItem)
        end
        raise "(error: 7E3C3122-8B47-4FAE-9BC6-A65208EC5E15) item: #{item}"
    end

    # Dx02s::positioningToString(positioning)
    def self.positioningToString(positioning)
        if positioning["type"] == "appointment" then
            return "(#{positioning["startTime"]} to #{positioning["endTime"]})         "
        end
        if positioning["type"] == "fluid" then
            return "                 (#{"%6.2f" % positioning["ordinal"]})"
        end
        raise "(error: 521cebb2-5e28-44e1-8f5a-5fd5d078350d)"
    end

    # Dx02s::toString(item)
    def self.toString(item)
        "(#{"Dx02".green}) #{Dx02s::positioningToString(item["positioning"])} #{Dx02s::payloadToString(item["payload"])}"
    end

    # Dx02s::listingItems()
    def self.listingItems()

        lis1 = Dx02s::items()
                    .select{|item| item["positioning"]["type"] == "appointment" }
                    .sort_by{|item| item["positioning"]["startTime"] }

        lis2 = Dx02s::items()
                    .select{|item| item["positioning"]["type"] == "fluid" }
                    .sort_by{|item| item["positioning"]["ordinal"] }

        lis2.take(1) + lis1 + lis2.drop(1)

    end
end
