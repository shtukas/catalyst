# encoding: UTF-8

class ListingCommandsAndInterpreters

    # ListingCommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | <datecode> | access (<n>) | do not show until <n> | done (<n>) | program (<n>) | expose (<n>) | add time <n> | engine (<n>) | note (<n>) | coredata <n> | tx8 (<n>) | holiday <n> | skip | engine (<n>) | cloud (<n>) | position (<n>) | reorganise <n> | pile (<n>) | destroy (<n>)",
            "",
            "specific types commands:",
            "    - OnDate  : redate",
            "    - NxTask  : stack (<n>)",
            "    - NxBurner: ack",
            "transmutation : >> (<n>)",
            "makers        : anniversary | manual countdown | wave | today | tomorrow | ondate | desktop | task | fire | burner | time | times | engine | thread",
            "makers (sc)   : jedi | netflix",
            "divings       : anniversaries | ondates | waves | burners | desktop | engines",
            "NxBalls       : start | start * | stop | stop * | pause | pursue",
            "misc          : search | speed | commands | mikuTypes | edit <n> | inventory | reschedule",
        ].join("\n")
    end

    # ListingCommandsAndInterpreters::interpreter(input, store)
    def self.interpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                DoNotShowUntil::setUnixtime(item, unixtime)
                return
            end
        end

        if Interpreting::match("..", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::doubleDot(item)
            return
        end

        if Interpreting::match(".. *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::doubleDot(item)
            return
        end

        if Interpreting::match("skip", input) then
            item = store.getDefault()
            return if item.nil?
            TmpSkip1::tmpskip1(item, 1)
            return
        end

        if Interpreting::match("mikutypes", input) then
            puts JSON.pretty_generate(DarkEnergy::all().map{|item| item["mikuType"] }.uniq.sort)
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("reschedule", input) then
            NxTimes::reschedule()
            return
        end

        if Interpreting::match("burners", input) then
            NxBurners::program2()
            return
        end

        if Interpreting::match("drop", input) then
            NxDrops::interactivelyIssueNewOrNull()
            return
        end

        if Interpreting::match("thread", input) then
            thread = NxThreads::interactivelyIssueNewOrNull()
            return if thread.nil?
            puts JSON.pretty_generate(thread)
            return
        end

        if Interpreting::match("engines", input) then
            NxEngines::program()
            return
        end

        if Interpreting::match("reorganise *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Tx8s::reorganise(item)
            return
        end

        if Interpreting::match("move", input) then
            item = store.getDefault()
            return if item.nil?
            DarkEnergy::patch(item["uuid"], "parent", Tx8s::selectCoreAndMakeTx8OrNull())
            return
        end

        if Interpreting::match("move *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            DarkEnergy::patch(item["uuid"], "parent", Tx8s::selectCoreAndMakeTx8OrNull())
            return
        end

        if Interpreting::match("pile", input) then
            item = store.getDefault()
            return if item.nil?
            NxTasks::pile(item)
            return
        end

        if Interpreting::match("pile *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxTasks::pile(item)
            return
        end

        if Interpreting::match("context", input) then
            item = store.getDefault()
            return if item.nil?
            Tx8s::interactivelyDecideAndSetParent(item)
            return
        end

        if Interpreting::match("context *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Tx8s::interactivelyDecideAndSetParent(item)
            return
        end

        if Interpreting::match("engine", input) then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["set engine at default item", "create new engine"])
            return if option.nil?
            if option == "set engine at default item" then
                item = store.getDefault()
                return if item.nil?
                NxEngines::interactivelySetEngineAttempt(item)
                return
            end
            if option == "create new engine" then
                engine = NxEngines::interactivelyIssueNewOrNull()
                return if engine.nil?
                puts JSON.pretty_generate(engine)
                return
            end
        end

        if Interpreting::match("engine *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxEngines::interactivelySetEngineAttempt(item)
            return
        end

        if Interpreting::match("engines", input) then
            NxEngines::program()
            return
        end

        if Interpreting::match("ack", input) then
            item = store.getDefault()
            return if item.nil?
            if item["mikuType"] != "NxBurner" then
                puts "Only NxBurners can be ack"
                LucilleCore::pressEnterToContinue()
                return
            end
            item["ackDay"] = CommonUtils::today()
            DarkEnergy::commit(item)
            return
        end

        if Interpreting::match("jedi", input) then
            engineuuid = "586d478d-0a04-40b7-aad3-fa5cbd2c45e4"
            item = NxTasks::interactivelyIssueNewOrNull()
            DarkEnergy::patch(item["uuid"], "parent", Tx8s::make(engineuuid, rand))
            return
        end

        if Interpreting::match("holiday", input) then
            item = store.getDefault()
            return if item.nil?
            unixtime = CommonUtils::codeToUnixtimeOrNull("+++")
            DoNotShowUntil::setUnixtime(item, unixtime)
            return
        end

        if Interpreting::match("holiday *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            unixtime = CommonUtils::codeToUnixtimeOrNull("+++")
            DoNotShowUntil::setUnixtime(item, unixtime)
            return
        end

        if Interpreting::match("add time *", input) then
            _, _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
            PolyActions::addTimeToItem(item, timeInHours*3600)
        end

        if Interpreting::match("inventory", input) then
            puts TheLine::line()
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("access", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::access(item)
            return
        end

        if Interpreting::match("project", input) then
            NxLongs::interactivelyIssueNewOrNull()
            return
        end

        if Interpreting::match("projects", input) then
            NxLongs::program1()
            return
        end

        if Interpreting::match("time", input) then
            item = NxTimes::interactivelyIssueTimeOrNull()
            puts JSON.pretty_generate(item)
            puts PolyFunctions::toString(item)
            NxEngines::interactivelySetEngineAttempt(item)
            return
        end

        if Interpreting::match("times", input) then
            loop {
                puts ""
                item = NxTimes::interactivelyIssueTimeOrNull()
                return if item.nil?
                puts JSON.pretty_generate(item)
                puts PolyFunctions::toString(item)
                NxEngines::interactivelySetEngineAttempt(item)
            }
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

        if Interpreting::match("coredata *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            reference =  CoreData::interactivelyMakeNewReferenceStringOrNull()
            return if reference.nil?
            DarkEnergy::patch(item["uuid"], "field11", reference)
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
            item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
            item.to_a.each{|key, value|
                DarkEnergy::patch(item["uuid"], key, value)
            }
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

        if Interpreting::match("do not show until *", input) then
            _, _, _, _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
            return if unixtime.nil?
            DoNotShowUntil::setUnixtime(item, unixtime)
            return
        end

        if Interpreting::match("position", input) then
            item = store.getDefault()
            return if item.nil?
            Tx8s::repositionItemAtSameParent(item)
            return
        end

        if Interpreting::match("position *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Tx8s::repositionItemAtSameParent(item)
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

        if Interpreting::match("task", input) then
            task = NxTasks::interactivelyIssueNewOrNull()
            return if task.nil?
            puts JSON.pretty_generate(task)
            Tx8s::interactivelyDecideAndSetParent(task)
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

        if Interpreting::match("note", input) then
            item = store.getDefault()
            return if item.nil?
            NxNotes::edit(item)
            return
        end

        if Interpreting::match("note *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxNotes::edit(item)
            return
        end

        if Interpreting::match("ondate", input) then
            item = NxOndates::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ondates", input) then
            NxOndates::program()
            return
        end

        if Interpreting::match("fire", input) then
            item = NxFires::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("burner", input) then
            item = NxBurners::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
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

        if Interpreting::match(">>", input) then
            item = store.getDefault()
            return if item.nil?
            Transmutations::transmute(item)
            return
        end

        if Interpreting::match(">> *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Transmutations::transmute(item)
            return
        end

        if Interpreting::match("start", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::start(item)
            return
        end

        if Interpreting::match("start *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::start(item)
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

        if Interpreting::match("today", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("tomorrow", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            DarkEnergy::patch(item["uuid"], "datetime", "#{CommonUtils::nDaysInTheFuture(1)} 07:00:00+00:00")
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
