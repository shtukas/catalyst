
# encoding: UTF-8

class PolyActions

    # function names in alphabetical order

    # PolyActions::start(item)
    def self.start(item)
        if item["mikuType"] == "NxCounter" then
            return
        end

        if item["mikuType"] == "NxActive" and !item["donation-13"] and !item["no-donation-0D939389"] then
            puts "You are starting a NxActive that doesn't have a donation instruction and no directive to avoid one"
            item = Donations::interactivelySetDonation(item)
            if item["donation-13"].nil? then
                if LucilleCore::askQuestionAnswerAsBoolean("You did not set up a donation, do you want to avoid donations for this item ? ") then
                    Blades::setAttribute(item["uuid"], "no-donation-0D939389", true)
                    item = Blades::itemOrNull(item["uuid"])
                end
            end
        end

        puts "start: '#{PolyFunctions::toString(item).green}'"
        NxBalls::start(item)
    end

    # PolyActions::access(item)
    def self.access(item)
        if item["mikuType"] == "NxListing" then
            NxListings::diveListing(item)
            return
        end

        if item["mikuType"] == "NxCounter" then
            NxCounters::interactivelyIncrement(item)
            return
        end

        UxPayloads::access(item["uuid"], item["payload-37"])
    end

    # PolyActions::stop(item)
    def self.stop(item)
        timespan_in_second = NxBalls::stop(item)
        Dispatch::incoming(item, timespan_in_second)
    end

    # PolyActions::done(item)
    def self.done(item)

        PolyActions::stop(item)
        ListingPosition::nullifyNx42(item)

        if item["mikuType"] == "NxCounter" then
            return
        end

        if item["mikuType"] == "NxListing" then
            return
        end

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
            Blades::deleteItem(item["uuid"])
            return
        end

        if item["mikuType"] == "Wave" then
            Waves::performDone(item)
            return
        end

        if item["mikuType"] == "Anniversary" then
            next_celebration = Anniversary::computeNextCelebrationDate(item["startdate"], item["repeatType"])
            Blades::setAttribute(item["uuid"], "next_celebration", next_celebration)
            DoNotShowUntil::doNotShowUntil(item, Date.parse(next_celebration).to_time.to_i)
            return
        end

        if item["mikuType"] == "NxOndate" then
            puts "#{PolyFunctions::toString(item).green}"
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["dismiss", "destroy"])
            if option == "dismiss" then
                NxBalls::stop(item)
                DoNotShowUntil::doNotShowUntil(item, CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone())
            end
            if option == "destroy" then
                NxBalls::stop(item)
                PolyActions::destroy(item)
            end
            return
        end

        if item["mikuType"] == "NxActive" then
            puts "#{PolyFunctions::toString(item).green}"
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["dismiss", "destroy"])
            if option == "dismiss" then
                NxBalls::stop(item)
                DoNotShowUntil::doNotShowUntil(item, CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone())
            end
            if option == "destroy" then
                NxBalls::stop(item)
                PolyActions::destroy(item)
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            puts "#{PolyFunctions::toString(item).green}"
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["dismiss", "destroy"])
            if option == "dismiss" then
                NxBalls::stop(item)
                DoNotShowUntil::doNotShowUntil(item, CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone())
            end
            if option == "destroy" then
                NxBalls::stop(item)
                PolyActions::destroy(item)
            end
            return
        end

        if item["mikuType"] == "BufferIn" then
            return
        end

        if item["mikuType"] == "NxBackup" then
            puts "#{PolyFunctions::toString(item).green}"
            DoNotShowUntil::doNotShowUntil(item, Time.new.to_i + 86400 * item["period"])
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

        if item["mikuType"] == "NxListing" then
            puts "#{PolyFunctions::toString(item).green}"
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["start", "access"])
            if option == "start" then
                PolyActions::start(item)
            end
            if option == "access" then
                PolyActions::access(item)
            end
            return
        end

        PolyActions::start(item)
        PolyActions::access(item)
    end

    # PolyActions::tripleDots(item)
    def self.tripleDots(item)

        return if NxBalls::itemIsActive(item)

        if item["mikuType"] == "NxListing" then
            puts "We do not do triple dots for NxListings"
            LucilleCore::pressEnterToContinue()
            return
        end

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
                Blades::deleteItem(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxActive" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Blades::deleteItem(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "Anniversary" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Blades::deleteItem(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "Wave" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Blades::deleteItem(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxListing" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Blades::deleteItem(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxBackup" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Blades::deleteItem(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Blades::deleteItem(item["uuid"])
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
        Dispatch::incoming(item, timeInSeconds)
    end

    # PolyActions::editDescription(item) # item
    def self.editDescription(item)
        puts "edit description:"
        description = CommonUtils::editTextSynchronously(item["description"]).strip
        return item if description == ""
        Blades::setAttribute(item["uuid"], "description", description)
        Blades::itemOrNull(item["uuid"])
    end
end
