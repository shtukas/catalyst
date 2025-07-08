
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

        if item["uxpayload-b4e4"] and PolyFunctions::hasChildren(item) then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull('access mode', ["access payload", "dive"])
            if option == "access payload" then
                # we continue here
            end
            if option == "dive" then
                Operations::diveItem(item)
                return
            end
        end

        if item["mikuType"] == "NxLambda" then
            NxLambdas::run(item)
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            return
        end

        if item["mikuType"] == "NxBackup" then
            return
        end

        if item["mikuType"] == "NxFloat" then
            return
        end

        if item["mikuType"] == "NxLine" then
            return
        end

        if item["mikuType"] == "NxCore" then
            if item["uxpayload-b4e4"] and !PolyFunctions::hasChildren(item) then
                UxPayload::access(item["uuid"], item["uxpayload-b4e4"])
                return
            end
            Operations::diveItem(item)
            return
        end

        if item["mikuType"] == "NxTask" then
            UxPayload::access(item["uuid"], item["uxpayload-b4e4"])
            return
        end

        if item["mikuType"] == "NxDated" then
            UxPayload::access(item["uuid"], item["uxpayload-b4e4"])
            return
        end

        if item["mikuType"] == "Wave" then
            UxPayload::access(item["uuid"], item["uxpayload-b4e4"])
            return
        end

        raise "(error: abb645e9-2575-458e-b505-f9c029f4ca69) I do not know how to access mikuType: #{item["mikuType"]}"
    end

    # PolyActions::stop(item)
    def self.stop(item)
        NxBalls::stop(item)
        Nx2133::itemHasStopped(item)
    end

    # PolyActions::done(item, useTheForce = false)
    def self.done(item, useTheForce = false)

        NxBalls::stop(item)

        if item["mikuType"] == "NxLambda" then
            return
        end

        if item["mikuType"] == "NxFloat" then
            NxBalls::stop(item)
            DoNotShowUntil::setUnixtime(item["uuid"], CommonUtils::unixtimeAtComingMidnightAtLocalTimezone() + 3600*6 + rand)
            return
        end

        if item["mikuType"] == "DesktopTx1" then
            Desktop::done()
            return
        end

        if item["mikuType"] == "NxCore" then
            NxBalls::stop(item)
            return
        end

        if item["mikuType"] == "DropBox" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green} ? '") then
                DropBox::done(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxBackup" then
            if useTheForce or LucilleCore::askQuestionAnswerAsBoolean("done: '#{item["description"].green}' ? ", true) then
                NxBalls::stop(item)
                DoNotShowUntil::setUnixtime(item["uuid"], Time.new.to_i + item["period"] * 86400 + rand)
                Items::setAttribute(item["uuid"], "last-done-unixtime", Time.new.to_i)
            end
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::mark_next_celebration_date(item)
            return
        end

        if item["mikuType"] == "NxLine" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxDated" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            if item["nx2290-important"] then
                return
            end
            if Bank1::getValue(item["uuid"]) > Bank1::getValueAtDate(item["uuid"], CommonUtils::today()) then
                return
            end
            if LucilleCore::askQuestionAnswerAsBoolean("confirm destroying: '#{PolyFunctions::toString(item).green} ? '") then
                Items::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "Wave" then
            if useTheForce or LucilleCore::askQuestionAnswerAsBoolean("done-ing: '#{PolyFunctions::toString(item).green} ? '", true) then
                Waves::perform_done(item)
            end
            return
        end

        puts "I do not know how to PolyActions::done(#{JSON.pretty_generate(item)})"
        raise "(error: f278f3e4-3f49-4f79-89d2-e5d3b8f728e6)"
    end

    # PolyActions::doubleDots(item)
    def self.doubleDots(item)
        return if NxBalls::itemIsActive(item)

        if item["uxpayload-b4e4"] and PolyFunctions::hasChildren(item) then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull('access mode', ["access payload", "dive"])
            if option == "access payload" then
                # we continue here
            end
            if option == "dive" then
                Operations::diveItem(item)
                return
            end
        end

        if item["mikuType"] == "NxCore" and item["uxpayload-b4e4"] and !PolyFunctions::hasChildren(item) then
            PolyActions::start(item)
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxCore" then
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxLambda" then
            NxLambdas::run(item)
            return
        end

        # Default

        PolyActions::start(item)
        PolyActions::access(item)
    end

    # PolyActions::tripleDots(item)
    def self.tripleDots(item)

        return if NxBalls::itemIsActive(item)

        if item["nx2290-important"] then
            PolyActions::start(item)
            PolyActions::access(item)
            LucilleCore::pressEnterToContinue("Press [enter] to stop: ")
            PolyActions::stop(item)
            return
        end

        if item["uxpayload-b4e4"] and PolyFunctions::hasChildren(item) then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull('access mode', ["access payload", "dive"])
            if option == "access payload" then
                # we continue here
            end
            if option == "dive" then
                Operations::diveItem(item)
                return
            end
        end

        if item["mikuType"] == "NxCore" and item["uxpayload-b4e4"] and !PolyFunctions::hasChildren(item) then
            PolyActions::start(item)
            PolyActions::access(item)
            LucilleCore::pressEnterToContinue("Press [enter] to done: ")
            PolyActions::done(item)
            return
        end

        if item["mikuType"] == "NxCore" then
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxLambda" then
            NxLambdas::run(item)
            return
        end

        if item["mikuType"] == "NxLine" then
            PolyActions::start(item)
            PolyActions::access(item)
            LucilleCore::pressEnterToContinue("Press [enter] to destroy: ")
            PolyActions::destroy(item, true)
            return
        end

        if item["mikuType"] == "NxTask" then
            PolyActions::start(item)
            PolyActions::access(item)
            LucilleCore::pressEnterToContinue("Press [enter] to done: ")
            PolyActions::destroy(item)
            return
        end

        if item["mikuType"] == "NxDated" then
            PolyActions::start(item)
            PolyActions::access(item)
            LucilleCore::pressEnterToContinue("Press [enter] to destroy: ")
            PolyActions::destroy(item)
            return
        end

        if item["mikuType"] == "Wave" then
            PolyActions::start(item)
            PolyActions::access(item)
            LucilleCore::pressEnterToContinue("Press [enter] to done: ")
            PolyActions::done(item, true)
            return
        end

        puts "I do not know how to PolyActions::tripleDots(#{JSON.pretty_generate(item)})"
        raise "(error: ba36812e-bd85-4c1a-9a10-e1d650a239a5)"
    end

    # PolyActions::destroy(item, force)
    def self.destroy(item, force = false)

        NxBalls::stop(item)

        if item["mikuType"] == "NxLambda" then
            return
        end

        if force then
            Items::destroy(item["uuid"])
            return
        end

        if item["mikuType"] == "NxFloat" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "Wave" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxCore" then
            return
        end

        if item["mikuType"] == "NxTask" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxLine" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxDated" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxBackup" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
            end
            return
        end

        puts "I do not know how to PolyActions::destroy(#{JSON.pretty_generate(item)})"
        raise "(error: f7ac071e-f2bb-4921-a7f3-22f268b25be8)"
    end

    # PolyActions::program(item)
    def self.program(item)

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::program1(item)
            return
        end

        if item["mikuType"] == "NxCore" then
            Operations::diveItem(core)
            return
        end

        if item["mikuType"] == "Wave" then
            Waves::program2(item)
            return
        end

        puts "PolyActions::program has not yet been implemented for miku type #{item["mikuType"]}"
        LucilleCore::pressEnterToContinue()
    end

    # PolyActions::pursue(item)
    def self.pursue(item)
        NxBalls::pursue(item)
    end

    # PolyActions::addTimeToItem(item, timeInSeconds)
    def self.addTimeToItem(item, timeInSeconds)
        PolyFunctions::itemToBankingAccounts(item).each{|account|
            puts "Adding #{timeInSeconds} seconds to account: #{account["description"]}"
            Bank1::put(account["number"], CommonUtils::today(), timeInSeconds)
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
