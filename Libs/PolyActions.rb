
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
        UxPayloads::access(UxPayloads::itemToPayloadOrNull(item))
    end

    # PolyActions::stop(item)
    def self.stop(item)
        NxBalls::stop(item)
        ListingPosition::delistItemAndSimilar(item)
    end

    # PolyActions::done(item)
    def self.done(item)

        payload = UxPayloads::itemToPayloadOrNull(item)
        sublines = NxSublines::itemsForParentInOrder(item["uuid"])

        if sublines.size > 0 then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option",["default item done (default)", "destroy first subline"])
            if option == "destroy first subline" then
                PolyActions::destroy(sublines.first)
                return
            end
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

        if item["mikuType"] == "Infinity" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green} ? '") then
                DropBox::done(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxOndate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green} ? '") then
                Items::deleteObject(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxPriority" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green} ? '") then
                Items::deleteObject(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxDeleted" then
            Items::deleteObject(item["uuid"])
            return
        end

        if item["mikuType"] == "Wave" then
            Waves::performDone(item)
            return
        end

        if item["mikuType"] == "NxHappening" then
            DoNotShowUntil::doNotShowUntil(item, CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone())
            return
        end

        if item["mikuType"] == "Anniversary" then
            next_celebration = Anniversary::computeNextCelebrationDate(item["startdate"], item["repeatType"])
            Items::setAttribute(item["uuid"], "next_celebration", next_celebration)
            DoNotShowUntil::doNotShowUntil(item, Date.parse(next_celebration).to_time.to_i)
            return
        end

        if item["mikuType"] == "NxTask" then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option",["done for the day (default)", "destroy"])
            return if option.nil?
            if option == "done for the day (default)" then
                DoNotShowUntil::doNotShowUntil(item, CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone())
            end
            if option == "destroy" then
                PolyActions::destroy(item)
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

        PolyActions::start(item)
        PolyActions::access(item)
        LucilleCore::pressEnterToContinue("Press [enter] to done: ")
        PolyActions::done(item)
    end

    # PolyActions::destroy(item)
    def self.destroy(item)

        if NxSublines::itemsForParentInOrder(item["uuid"]).size > 0 then
            puts "You cannot destroy an items which has active sublines"
            LucilleCore::pressEnterToContinue()
            return
        end

        NxBalls::stop(item)

        if item["mikuType"] == "NxHappening" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::deleteObject(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxInfinity" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green} ? '") then
                Items::deleteObject(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxOndate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green} ? '") then
                Items::deleteObject(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxPriority" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::deleteObject(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "Anniversary" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::deleteObject(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "Wave" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::deleteObject(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxSubline" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::deleteObject(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::deleteObject(item["uuid"])
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
        ListingPosition::delistItemAndSimilar(item)
    end

    # PolyActions::editDescription(item)
    def self.editDescription(item)
        puts "edit description:"
        description = CommonUtils::editTextSynchronously(item["description"]).strip
        return if description == ""
        Items::setAttribute(item["uuid"], "description", description)
    end
end
