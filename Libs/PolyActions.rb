
# encoding: UTF-8

class PolyActions

    # function names in alphabetical order

    # PolyActions::access(item)
    def self.access(item)

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::advance(item)
            return
        end

        if item["mikuType"] == "NxBackup" then
            return
        end

        if item["mikuType"] == "NxFloat" then
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

        if item["mikuType"] == "NxCapsuledTask" then
            NxCapsuledTasks::program1(item)
            return
        end

        if item["mikuType"] == "NxTimeCapsule" then
            NxTimeCapsules::program1(item)
            return
        end

        if item["mikuType"] == "NxStrat" then
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
        if item["mikuType"] == "NxTimeCapsule" then
            return
        end
        Items::setAttribute(item["uuid"], "flight-data-27", nil)
    end

    # PolyActions::done(item, useTheForce = false)
    def self.done(item, useTheForce = false)

        NxBalls::stop(item)

        if item["mikuType"] == "NxTimeCapsule" then
            return
        end

        Items::setAttribute(item["uuid"], "flight-data-27", nil)

        if item["mikuType"] == "NxFloat" then
            DoNotShowUntil1::setUnixtime(item["uuid"], CommonUtils::unixtimeAtComingMidnightAtLocalTimezone()+3600*6)
            return
        end

        if item["mikuType"] == "DesktopTx1" then
            Desktop::done()
            return
        end

        if item["mikuType"] == "DropBox" then
            if LucilleCore::askQuestionAnswerAsBoolean("done-ing: '#{PolyFunctions::toString(item).green} ? '", true) then
                DropBox::done(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxBackup" then
            if LucilleCore::askQuestionAnswerAsBoolean("done: '#{item["description"].green}' ? ", true) then
                NxBackups::resetDescriptionDateTime(item["description"])
            end
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::advance(item)
            return
        end

        if item["mikuType"] == "NxDated" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxCapsuledTask" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxStrat" then
            return if NxStrats::topOrNull(item["uuid"])
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxCapsuledTask" then
            return
        end

        if item["mikuType"] == "Wave" then
            if useTheForce or LucilleCore::askQuestionAnswerAsBoolean("done-ing: '#{PolyFunctions::toString(item).green} ? '", true) then
                Waves::advance(item)
            end
            return
        end

        puts "I do not know how to PolyActions::done(#{JSON.pretty_generate(item)})"
        raise "(error: f278f3e4-3f49-4f79-89d2-e5d3b8f728e6)"
    end

    # PolyActions::perform(item)
    def self.perform(item)

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::advance(item)
            return
        end

        if item["mikuType"] == "NxBackup" then
            PolyActions::done(item)
            return
        end

        if item["mikuType"] == "NxFloat" then
            PolyActions::done(item)
            return
        end

        if item["mikuType"] == "NxTask" then
            PolyActions::start(item)
            PolyActions::access(item)
            if LucilleCore::askQuestionAnswerAsBoolean("stop & destroy ? ") then
                PolyActions::destroy(item, true)
            else
                if LucilleCore::askQuestionAnswerAsBoolean("stop ? ") then
                    PolyActions::stop(item)
                end
            end
            return
        end

        if item["mikuType"] == "NxCapsuledTask" then
            PolyActions::start(item)
            PolyActions::access(item)
            if LucilleCore::askQuestionAnswerAsBoolean("stop & destroy ? ") then
                PolyActions::destroy(item, true)
            else
                if LucilleCore::askQuestionAnswerAsBoolean("stop ? ") then
                    PolyActions::stop(item)
                end
            end
            return
        end

        if item["mikuType"] == "NxDated" then
            PolyActions::start(item)
            PolyActions::access(item)
            if LucilleCore::askQuestionAnswerAsBoolean("stop & destroy ? ") then
                PolyActions::destroy(item, true)
            else
                if LucilleCore::askQuestionAnswerAsBoolean("stop ? ") then
                    PolyActions::stop(item)
                end
            end
            return
        end

        if item["mikuType"] == "NxStrat" then
            PolyActions::start(item)
            PolyActions::access(item)
            if LucilleCore::askQuestionAnswerAsBoolean("stop & destroy ? ") then
                PolyActions::destroy(item, true)
            else
                if LucilleCore::askQuestionAnswerAsBoolean("stop ? ") then
                    PolyActions::stop(item)
                end
            end
            return
        end

        if item["mikuType"] == "NxTimeCapsule" then
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxCapsuledTask" then
            NxCapsuledTasks::program1(item)
            return
        end

        if item["mikuType"] == "Wave" then
            PolyActions::start(item)
            PolyActions::access(item)
            if LucilleCore::askQuestionAnswerAsBoolean("done ? ") then
                PolyActions::done(item, true)
            end
            return
        end

        raise "(error: abb645e9-2575-458e-b505-f9c029f4ca69) I do not know how to double dots #{item["mikuType"]}"
    end

    # PolyActions::destroy(item)
    def self.destroy(item)

        NxBalls::stop(item)

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

        if item["mikuType"] == "NxTask" then
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

        if item["mikuType"] == "NxTimeCapsule" then
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxStrat" then
            return if NxStrats::topOrNull(item["uuid"])
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

        if item["mikuType"] == "NxCapsuledTask" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxCapsuledTask" then
            if !PolyFunctions::children(item).empty? then
                puts "You cannot destroy core '#{PolyFunctions::toString(item).green}' because it has children."
                LucilleCore::pressEnterToContinue()
                return
            end
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

    # PolyActions::start(item)
    def self.start(item)
        puts "start: '#{PolyFunctions::toString(item).green}' ? "
        NxBalls::start(item)
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
        if item["mikuType"] == "NxBackup" then
            puts "There is no description edit for Backups (inherited from the file)"
            LucilleCore::pressEnterToContinue()
            return
        end
        puts "edit description:"
        description = CommonUtils::editTextSynchronously(item["description"]).strip
        return if description == ""
        Items::setAttribute(item["uuid"], "description", description)
    end
end
