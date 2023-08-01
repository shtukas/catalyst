 
# encoding: UTF-8

class PolyActions

    # function names in alphabetical order

    # PolyActions::access(item)
    def self.access(item)

        # types in alphabetical order

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::accessAndDone(item)
            return
        end

        if item["mikuType"] == "NxBackup" then
            if LucilleCore::askQuestionAnswerAsBoolean("done '#{PolyFunctions::toString(item).green}' ? ", true) then
                NxBackups::performDone(item)
            end
            return
        end

        if item["mikuType"] == "NxDelegate" then
            puts NxDelegates::toString(item)
            LucilleCore::pressEnterToContinue()
            return
        end

        if item["mikuType"] == "NxThread" then
            NxThreads::program1(item)
            return
        end

        if item["mikuType"] == "NxTime" then
            return
        end

        if item["mikuType"] == "NxLambda" then
            item["lambda"].call()
            return
        end

        if item["mikuType"] == "NxPrimeDirective" then
            puts NxPrimeDirectives::toString(item)
            LucilleCore::pressEnterToContinue()
            return
        end

        if item["mikuType"] == "NxOndate" then
            NxOndates::access(item)
            return
        end

        if item["mikuType"] == "NxTask" then
            NxTasks::access(item)
            return
        end

        if item["mikuType"] == "NxLongTask" then
            CoreDataRefStrings::access(item["uuid"], item["field11"])
            return
        end

        if item["mikuType"] == "TxCore" then
            TxCores::program1(item)
            return
        end

        if item["mikuType"] == "PhysicalTarget" then
            PhysicalTargets::access(item)
            return
        end

        if item["mikuType"] == "Wave" then
            Waves::access(item)
            return
        end

        raise "(error: abb645e9-2575-458e-b505-f9c029f4ca69) I do not know how to access mikuType: #{item["mikuType"]}"
    end

    # PolyActions::done(item)
    def self.done(item)

        NxBalls::stop(item)

        # Removing park, if any.
        item["parking"] = nil
        item["skipped"] = false

        # order: alphabetical order

        if item["mikuType"] == "DropBox" then
            if LucilleCore::askQuestionAnswerAsBoolean("done-ing: '#{PolyFunctions::toString(item).green} ? '", true) then
                DropBox::done(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxBackup" then
            if LucilleCore::askQuestionAnswerAsBoolean("done-ing: '#{PolyFunctions::toString(item).green} ? '", true) then
                DoNotShowUntil::setUnixtime(item, Time.new.to_i + item["periodInDays"] * 86400)
            end
            return
        end

        if item["mikuType"] == "NxThread" then
            puts "You cannot done a NxThread, but you can destroy it"
            LucilleCore::pressEnterToContinue()
            return
        end

        if item["mikuType"] == "NxPrimeDirective" then
            puts "You cannot done a NxPrimeDirective, but you can destroy it"
            LucilleCore::pressEnterToContinue()
            return
        end

        if item["mikuType"] == "NxLambda" then
            return
        end

        if item["mikuType"] == "NxDelegate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                BladesGI::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxLongTask" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                BladesGI::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTime" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                BladesGI::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::done(item["uuid"])
            return
        end

        if item["mikuType"] == "NxLine" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                BladesGI::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxLong" then
            BladesGI::destroy(item["uuid"])
            return
        end

        if item["mikuType"] == "NxBackup" then
            puts "done-ing item: #{item["description"]}"
            NxBackups::performDone(item)
            return
        end

        if item["mikuType"] == "NxOndate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                BladesGI::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxOndate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                BladesGI::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            if Tx8s::childrenInOrder(item).size > 0 then
                puts "The item has children"
                Tx8s::childrenInOrder(item).each{|i|
                    puts " - #{PolyFunctions::toString(item)}"
                }
                if LucilleCore::askQuestionAnswerAsBoolean("> destroy all of them ?") then
                    Tx8s::childrenInOrder(item).each{|i|
                        BladesGI::destroy(i["uuid"])
                    }
                end
            end
            if Tx8s::childrenInOrder(item).size > 0 then
                return
            end
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                PolyActions::addTimeToItem(item, 300) # cosmological inflation 😄
                BladesGI::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTime" then
            puts "done-ing: '#{NxTimes::toString(item).green}'"
            BladesGI::destroy(item["uuid"])
            return
        end

        if item["mikuType"] == "PhysicalTarget" then
            PhysicalTargets::performUpdate(item)
            return
        end

        if item["mikuType"] == "TxCore" then
            puts "You cannot done a TxCore"
            LucilleCore::pressEnterToContinue()
            return
        end

        if item["mikuType"] == "Wave" then
            if LucilleCore::askQuestionAnswerAsBoolean("done-ing: '#{PolyFunctions::toString(item).green} ? '", true) then
                Waves::performWaveDone(item)
            end
            return
        end

        puts "I do not know how to PolyActions::done(#{JSON.pretty_generate(item)})"
        raise "(error: f278f3e4-3f49-4f79-89d2-e5d3b8f728e6)"
    end

    # PolyActions::destroy(item)
    def self.destroy(item)

        NxBalls::stop(item)

        if Tx8s::childrenInOrder(item).size > 0 then
            puts "Found Tx8 children for '#{PolyFunctions::toString(item).green}'. Cannot be destroyed"
            LucilleCore::pressEnterToContinue()
            return
        end

        if item["mikuType"] == "Wave" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                BladesGI::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxThread" then
            if Tx8s::childrenInOrder(item).size > 0 then
                puts "You cannot destroy '#{PolyFunctions::toString(item).green}' at this time. It has #{Tx8s::childrenInOrder(item).size} children items"
                LucilleCore::pressEnterToContinue()
                return
            end
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                BladesGI::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxDelegate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                BladesGI::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxOndate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                BladesGI::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxPrimeDirective" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                BladesGI::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "TxCore" then
            puts "You cannot done a TxCore"
            LucilleCore::pressEnterToContinue()
            return
        end

        puts "I do not know how to PolyActions::destroy(#{JSON.pretty_generate(item)})"
        raise "(error: f7ac071e-f2bb-4921-a7f3-22f268b25be8)"
    end

    # PolyActions::doubleDot(item)
    def self.doubleDot(item)

        if item["mikuType"] == "NxBackup" then
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxThread" then
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxOndate" then
            PolyFunctions::toString(item).green
            NxBalls::start(item)
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxLongTask" then
            PolyFunctions::toString(item).green
            NxBalls::start(item)
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxPrimeDirective" then
            puts NxPrimeDirectives::toString(item)
            LucilleCore::pressEnterToContinue()
            return
        end

        if item["mikuType"] == "NxDelegate" then
            return
        end

        if item["mikuType"] == "NxTime" then
            BladesGI::destroy(item["uuid"])
            return
        end

        if item["mikuType"] == "NxTask" then
            puts PolyFunctions::toString(item).green
            first_time = (Bank::getValue(item["uuid"]) == 0)
            NxBalls::start(item)
            NxTasks::access(item)
            if first_time then
                if LucilleCore::askQuestionAnswerAsBoolean("done and destroy '#{PolyFunctions::toString(item).green}' ? ", true) then
                    NxBalls::stop(item)
                    BladesGI::destroy(item["uuid"])
                end
            end
            if NxBalls::itemIsRunning(item) then
                if LucilleCore::askQuestionAnswerAsBoolean("stop '#{PolyFunctions::toString(item).green} ? '", true) then
                    NxBalls::stop(item)
                end
            end
            return
        end

        if item["mikuType"] == "PhysicalTarget" then
            PolyFunctions::toString(item).green
            PhysicalTargets::access(item)
            return
        end

        if item["mikuType"] == "Wave" then
            PolyFunctions::toString(item).green
            NxBalls::start(item)
            PolyActions::access(item)
            if LucilleCore::askQuestionAnswerAsBoolean("done-ing: '#{Waves::toString(item).green} ? '", true) then
                NxBalls::stop(item)
                Waves::performWaveDone(item)
            end
            return
        end

        if item["mikuType"] == "TxCore" then
            TxCores::program1(item)
            return
        end

        puts "I don't know how to double dot '#{item["mikuType"]}'"
        LucilleCore::pressEnterToContinue()
    end

    # PolyActions::doubleArrow(item)
    def self.doubleArrow(item)
        if item["mikuType"] == "NxTask" then
            puts PolyFunctions::toString(item)
            if item["description"].start_with?("(buffer-in)") then
                BladesGI::setAttribute2(item["uuid"], "description", item["description"][11, item["description"].size].strip)
                item = BladesGI::itemOrNull(item["uuid"])
            end
            Tx8s::move(item)
            return
        end
        if item["mikuType"] == "NxOndate" then
            puts PolyFunctions::toString(item)
            Tx8s::move(item)
            BladesGI::setAttribute2(item["uuid"], "mikuType", "NxTask")
            return
        end
        puts "I do not know how to double arrow"
        exit
    end

    # PolyActions::program(item)
    def self.program(item)

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::program1(item)
            return
        end

        if item["mikuType"] == "NxBackup" then
            NxBackups::program(item)
            return
        end

        if item["mikuType"] == "Wave" then
            Waves::program2(item)
            return
        end

        if item["mikuType"] == "NxThread" then
            PolyActions::access(item)
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
        PolyFunctions::itemToBankingAccounts(item).each{|account|
            puts "Adding #{timeInSeconds} seconds to account: #{account["description"]}"
            Bank::put(account["number"], timeInSeconds)
        }
    end

    # PolyActions::editDescription(item)
    def self.editDescription(item)
        if item["mikuType"] == "NxBackup" then
            puts "There is no description edit for NxBackups (inherited from the file)"
            LucilleCore::pressEnterToContinue()
            return
        end
        puts "edit description:"
        description = CommonUtils::editTextSynchronously(item["description"]).strip
        return if description == ""
        BladesGI::setAttribute2(item["uuid"], "description", description)
    end
end
