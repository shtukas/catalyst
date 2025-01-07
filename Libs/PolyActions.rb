
# encoding: UTF-8

class PolyActions

    # function names in alphabetical order

    # PolyActions::start(item)
    def self.start(item)
        puts "start: '#{PolyFunctions::toString(item).green}' ? "
        NxBalls::start(item)
    end

    # PolyActions::access(item)
    def self.access(item)

        if item["mikuType"] == "NxAnniversary" then
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

        if item["mikuType"] == "NxLongTask" then
            UxPayload::access(item["uuid"], item["uxpayload-b4e4"])
            return
        end

        if item["mikuType"] == "NxCore" then
            NxCores::program1(item)
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
    end

    # PolyActions::done(item, useTheForce = false)
    def self.done(item, useTheForce = false)

        NxBalls::stop(item)

        if item["mikuType"] == "NxFloat" then
            ListingPositioning::reposition(item)
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

        if item["mikuType"] == "NxBackup" then
            if useTheForce or LucilleCore::askQuestionAnswerAsBoolean("done: '#{item["description"].green}' ? ", true) then
                ListingPositioning::reposition(item)
            end
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::mark_next_celebration_date(item)
            ListingPositioning::reposition(item)
            return
        end

        if item["mikuType"] == "NxDated" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            puts "`done` is not implemented for NxTasks, you either `dismiss` for the day, or `destroy`"
            LucilleCore::pressEnterToContinue()
            return
        end

        if item["mikuType"] == "NxLongTask" then
            puts "`done` is not implemented for NxLongTasks, you either `dismiss` for the day, or `destroy`"
            LucilleCore::pressEnterToContinue()
            return
        end

        if item["mikuType"] == "NxCore" then
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

    # PolyActions::natural(item)
    def self.natural(item)

        processWaveLike = lambda{|item|
            if !NxBalls::itemIsActive(item) then
                PolyActions::start(item)
                PolyActions::access(item)
                if LucilleCore::askQuestionAnswerAsBoolean("done ? ") then
                    PolyActions::done(item, true)
                end
            end
        }

        processDestroyable = lambda {|item|
            if !NxBalls::itemIsActive(item) then
                PolyActions::start(item)
                PolyActions::access(item)
                if LucilleCore::askQuestionAnswerAsBoolean("done and destroy ? ") then
                    PolyActions::done(item, true)
                    PolyActions::destroy(item, true)
                    return
                end
                if LucilleCore::askQuestionAnswerAsBoolean("stop ? ") then
                    PolyActions::stop(item)
                    Operations::transformation1(item)
                    return
                end
            end
        }

        if item["mikuType"] == "NxAnniversary" then
            processWaveLike.call(item)
            return
        end

        if item["mikuType"] == "NxBackup" then
            processWaveLike.call(item)
            return
        end

        if item["mikuType"] == "NxFloat" then
            processWaveLike.call(item)
            return
        end

        if item["mikuType"] == "NxTask" then
            processDestroyable.call(item)
            return
        end

        if item["mikuType"] == "NxDated" then
            processDestroyable.call(item)
            return
        end

        if item["mikuType"] == "NxCore" then
            NxCores::program1(item)
            return
        end

        if item["mikuType"] == "Wave" then
            processWaveLike.call(item)
            return
        end

        if item["mikuType"] == "NxLongTask" then
            processWaveLike.call(item)
            return
        end

        raise "(error: abb645e9-2575-458e-b505-f9c029f4ca69) I do not know how to double dots #{item["mikuType"]}"
    end

    # PolyActions::destroy(item, force)
    def self.destroy(item, force = false)

        NxBalls::stop(item)

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

        if item["mikuType"] == "NxCore" then
            if !PolyFunctions::naturalChildren(item).empty? then
                puts "You cannot destroy NxCore '#{PolyFunctions::toString(item).green}' because it has children."
                LucilleCore::pressEnterToContinue()
                return
            end
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Items::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxLongTask" then
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
