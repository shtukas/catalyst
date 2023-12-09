
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

        if item["mikuType"] == "Backup" then
            return
        end

        if item["mikuType"] == "NxLambda" then
            item["lambda"].call()
            return
        end

        if item["mikuType"] == "NxOndate" then
            CoreDataRefStrings::accessAndMaybeEdit(item["uuid"], item["field11"])
            return
        end

        if item["mikuType"] == "NxCruiser" then
            NxCruisers::access(item)
            return
        end

        if item["mikuType"] == "NxTask" then
            NxTasks::access(item)
            return
        end

        if item["mikuType"] == "NxStrat" then
            return
        end

        if item["mikuType"] == "PhysicalTarget" then
            PhysicalTargets::access(item)
            Ox1::detach(item)
            return
        end

        if item["mikuType"] == "Wave" then
            Waves::access(item)
            return
        end

        raise "(error: abb645e9-2575-458e-b505-f9c029f4ca69) I do not know how to access mikuType: #{item["mikuType"]}"
    end

    # PolyActions::done(item, confirmed = false)
    def self.done(item, confirmed = false)

        NxBalls::stop(item)
        Ox1::detach(item)

        # order: alphabetical order

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

        if item["mikuType"] == "Backup" then
            XCache::set("1c959874-c958-469f-967a-690d681412ca:#{item["uuid"]}", Time.new.to_i)
            return
        end

        if item["mikuType"] == "NxLambda" then
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::done(item["uuid"])
            return
        end

        if item["mikuType"] == "NxCruiser" then
            return NxCruisers::done(item)
        end

        if item["mikuType"] == "NxStrat" then
            if parent = NxStrats::parentOrNull(item) then
                puts "You cannot done NxStrat '#{PolyFunctions::toString(item).green}' as it has a parent: '#{PolyFunctions::toString(parent).green}'"
                LucilleCore::pressEnterToContinue()
                return
            end
            if confirmed or LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                DataCenter::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxOndate" then
            if confirmed or LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                DataCenter::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                PolyActions::addTimeToItem(item, 300) # cosmological inflation 😄
                DataCenter::destroy(item["uuid"])
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

        puts "I do not know how to PolyActions::done(#{JSON.pretty_generate(item)})"
        raise "(error: f278f3e4-3f49-4f79-89d2-e5d3b8f728e6)"
    end

    # PolyActions::natural(item)
    def self.natural(item)

        # order: alphabetical order

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

        if item["mikuType"] == "Backup" then
            XCache::set("1c959874-c958-469f-967a-690d681412ca:#{item["uuid"]}", Time.new.to_i)
            return
        end

        if item["mikuType"] == "NxLambda" then
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::done(item["uuid"])
            return
        end

        if item["mikuType"] == "NxCruiser" then
            return NxCruisers::natural(item)
        end

        if item["mikuType"] == "NxStrat" then
            if !NxBalls::itemIsActive(item) then
                NxBalls::start(item)
                return
            end
            if NxBalls::itemIsActive(item) then
                NxBalls::stop(item)
                if NxStrats::parentOrNull(item) then
                    return
                end
                if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                    DataCenter::destroy(item["uuid"])
                end
                return
            end
        end

        if item["mikuType"] == "NxOndate" then
            if !NxBalls::itemIsActive(item) then
                NxBalls::start(item)
            end
            PolyActions::access(item)
            NxBalls::stop(item)
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                DataCenter::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            if !NxBalls::itemIsActive(item) then
                NxBalls::start(item)
            end
            PolyActions::access(item)
            NxBalls::stop(item)
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                PolyActions::addTimeToItem(item, 300) # cosmological inflation 😄
                DataCenter::destroy(item["uuid"])
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
            NxBalls::stop(item)
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

        if item["mikuType"] == "Wave" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                DataCenter::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxCruiser" then
            if NxCruisers::stack(item).size > 0 then
                puts "You cannot delete '#{PolyFunctions::toString(item).green}' because the stack is not empty"
                LucilleCore::pressEnterToContinue()
                return
            end
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                DataCenter::destroy(item["uuid"])
            end
        end

        if item["mikuType"] == "NxAnniversary" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                DataCenter::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxOndate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                DataCenter::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                PolyActions::addTimeToItem(item, 300) # cosmological inflation 😄
                DataCenter::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxStrat" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                DataCenter::destroy(item["uuid"])
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

        if item["mikuType"] == "NxTask" then
            Catalyst::program1(item)
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
        if item["mikuType"] == "Backup" then
            puts "There is no description edit for Backups (inherited from the file)"
            LucilleCore::pressEnterToContinue()
            return
        end
        puts "edit description:"
        description = CommonUtils::editTextSynchronously(item["description"]).strip
        return if description == ""
        DataCenter::setAttribute(item["uuid"], "description", description)
    end
end
