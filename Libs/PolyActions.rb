
# encoding: UTF-8

class PolyActions

    # function names in alphabetical order

    # PolyActions::start(item)
    def self.start(item)
        puts "start: '#{PolyFunctions::toString(item).green}'"
        NxBalls::start(item)
    end

    # PolyActions::access(item)
    def self.access(item)
        UxPayload::access(item["uuid"], item["uxpayload-b4e4"])
    end

    # PolyActions::stop(item)
    def self.stop(item)
        NxBalls::stop(item)
    end

    # PolyActions::done(item)
    def self.done(item)

        if item["uxpayload-b4e4"] and item["uxpayload-b4e4"]["type"] == "breakdown" and item["uxpayload-b4e4"]["lines"].size > 0 then
            line = item["uxpayload-b4e4"]["lines"].first
            puts "done: #{line}"
            item["uxpayload-b4e4"]["lines"] = item["uxpayload-b4e4"]["lines"].drop(1)
            if item["uxpayload-b4e4"]["lines"].size > 0 then
                Items::setAttribute(item["uuid"], "uxpayload-b4e4", item["uxpayload-b4e4"])
            else
                Items::setAttribute(item["uuid"], "uxpayload-b4e4", nil)
            end
            return
        end

        PolyActions::stop(item)

        if item["mikuType"] == "DesktopTx1" then
            Desktop::done()
            return
        end

        if item["mikuType"] == "DropBox" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green} ? '") then
                DropBox::done(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxDeleted" then
            Items::deleteItem(item["uuid"])
            return
        end

        if item["mikuType"] == "NxPolymorph" then
            if item["behaviours"].first["btype"] == "listing-position" and item["behaviours"].size >= 2 then
                item["behaviours"] = item["behaviours"].drop(1)
            end
            behaviours = TxBehaviour::doneArrayOfBehaviours(item["behaviours"])
            if behaviours.empty? then
                if LucilleCore::askQuestionAnswerAsBoolean("confirm destroy '#{PolyFunctions::toString(item).green}': ") then
                    Items::deleteItem(item["uuid"])
                end
            else
                Items::setAttribute(item["uuid"], "behaviours", behaviours)
            end
            return
        end

        puts "I do not know how to PolyActions::done(#{JSON.pretty_generate(item)})"
        raise "(error: f278f3e4-3f49-4f79-89d2-e5d3b8f728e6)"
    end

    # PolyActions::doubleDots(item)
    def self.doubleDots(item)
        if NxBalls::itemIsPaused(item) then
            NxBalls::pursue(item)
            return
        end

        if NxBalls::itemIsRunning(item) then
            return
        end

        PolyActions::start(item)
        PolyActions::access(item)
    end

    # PolyActions::tripleDots(item)
    def self.tripleDots(item)

        return if NxBalls::itemIsActive(item)

        if item["mikuType"] == "NxPolymorph" then
            PolyActions::start(item)
            PolyActions::access(item)
            LucilleCore::pressEnterToContinue("Press [enter] to done: ")
            PolyActions::done(item)
            return
        end

        puts "I do not know how to PolyActions::tripleDots(#{JSON.pretty_generate(item)})"
        raise "(error: ba36812e-bd85-4c1a-9a10-e1d650a239a5)"
    end

    # PolyActions::destroy(item)
    def self.destroy(item)

        NxBalls::stop(item)

        if item["mikuType"] == "NxPolymorph" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::deleteItem(item["uuid"])
                
            end
            return
        end

        puts "I do not know how to PolyActions::destroy(#{JSON.pretty_generate(item)})"
        raise "(error: f7ac071e-f2bb-4921-a7f3-22f268b25be8)"
    end

    # PolyActions::pursue(item)
    def self.pursue(item)
        NxBalls::pursue(item)
    end

    # PolyActions::addTimeToItem(item, timeInSeconds)
    def self.addTimeToItem(item, timeInSeconds)
        PolyFunctions::itemToBankingAccounts(item).each{|account|
            puts "Adding #{timeInSeconds} seconds to account: #{account["description"]}"
            Bank::insertValue(account["number"], CommonUtils::today(), timeInSeconds)
        }
    end

    # PolyActions::editDescription(item)
    def self.editDescription(item)
        puts "edit description:"
        description = CommonUtils::editTextSynchronously(item["description"]).strip
        return if description == ""
        Items::setAttribute(item["uuid"], "description", description)
    end
end
