# encoding: UTF-8

class ListingCommandsAndInterpreters

    # ListingCommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | <datecode> | access (<n>) | push (<n>) # do not show until | done (<n>) | program (<n>) | expose (<n>) | add time <n> | coredata (<n>) | skip (<n>) | pile (<n>) | deadline (<n>) | core (<n>) | unstack (<n>) | active (<n>) | unparent <n> | engine * | engine-no * | red (*) | unred (*)  | destroy (<n>)",
            "",
            "Transmutations:",
            "              : (task)   >ondate (<n>)",
            "              : (ondate) >task (<n>)",
            "",
            "makers        : anniversary | manual countdown | wave | today | tomorrow | ondate | desktop | task | stack | stack * | pile",
            "divings       : anniversaries | ondates | waves | desktop | boxes | cores | engined | actives",
            "NxBalls       : start | start (<n>) | stop | stop (<n>) | pause | pursue",
            "NxOnDate      : redate",
            "NxTask        : red (<n>)",
            "misc          : search | speed | commands | edit <n> | sort | move | rise",
        ].join("\n")
    end

    # ListingCommandsAndInterpreters::interpreter(input, store)
    def self.interpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                DxStack::unregister(item)
                return
            end
        end

        if Interpreting::match("..", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::doubleDots(item)
            return
        end

        if Interpreting::match(".. *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::doubleDots(item)
            return
        end

        if Interpreting::match(">task", input) then
            item = store.getDefault()
            return if item.nil?
            if item["mikuType"] != "NxOndate" then
                puts "For the moment we only run >task on buffer in NxOndates"
                LucilleCore::pressEnterToContinue()
                return
            end
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "mikuType", "NxTask")
            return
        end

        if Interpreting::match(">task *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["mikuType"] != "NxOndate" then
                puts "For the moment we only run >task on buffer in NxOndates"
                LucilleCore::pressEnterToContinue()
                return
            end
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "mikuType", "NxTask")
            return
        end

        if Interpreting::match(">ondate", input) then
            item = store.getDefault()
            return if item.nil?
            if !item["mikuType"] != "NxTask" then
                puts "For the moment we only run >ondate on NxTasks"
                LucilleCore::pressEnterToContinue()
                return
            end
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "description", item["description"].gsub("(buffer-in)", "").strip)
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "datetime", CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode())
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "mikuType", "NxOndate")
            return
        end

        if Interpreting::match(">ondate *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if !item["mikuType"] != "NxTask" then
                puts "For the moment we only run >ondate on NxTasks"
                LucilleCore::pressEnterToContinue()
                return
            end
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "description", item["description"].gsub("(buffer-in)", "").strip)
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "datetime", CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode())
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "mikuType", "NxOndate")
            return
        end

        if Interpreting::match("move", input) then
            Catalyst::selectSubsetAndMoveToSelectedParent(store.items())
            return
        end

        if Interpreting::match("engined", input) then
            Catalyst::program2(Catalyst::enginedInOrder())
            return
        end

        if Interpreting::match("cores", input) then
            TxCores::program2()
            return
        end

        if Interpreting::match("rise", input) then
            # 1. select some items
            # 2. sort them

            puts "Select what to do today (order doesn't matter)"
            sleep 2
            i2s, _ = LucilleCore::selectZeroOrMore("items", [], store.items(), lambda{|item| PolyFunctions::toString(item) })
            return if i2s.size == 0
            puts "You have selected #{i2s.size} items. Now putting them in order"
            sleep 2

            i3s, _ = LucilleCore::selectZeroOrMore("items", [], i2s, lambda{|item| PolyFunctions::toString(item) })

            (i3s + i2s)
                .reduce([]){|selected, item|
                    if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                        selected
                    else
                        selected + [item]
                    end
                }
                .reverse
                .each{|item|
                    Broadcasts::publishItemAttributeUpdate(item["uuid"], "stack-0012", [CommonUtils::today(), DxStack::newFirstPosition()])
                }
            return
        end

        if Interpreting::match("today", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("unred", input) then
            item = store.getDefault()
            return if item.nil?
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "red-2029", false)
            return
        end

        if Interpreting::match("unred *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "red-2029", false)
            return
        end

        if Interpreting::match("red", input) then
            item = store.getDefault()
            return if item.nil?
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "red-2029", true)
            return
        end

        if Interpreting::match("red *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "red-2029", true)
            return
        end

        if Interpreting::match("skip", input) then
            item = store.getDefault()
            return if item.nil?
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "tmpskip1", CommonUtils::today())
            return
        end

        if Interpreting::match("skip *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "tmpskip1", CommonUtils::today())
            return
        end

        if Interpreting::match("task", input) then
            item = NxTasks::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            Catalyst::setDrivingForce(item)
            return
        end

        if Interpreting::match("core", input) then
            item = store.getDefault()
            return if item.nil?
            puts PolyFunctions::toString(item).green
            core = TxCores::interactivelySelectOneOrNull()
            return if core.nil?
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "coreX-2300", core["uuid"])
            if item["description"].include?("(buffer-in)") then
                Broadcasts::publishItemAttributeUpdate(item["uuid"], "description", item["description"].gsub("(buffer-in)", "").strip)
            end
            return
        end

        if Interpreting::match("core *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            puts PolyFunctions::toString(item).green
            core = TxCores::interactivelySelectOneOrNull()
            return if core.nil?
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "coreX-2300", core["uuid"])
            if item["description"].include?("(buffer-in)") then
                Broadcasts::publishItemAttributeUpdate(item["uuid"], "description", item["description"].gsub("(buffer-in)", "").strip)
            end
            return
        end

        if Interpreting::match("engine *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if !["NxTask"].include?(item["mikuType"]) then
                puts "For the moment we only give TxEngines to tasks"
                LucilleCore::pressEnterToContinue()
                return
            end
            engine = TxEngine::interactivelyMakeOrNull()
            return if engine.nil?
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "engine-2251", engine)
            return
        end

        if Interpreting::match("engine-no *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "engine-2251", nil)
            return
        end

        if Interpreting::match("actives", input) then
            Catalyst::program2(Catalyst::red())
            return
        end

        if Interpreting::match("stack", input) then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return if description == ""
            task = NxTasks::descriptionToTask1(Time.new.to_f.to_s, description)
            position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
            Broadcasts::publishItemAttributeUpdate(task["uuid"], "stack-0012", [CommonUtils::today(), position])
            return
        end

        if Interpreting::match("stack *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "stack-0012", [CommonUtils::today(), position])
            return
        end

        if Interpreting::match("unstack", input) then
            item = store.getDefault()
            return if item.nil?
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "stack-0012", nil)
            return
        end

        if Interpreting::match("unstack *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "stack-0012", nil)
            return
        end

        if Interpreting::match("pile", input) then
            DxStack::pile3()
            return
        end

        if Interpreting::match("sort", input) then
            items = store.items()
            selected, _ = LucilleCore::selectZeroOrMore("items", [], items, lambda{|item| "#{DxStack::prefix(item)}#{PolyFunctions::toString(item)}" })
            selected.reverse.each{|item|
                Broadcasts::publishItemAttributeUpdate(item["uuid"], "stack-0012", [CommonUtils::today(), DxStack::newFirstPosition()])
            }
            return
        end

        if Interpreting::match("add time *", input) then
            _, _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            puts "adding time for '#{PolyFunctions::toString(item).green}'"
            timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
            PolyActions::addTimeToItem(item, timeInHours*3600)
        end

        if Interpreting::match("unparent *", input) then
            item = store.get(listord.to_i)
            return if item.nil?
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "parent-1328", nil)
            return
        end

        if Interpreting::match("access", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::access(item)
            return
        end

        if Interpreting::match("access *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::access(item)
            return
        end

        if Interpreting::match("anniversary", input) then
            Anniversaries::issueNewAnniversaryOrNullInteractively()
            return
        end

        if Interpreting::match("anniversaries", input) then
            Anniversaries::program2()
            return
        end

        if Interpreting::match("coredata", input) then
            item = store.getDefault()
            return if item.nil?
            reference =  CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(item["uuid"])
            return if reference.nil?
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "field11", reference)
            return
        end

        if Interpreting::match("coredata *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            reference =  CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(item["uuid"])
            return if reference.nil?
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "field11", reference)
            return
        end

        if Interpreting::match("commands", input) then
            puts ListingCommandsAndInterpreters::commands().yellow
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("description", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::editDescription(item)
            return
        end

        if Interpreting::match("description *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::editDescription(item)
            return
        end

        if Interpreting::match("edit *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Catalyst::editItem(item)
            return
        end

        if Interpreting::match("desktop", input) then
            system("open '#{Desktop::filepath()}'")
            return
        end

        if Interpreting::match("done", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::done(item)
            return
        end

        if Interpreting::match("done *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::done(item)
            return
        end

        if Interpreting::match("destroy", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::destroy(item)
            return
        end

        if Interpreting::match("destroy *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::destroy(item)
            return
        end

        if Interpreting::match("push", input) then
            item = store.getDefault()
            return if item.nil?
            unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
            return if unixtime.nil?
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            DxStack::unregister(item)
            return
        end

        if Interpreting::match("push *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
            return if unixtime.nil?
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            DxStack::unregister(item)
            return
        end

        if Interpreting::match("expose", input) then
            item = store.getDefault()
            return if item.nil?
            puts JSON.pretty_generate(item)
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("expose *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            puts JSON.pretty_generate(item)
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("program", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::program(item)
            return
        end

        if Interpreting::match("program *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::program(item)
            return
        end

        if Interpreting::match("manual countdown", input) then
            PhysicalTargets::issueNewOrNull()
            return
        end

        if Interpreting::match("ondate", input) then
            item = NxOndates::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ondates", input) then
            items = Catalyst::mikuType("NxOndate")
                        .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            Catalyst::program2(items)
            return
        end

        if Interpreting::match("pause", input) then
            item = store.getDefault()
            return if item.nil?
            NxBalls::pause(item)
            return
        end

        if Interpreting::match("pause *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxBalls::pause(item)
            return
        end

        if Interpreting::match("pursue", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::pursue(item)
            return
        end

        if Interpreting::match("pursue *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::pursue(item)
            return
        end

        if Interpreting::match("redate", input) then
            item = store.getDefault()
            return if item.nil?
            if item["mikuType"] != "NxOndate" then
                puts "redate is reserved for NxOndates"
                LucilleCore::pressEnterToContinue()
                return
            end
            NxOndates::redate(item)
            return
        end

        if Interpreting::match("redate *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["mikuType"] != "NxOndate" then
                puts "redate is reserved for NxOndates"
                LucilleCore::pressEnterToContinue()
                return
            end
            NxOndates::redate(item)
            return
        end

        if Interpreting::match("start", input) then
            item = store.getDefault()
            return if item.nil?
            NxBalls::start(item)
            return
        end

        if Interpreting::match("start *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxBalls::start(item)
            return
        end

        if Interpreting::match("stop", input) then
            item = store.getDefault()
            return if item.nil?
            NxBalls::stop(item)
            return
        end

        if Interpreting::match("stop *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxBalls::stop(item)
            return
        end

        if Interpreting::match("search", input) then
            CatalystSearch::run()
            return
        end

        if Interpreting::match("speed", input) then
            Listing::speedTest()
            return
        end

        if Interpreting::match("tomorrow", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "datetime", "#{CommonUtils::nDaysInTheFuture(1)} 07:00:00+00:00")
            return
        end

        if input == "wave" then
            item = Waves::issueNewWaveInteractivelyOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if input == "waves" then
            Waves::program1()
            return
        end

        if Interpreting::match("speed", input) then
            LucilleCore::pressEnterToContinue()
            return
        end
    end
end
