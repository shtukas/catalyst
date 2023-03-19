
# encoding: UTF-8

class PolyActions

    # function names in alphabetical order

    # PolyActions::access(item)
    def self.access(item)

        # types in alphabetical order

        if item["mikuType"] == "DeviceBackup" then
            puts item["announce"]
            LucilleCore::pressEnterToContinue()
            return
        end

        if item["mikuType"] == "LambdX1" then
            item["lambda"].call()
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::accessAndDone(item)
            return
        end

        if item["mikuType"] == "NxBoard" then
            NxBoards::listingProgram(item)
            return
        end

        if item["mikuType"] == "NxCherryPick" then
            object = N3Objects::getOrNull(item["targetuuid"])
            return if object.nil? 
            return PolyActions::access(object)
        end

        if item["mikuType"] == "NxLine" then
            puts "nxline: #{item["description"]}".green
            LucilleCore::pressEnterToContinue()
            return
        end

        if item["mikuType"] == "NxOndate" then
            NxOndates::access(item)
            return
        end

        if item["mikuType"] == "NxOrbital" then
            CoreData::access(item["field11"])
            return
        end

        if item["mikuType"] == "NxFire" then
            CoreData::access(item["field11"])
            return
        end

        if item["mikuType"] == "NxBoard" then
            puts NxBoards::toString(item)
            actions = ["set hours", "access items"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "set hours" then
                puts "Not implemented yet"
                LucilleCore::pressEnterToContinue()
            end
            if action == "access items" then
                puts "Not implemented yet"
                LucilleCore::pressEnterToContinue()
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            NxTasks::access(item)
            return
        end

        if item["mikuType"] == "TxManualCountDown" then
            TxManualCountDowns::access(item)
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

        if item["mikuType"] == "DeviceBackup" then
            if LucilleCore::askQuestionAnswerAsBoolean("done-ing '#{item["announce"].green} ? '", true) then
                DoNotShowUntil::setUnixtime(item["uuid"], Time.new.to_i + item["instruction"]["period"] * 86400)
            end
            return
        end

        if item["mikuType"] == "LambdX1" then
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::done(item["uuid"])
            return
        end

        if item["mikuType"] == "NxBoard" then
            puts "There is no done action on NxBoards. If it was running, I have stopped it."
            LucilleCore::pressEnterToContinue()
            return
        end

        if item["mikuType"] == "NxOndate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunctions::toString(item).green}' ? ", true) then
                NxOndates::access(item)
            end
            return
        end

        if item["mikuType"] == "NxCherryPick" then
            object = N3Objects::getOrNull(item["targetuuid"])
            if object then
                PolyActions::done(object)
            end
            NxCherryPicks::destroy(item["uuid"])
            return
        end

        if item["mikuType"] == "NxLine" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunctions::toString(item).green}' ? ", true) then
                N3Objects::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxOrbital" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunctions::toString(item).green}' ? ", true) then
                NxOrbitals::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxFire" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunctions::toString(item).green}' ? ", true) then
                NxOrbitals::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxOndate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunctions::toString(item).green}' ? ", true) then
                NxOndates::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunctions::toString(item).green}' ? ", true) then
                NxTasks::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "TxManualCountDown" then
            TxManualCountDowns::performUpdate(item)
            return
        end

        if item["mikuType"] == "Wave" then
            if LucilleCore::askQuestionAnswerAsBoolean("done-ing '#{Waves::toString(item).green} ? '", true) then
                Waves::performWaveNx46WaveDone(item)
            end
            return
        end

        puts "I do not know how to PolyActions::done(#{JSON.pretty_generate(item)})"
        raise "(error: f278f3e4-3f49-4f79-89d2-e5d3b8f728e6)"
    end

    # PolyActions::doubleDot(item)
    def self.doubleDot(item)

        if item["mikuType"] == "DeviceBackup" then
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxBoard" then
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxCherryPick" then
            object = N3Objects::getOrNull(item["targetuuid"])
            return if object.nil? 
            NxBalls::start(item)
            PolyActions::start(object)
            return
        end

        if item["mikuType"] == "NxOndate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunctions::toString(item).green}' ? ", true) then
                NxOndates::access(item)
            end
            return
        end

        if item["mikuType"] == "NxOrbital" then
            NxBalls::start(item)
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxFire" then
            NxBalls::start(item)
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxLine" then
            NxBalls::start(item)
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxTask" then
            NxBalls::start(item)
            NxTasks::access(item)
            return
        end

        if item["mikuType"] == "TxManualCountDown" then
            TxManualCountDowns::access(item)
            return
        end

        if item["mikuType"] == "Wave" then
            NxBalls::start(item)
            PolyActions::access(item)
            if LucilleCore::askQuestionAnswerAsBoolean("done-ing '#{Waves::toString(item).green} ? '", true) then
                NxBalls::stop(item)
                Waves::performWaveNx46WaveDone(item)
            end
            return
        end

        puts "I don't know how to doubleDot '#{item["mikuType"]}'"
        LucilleCore::pressEnterToContinue()
    end

    # PolyActions::landing(item)
    def self.landing(item)

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::landing(item)
            return
        end

        if item["mikuType"] == "NxBoard" then
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxCherryPick" then
            object = N3Objects::getOrNull(item["targetuuid"])
            return if object.nil? 
            return PolyActions::landing(object)
        end

        if item["mikuType"] == "Wave" then
            Waves::landing(item)
            return
        end

        puts "PolyActions::landing has not yet been implemented for miku type #{item["mikuType"]}"
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
        PolyFunctions::itemsToBankingAccounts(item).each{|account|
            puts "Adding #{timeInSeconds} seconds to account: #{account["description"]}"
            BankCore::put(account["number"], timeInSeconds)
        }
    end

    # PolyActions::editDescription(item)
    def self.editDescription(item)

        if item["mikuType"] == "DeviceBackup" then
            puts "There is no description edit for DeviceBackups"
            LucilleCore::pressEnterToContinue()
            return
        end

        puts "edit description:"
        item["description"] = CommonUtils::editTextSynchronously(item["description"])
        N3Objects::commit(item)
    end

    # PolyActions::dropmaking(useCoreData: true)
    def self.dropmaking(useCoreData: true)
        item = nil
        options = ["fire", "orbital", "today", "ondate", "wave", "countdown", "task"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        return nil if option.nil?
        if option == "fire" then
            item = NxFires::interactivelyIssueNullOrNull(useCoreData: useCoreData)
        end
        if option == "orbital" then
            item = NxOrbitals::interactivelyIssueNullOrNull(useCoreData: useCoreData)
        end
        if option == "today" then
            item = NxOndates::interactivelyIssueNewTodayOrNull(useCoreData: useCoreData)
        end
        if option == "ondate" then
            item = NxOndates::interactivelyIssueNullOrNull(useCoreData: useCoreData)
        end
        if option == "wave" then
            item = Waves::issueNewWaveInteractivelyOrNull(useCoreData: useCoreData)
        end
        if option == "countdown" then
            item = TxManualCountDowns::issueNewOrNull(useCoreData: useCoreData)
        end
        if option == "task" then
            item = NxTasks::interactivelyIssueNewOrNull(useCoreData: useCoreData)
        end
        if item then
            puts JSON.pretty_generate(item)
        end
        return item
    end
end
