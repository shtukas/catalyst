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

    # Dx02s::commit(item)
    def self.commit(item)
        LucilleCore::locationsAtFolder(Dx02s::storeFolderpath())
            .select{|location| File.basename(location).start_with?("Dx02-") }
            .each{|filepath|
                i = JSON.parse(IO.read(filepath))
                if i["uuid"] == item["uuid"] then
                    FileUtils.rm(filepath)
                end
            }
        filepath = "#{Dx02s::storeFolderpath()}/Dx02-#{SecureRandom.hex}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
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
        if str.include?(':') and str.include?(' ') then
            startTime, endTime = str.split(' ')
            return {
               "type"      => "appointment",
               "startTime" => startTime,
               "endTime"   => endTime
            }
        end

        if str.include?(':') then
            startTime, endTime = str.split(" ")
            return {
               "type"      => "appointment",
               "startTime" => startTime,
               "endTime"   => nil
            }
        end

        {
           "type" => "fluid"
        }
    end

    # Dx02s::dx03Fluid()
    def self.dx03Fluid()
        {
           "type" => "fluid"
        }
    end

    # Dx02s::issueDx02(payload, style, position = nil)
    def self.issueDx02(payload, style, position = nil)
        item = {
            "uuid"      => SecureRandom.uuid,
            "mikuType"  => "Dx02",
            "payload"   => payload,
            "style"     => style,
            "position"  => position || Dx02s::nextPosition()
        }
        Dx02s::commit(item)
    end

    # ------------------------
    # Data

    # Dx02s::nextPosition()
    def self.nextPosition()
        items = Dx02s::items()
        return 1 if items.empty?
        items.map{|item| item["position"] }.max + 1
    end

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

    # Dx02s::styleToString(item)
    def self.styleToString(item)
        style = item["style"]
        if style["type"] == "appointment" and style["endTime"] then
            return "#{style["startTime"]} to #{style["endTime"]}"
        end
        if style["type"] == "appointment" and style["endTime"].nil? then
            return "#{style["startTime"]}                  "
        end
        if style["type"] == "fluid" then
            return "              "
        end
        raise "(error: 521cebb2-5e28-44e1-8f5a-5fd5d078350d)"
    end

    # Dx02s::toString(item)
    def self.toString(item)
        "(#{"%5.2f" % item["position"]}) #{Dx02s::styleToString(item)} #{Dx02s::payloadToString(item["payload"])}"
    end

    # Dx02s::listingItems()
    def self.listingItems()
        Dx02s::items().sort_by{|item| item["position"] }
    end

    # ------------------------
    # Ops

    # Dx02s::done(dx02)
    def self.done(dx02)
        NxBalls::stop(dx02)
        both = LucilleCore::askQuestionAnswerAsBoolean("Both Dx20 and payload done ? ")
        if both then
            payload = dx02["payload"]
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
        end
        Dx02s::destroy(dx02["uuid"])
    end

    # Dx02s::access(dx02)
    def self.access(dx02)
        payload = dx02["payload"]
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
            if d1["payload"]["type"] == "topItem" and d2["payload"]["type"] == "topItem" and d1["style"]["type"] == "fluid" and d2["style"]["type"] == "fluid" then
                position = 0.5*(d1["position"]+d2["position"])
                item = Listing::firstDx02RelocatableItem()
                puts JSON.pretty_generate(item)
                dx02 = Dx02s::issueDx02(Dx02s::itemToDx04(item), Dx02s::dx03Fluid(), position)
                puts JSON.pretty_generate(dx02)
                return
            end
            dx02s.shift
        }
    end
end
