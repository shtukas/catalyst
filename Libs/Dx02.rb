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
            "periodInHours" => 0.45
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
            if topItem.nil? then
                return "(Could not identify a top item for: generatoruuid: #{payload["generatoruuid"]})"
            else
                return PolyFunctions::toString(topItem)
            end
        end
        raise "(error: 7E3C3122-8B47-4FAE-9BC6-A65208EC5E15) item: #{item}"
    end

    # Dx02s::positioningToString(positioning)
    def self.positioningToString(positioning)
        if positioning["type"] == "appointment" then
            return "#{positioning["startTime"]} to #{positioning["endTime"]}         "
        end
        if positioning["type"] == "fluid" then
            return "               (#{"%6.2f" % positioning["ordinal"]})"
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

    # ------------------------
    # Ops

    # Dx02s::done(dx02)
    def self.done(dx02)
        if payload["type"] == "item" then
            item = payload["item"]
            item = Solingen::getItemOrNull(item["uuid"])
            if item then
                PolyActions::done(item)
            end
        end
        if payload["type"] == "topItem" then
            topItem = PolyFunctions::topItemOfCollectionOrNull(payload["generatoruuid"])
            if topItem then
                PolyActions::done(topItem)
            end
        end
        Dx02s::destroy(dx02["uuid"])
    end

    # Dx02s::access(dx02)
    def self.access(dx02)
        if payload["type"] == "item" then
            item = payload["item"]
            item = Solingen::getItemOrNull(item["uuid"])
            if item.nil? then
                puts "Looks like item: #{PolyFunctions::toString(item)} has disappeared"
                puts "I am going to destroy the Dx02"
                LucilleCore::pressEnterToContinue()
                Dx02s::stop(dx02)
                Dx02s::destroy(dx02["uuid"])
                return
            else
                PolyActions::access(item)
            end
        end
        if payload["type"] == "topItem" then
            topItem = PolyFunctions::topItemOfCollectionOrNull(payload["generatoruuid"])
            if topItem.nil? then
                puts "(Could not identify a top item for: generatoruuid: #{payload["generatoruuid"]})"
                LucilleCore::pressEnterToContinue()
                return
            else
                PolyActions::access(topItem)
            end
        end
        raise "(error: 91f59fb6-e014-4ffe-9994-fe4098e6f5af) item: #{item}"
    end

    # Dx02s::dataManagement()
    def self.dataManagement()
        # Looking for gap between two consecutive "topItem"s
        dx02s = Dx02s::listingItems()
        loop {
            break if dx02s.size < 2
            d1, d2 = dx02s
            if d1["payload"]["type"] == "topItem" and d2["payload"]["type"] == "topItem" and d1["positioning"]["type"] == "fluid" and d2["positioning"]["type"] == "fluid" then
                ordinal = 0.5*(d1["positioning"]["ordinal"]+d2["positioning"]["ordinal"])
                item = Listing::firstDx02RelocatableItem()
                puts JSON.pretty_generate(item)
                dx02 = Dx02s::issueDx02(Dx02s::itemToDx04(item), Dx02s::ordinalToDx03Fluid(ordinal))
                puts JSON.pretty_generate(dx02)
                return
            end
            dx02s.shift
        }
    end
end
