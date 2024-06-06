
# encoding: UTF-8

class PolyActions

    # function names in alphabetical order

    # PolyActions::access(item)
    def self.access(item)

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::accessAndDone(item)
            return
        end

        if item["mikuType"] == "NxBackup" then
            return
        end

        if item["mikuType"] == "NxFloat" then
            return
        end

        if item["mikuType"] == "NxLambda" then
            item["lambda"].call()
            return
        end

        if item["mikuType"] == "NxOndate" then
            UxPayload::access(item["uuid"], item["uxpayload-b4e4"])
            return
        end

        if item["mikuType"] == "NxTodo" then
            UxPayload::access(item["uuid"], item["uxpayload-b4e4"])
            return
        end

        if item["mikuType"] == "NxThread" then
            NxThreads::program1(item)
            return
        end

        if item["mikuType"] == "PhysicalTarget" then
            PhysicalTargets::access(item)
            return
        end

        if item["mikuType"] == "Wave" then
            UxPayload::access(item["uuid"], item["uxpayload-b4e4"])
            return
        end

        if item["mikuType"] == "NxBufferInMonitor" then
            return
        end

        raise "(error: abb645e9-2575-458e-b505-f9c029f4ca69) I do not know how to access mikuType: #{item["mikuType"]}"
    end

    # PolyActions::done(item, confirmed = false)
    def self.done(item, confirmed = false)

        NxBalls::stop(item)

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
                NxBackups::setNowForDescription(item["description"])
            end
            return
        end

        if item["mikuType"] == "NxLambda" then
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::done(item["uuid"])
            return
        end

        if item["mikuType"] == "NxTodo" then
            if confirmed or LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Cubes1::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxThread" then
            DoNotShowUntil1::setUnixtime(item["uuid"], CommonUtils::unixtimeAtComingMidnightAtLocalTimezone()+3600*6)
            return
        end

        if item["mikuType"] == "NxOndate" then
            if confirmed or LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Cubes1::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "PhysicalTarget" then
            PhysicalTargets::performUpdate(item)
            return
        end

        if item["mikuType"] == "Wave" then
            if confirmed or LucilleCore::askQuestionAnswerAsBoolean("done-ing: '#{PolyFunctions::toString(item).green} ? '", true) then
                Waves::performWaveDone(item)
            end
            return
        end

        if item["mikuType"] == "NxBufferInMonitor" then
            DoNotShowUntil1::setUnixtime(item["uuid"], CommonUtils::unixtimeAtComingMidnightAtLocalTimezone()+3600*6)
            return
        end

        puts "I do not know how to PolyActions::done(#{JSON.pretty_generate(item)})"
        raise "(error: f278f3e4-3f49-4f79-89d2-e5d3b8f728e6)"
    end

    # PolyActions::doubledots(item)
    def self.doubledots(item)

        if item["mikuType"] == "NxFloat" then
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
            PolyActions::done(item)
            return
        end

        if item["mikuType"] == "NxLambda" then
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::done(item["uuid"])
            return
        end

        if item["mikuType"] == "NxTodo" then
            NxBalls::start(item)
            UxPayload::access(item["uuid"], item["uxpayload-b4e4"])
            LucilleCore::pressEnterToContinue()
            NxBalls::stop(item)
            if LucilleCore::askQuestionAnswerAsBoolean("'#{PolyFunctions::toString(item).green}' is empty. Destroy:  ? ", true) then
                Cubes1::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxThread" then
            NxThreads::program1(item)
            return
        end

        if item["mikuType"] == "NxOndate" then
            if !NxBalls::itemIsActive(item) then
                NxBalls::start(item)
            end
            PolyActions::access(item)
            LucilleCore::pressEnterToContinue()
            NxBalls::stop(item)
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Cubes1::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "PhysicalTarget" then
            PhysicalTargets::performUpdate(item)
            return
        end

        if item["mikuType"] == "Wave" then
            if !NxBalls::itemIsActive(item) then
                NxBalls::start(item)
            end
            PolyActions::access(item)
            if LucilleCore::askQuestionAnswerAsBoolean("completed : '#{PolyFunctions::toString(item).green} ? '", true) then
                NxBalls::stop(item)
                Waves::performWaveDone(item)
            end
            return
        end

        if item["mikuType"] == "NxBufferInMonitor" then
            return
        end

        puts "I do not know how to PolyActions::doubledots(#{JSON.pretty_generate(item)})"
        raise "(error: f278f3e4-3f49-4f79-89d2-e5d3b8f728e6)"
    end

    # PolyActions::destroy(item)
    def self.destroy(item)

        NxBalls::stop(item)

        if item["mikuType"] == "NxFloat" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Cubes1::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "Wave" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Cubes1::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTodo" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Cubes1::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxThread" then
            if Catalyst::children(item).size > 0 then
                puts "You can't destroy thread '#{PolyFunctions::toString(item).green}' which is not empty"
                LucilleCore::pressEnterToContinue()
                return
            end
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Cubes1::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Cubes1::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxOndate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Cubes1::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxBackup" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Cubes1::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxBufferInMonitor" then
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
        NxBalls::start(item)
    end

    # PolyActions::addTimeToItem(item, timeInSeconds)
    def self.addTimeToItem(item, timeInSeconds)
        PolyFunctions::itemToBankingAccounts(nil, item).each{|account|
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
        Cubes1::setAttribute(item["uuid"], "description", description)
    end
end
