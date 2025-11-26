
# encoding: UTF-8

class PolyActions

    # function names in alphabetical order

    # PolyActions::start(item)
    def self.start(item)
        if item["mikuType"] == "NxOndate" and item["donation-08"].nil? then
            Donations::interactivelyAttachDonationOrNothing(item)
        end
        puts "start: '#{PolyFunctions::toString(item).green}'"
        NxBalls::start(item)
    end

    # PolyActions::access(item)
    def self.access(item)
        UxPayloads::access(UxPayloads::itemToPayloadOrNull(item))
    end

    # PolyActions::stop(item)
    def self.stop(item)
        if item["mikuType"] == "NxPolymorph" then
            item = NxPolymorphs::stop(item)
        end
        NxBalls::stop(item)
        ListingPosition::delistItemAndSimilar(item)
    end

    # PolyActions::done(item)
    def self.done(item)

        payload = UxPayloads::itemToPayloadOrNull(item)

        if payload and payload["type"] == "breakdown" and payload["lines"].size > 0 then
            line = payload["lines"].first
            puts "done: #{line}"
            payload["lines"] = payload["lines"].drop(1)
            if payload["lines"].size > 0 then
                Items::commitObject(payload)
            else
                Items::setAttribute(item["uuid"], "payload-uuid-1141", nil)
            end
            return
        end

        if payload and payload["type"] == "sequence" then
            sequenceItem = Sequences::firstItemInSequenceOrNull(payload["sequenceuuid"])
            puts JSON.pretty_generate(sequenceItem)
            PolyActions::done(sequenceItem)
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

        if item["mikuType"] == "NxPriority" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green} ? '") then
                Items::deleteObject(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxSequenceItem" then
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

        if item["mikuType"] == "NxPolymorph" then
            NxPolymorphs::done(item)
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

        if item["mikuType"] == "NxProject" then
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

        PolyActions::stop(item)

        if item["mikuType"] == "NxPolymorph" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
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

        if item["mikuType"] == "NxTask" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::deleteObject(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxProject" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::deleteObject(item["uuid"])
                NxProjects::alignLx56()
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
