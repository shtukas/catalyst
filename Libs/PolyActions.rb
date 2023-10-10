
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
            NxOndates::access(item)
            return
        end

        if item["mikuType"] == "NxThread" then
            NxThreads::program1(item)
            return
        end

        if item["mikuType"] == "NxTask" then
            NxTasks::access(item)
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

        # order: alphabetical order

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

        if item["mikuType"] == "NxLong" then
            Catalyst::destroy(item["uuid"])
            return
        end

        if item["mikuType"] == "NxOndate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Catalyst::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                PolyActions::addTimeToItem(item, 300) # cosmological inflation 😄
                Catalyst::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "PhysicalTarget" then
            PhysicalTargets::performUpdate(item)
            return
        end

        if item["mikuType"] == "NxThread" then
            puts "You cannot done a NxThread"
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

        if item["mikuType"] == "Wave" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Catalyst::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxOndate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Catalyst::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Catalyst::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                PolyActions::addTimeToItem(item, 300) # cosmological inflation 😄
                Catalyst::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxThread" then
            if Catalyst::children(item).size > 0 then
                puts "The core '#{PolyFunctions::toString(item).green}' cannot be deleted as it has #{Catalyst::children(item).size} elements"
                LucilleCore::pressEnterToContinue()
                return
            end
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Catalyst::destroy(item["uuid"])
            end
            return
        end

        puts "I do not know how to PolyActions::destroy(#{JSON.pretty_generate(item)})"
        raise "(error: f7ac071e-f2bb-4921-a7f3-22f268b25be8)"
    end

    # PolyActions::doubleDots(item)
    def self.doubleDots(item)

        if item["mikuType"] == "NxAnniversary" then
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxLambda" then
            item["lambda"].call()
            return
        end

        if item["mikuType"] == "Backup" then
            PolyActions::access(item)
            PolyActions::done(item)
            return
        end

        if item["mikuType"] == "NxOndate" then
            PolyFunctions::toString(item).green
            NxBalls::start(item)
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxTask" then
            NxBalls::start(item)
            PolyActions::access(item)
            if LucilleCore::askQuestionAnswerAsBoolean("stop: '#{PolyFunctions::toString(item).green}' ? ", true) then
                NxBalls::stop(item)
            end
            if Catalyst::children(item).empty? and LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                Catalyst::destroy(item["uuid"])
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

        if item["mikuType"] == "NxThread" then
            PolyActions::access(item)
            return
        end

        puts "I don't know how to doubleDots '#{item["mikuType"]}'"
        LucilleCore::pressEnterToContinue()
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
        Updates::itemAttributeUpdate(item["uuid"], "description", description)
    end
end
