
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

        if item["uxpayload-b4e4"] and Index2::hasChildren(item["uuid"]) then
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

        if item["mikuType"] == "NxCore" then
            if item["uxpayload-b4e4"] and !Index2::hasChildren(item["uuid"]) then
                UxPayload::access(item["uuid"], item["uxpayload-b4e4"])
                return
            end
            Operations::diveItem(item)
            return
        end

        if item["uxpayload-b4e4"] then
            UxPayload::access(item["uuid"], item["uxpayload-b4e4"])
            return
        end
    end

    # PolyActions::stop(item)
    def self.stop(item)
        NxBalls::stop(item)
        if item["mikuType"] == "NxProject" then
            puts "You are stopping a NxProject"
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["dismiss for the day", "transmute to project", "actually stop it (default)"])
            if option.nil? or option == "actually stop it (default)" then
                return
            end
            if option == "dismiss for the day" then
                unixtime = CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone()
                puts "pushing until '#{Time.at(unixtime).to_s.green}'"
                NxBalls::stop(item)
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                Index0::removeEntry(item["uuid"])
                return
            end
        end
        if item["mikuType"] == "NxTask" then
            puts "You are stopping a NxTask"
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["dismiss for the day", "transmute to project", "actually stop it (default)"])
            if option.nil? or option == "actually stop it (default)" then
                return
            end
            if option == "transmute to project" then
                Items::setAttribute(item["uuid"], "project-position", NxProjects::getNextPosition())
                Items::setAttribute(item["uuid"], "commitment-date", CommonUtils::today())
                Items::setAttribute(item["uuid"], "commitment-hours", 0)
                Items::setAttribute(item["uuid"], "mikuType", "NxProject")
                item = Items::itemOrNull(item["uuid"])
                puts JSON.pretty_generate(item)
                Index0::removeEntry(item["uuid"])
                return
            end
            if option == "dismiss for the day" then
                unixtime = CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone()
                puts "pushing until '#{Time.at(unixtime).to_s.green}'"
                NxBalls::stop(item)
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                Index0::removeEntry(item["uuid"])
                return
            end
        end
        if item["mikuType"] == "NxCore" then
            puts "You are stopping a NxCore"
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["dismiss for the day", "actually stop it (default)"])
            if option.nil? or option == "actually stop it (default)" then
                return
            end
            if option == "dismiss for the day" then
                unixtime = CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone()
                puts "pushing until '#{Time.at(unixtime).to_s.green}'"
                NxBalls::stop(item)
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                Index0::removeEntry(item["uuid"])
                return
            end
        end
        Index0::evaluate(item["uuid"])
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

        if item["mikuType"] == "NxLambda" then
            Index0::removeEntry(item["uuid"])
            return
        end

        if item["mikuType"] == "NxFloat" then
            NxBalls::stop(item)
            DoNotShowUntil::setUnixtime(item["uuid"], CommonUtils::unixtimeAtComingMidnightAtLocalTimezone() + 3600*6 + rand)
            Index0::removeEntry(item["uuid"])
            return
        end

        if item["mikuType"] == "DesktopTx1" then
            Desktop::done()
            Index0::removeEntry(item["uuid"])
            return
        end

        if item["mikuType"] == "NxCore" then
            NxBalls::stop(item)
            Index0::evaluate(item["uuid"])
            return
        end

        if item["mikuType"] == "DropBox" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green} ? '") then
                DropBox::done(item["uuid"])
                Index0::removeEntry(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxBackup" then
            if LucilleCore::askQuestionAnswerAsBoolean("done: '#{item["description"].green}' ? ", true) then
                NxBalls::stop(item)
                DoNotShowUntil::setUnixtime(item["uuid"], Time.new.to_i + item["period"] * 86400 + rand)
                Items::setAttribute(item["uuid"], "last-done-unixtime", Time.new.to_i)
                Index0::removeEntry(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::mark_next_celebration_date(item)
            Index0::removeEntry(item["uuid"])
            return
        end

        if item["mikuType"] == "NxLine" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
                Index0::removeEntry(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxProject" then
            DoNotShowUntil::setUnixtime(item["uuid"], CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone())
            return
        end

        if item["mikuType"] == "NxDated" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
                Index0::removeEntry(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
                Index0::removeEntry(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "Wave" then
            Waves::perform_done(item)
            Index0::removeEntry(item["uuid"])
            return
        end

        puts "I do not know how to PolyActions::done(#{JSON.pretty_generate(item)})"
        raise "(error: f278f3e4-3f49-4f79-89d2-e5d3b8f728e6)"
    end

    # PolyActions::doubleDots(item)
    def self.doubleDots(item)
        if item["mikuType"] == "NxCore" then
            PolyActions::access(item)
            return
        end

        return if NxBalls::itemIsActive(item)

        if item["uxpayload-b4e4"] and Index2::hasChildren(item["uuid"]) then
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

        # Default

        PolyActions::start(item)
        PolyActions::access(item)
    end

    # PolyActions::tripleDots(item)
    def self.tripleDots(item)

        return if NxBalls::itemIsActive(item)

        if item["uxpayload-b4e4"] and Index2::hasChildren(item["uuid"]) then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull('access mode', ["access payload", "dive"])
            if option == "access payload" then
                # we continue here
            end
            if option == "dive" then
                Operations::diveItem(item)
                return
            end
        end

        if item["mikuType"] == "NxCore" and item["uxpayload-b4e4"] and !Index2::hasChildren(item["uuid"]) then
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
            PolyActions::done(item)
            return
        end

        if item["mikuType"] == "NxTask" then
            PolyActions::start(item)
            PolyActions::access(item)
            LucilleCore::pressEnterToContinue("Press [enter] to done: ")
            PolyActions::destroy(item)
            return
        end

        if item["mikuType"] == "NxProject" then
            PolyActions::start(item)
            PolyActions::access(item)
            LucilleCore::pressEnterToContinue("Press [enter] to done: ")
            PolyActions::done(item)
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
            PolyActions::done(item)
            return
        end

        puts "I do not know how to PolyActions::tripleDots(#{JSON.pretty_generate(item)})"
        raise "(error: ba36812e-bd85-4c1a-9a10-e1d650a239a5)"
    end

    # PolyActions::destroy(item)
    def self.destroy(item)

        NxBalls::stop(item)

        if Index2::hasChildren(item["uuid"]) then
            puts "You cannot destroy an item that has children"
            LucilleCore::pressEnterToContinue()
            return
        end

        if item["mikuType"] == "NxLambda" then
            Index0::removeEntry(item["uuid"])
            return
        end

        if item["mikuType"] == "NxFloat" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
                Index0::removeEntry(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "Wave" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
                Index0::removeEntry(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxCore" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
                Index0::removeEntry(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
                Index0::removeEntry(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxProject" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
                Index0::removeEntry(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxLine" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
                Index0::removeEntry(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxDated" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
                Index0::removeEntry(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
                Index0::removeEntry(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxBackup" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
                Index0::removeEntry(item["uuid"])
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
            Waves::program0(item)
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
