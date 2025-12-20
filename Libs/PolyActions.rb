
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
        UxPayloads::access(item["payload-37"])
    end

    # PolyActions::stop(item)
    def self.stop(item)
        NxBalls::stop(item)
        ListingPosition::delistNonOverridenItem(item)
    end

    # PolyActions::dismiss(item)
    def self.dismiss(item)

        PolyActions::stop(item)

        if item["mikuType"] == "NxTask" then
            if item["focus-24"].nil? then
                puts "You are stopping a #{item["mikuType"]} with no focus, setting one..."
                Focus24::interactivelyUpdateItemWithNewFocus(item)
            else
                Focus24::interactivelyUpdateFocus24AsPartOfDismissalOrNothing(item)
            end
            DoNotShowUntil::doNotShowUntil(item, CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone())
            return
        end

        puts "I do not know how to PolyActions::dismiss(#{JSON.pretty_generate(item)})"
        LucilleCore::pressEnterToContinue()
    end

    # PolyActions::done(item)
    def self.done(item)

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

        if item["mikuType"] == "NxOndate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green} ? '") then
                Items::deleteItem(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxDeleted" then
            Items::deleteItem(item["uuid"])
            return
        end

        if item["mikuType"] == "Wave" then
            Waves::performDone(item)
            return
        end

        if item["mikuType"] == "Anniversary" then
            next_celebration = Anniversary::computeNextCelebrationDate(item["startdate"], item["repeatType"])
            Items::setAttribute(item["uuid"], "next_celebration", next_celebration)
            DoNotShowUntil::doNotShowUntil(item, Date.parse(next_celebration).to_time.to_i)
            return
        end

        if item["mikuType"] == "NxTask" then
            puts "You cannot `done` a NxTask, you can either dismiss or destroy them"
            LucilleCore::pressEnterToContinue()
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

        PolyActions::start(item)
        PolyActions::access(item)
        LucilleCore::pressEnterToContinue("Press [enter] to done: ")
        PolyActions::done(item)
    end

    # PolyActions::destroy(item)
    def self.destroy(item)

        NxBalls::stop(item)

        if item["mikuType"] == "NxOndate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green} ? '", true) then
                Items::deleteItem(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "Anniversary" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::deleteItem(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "Wave" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::deleteItem(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
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
        ListingPosition::delistNonOverridenItem(item)
    end

    # PolyActions::editDescription(item)
    def self.editDescription(item)
        puts "edit description:"
        description = CommonUtils::editTextSynchronously(item["description"]).strip
        return if description == ""
        Items::setAttribute(item["uuid"], "description", description)
    end
end
