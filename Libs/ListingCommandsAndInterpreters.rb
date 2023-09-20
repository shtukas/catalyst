# encoding: UTF-8

class ListingCommandsAndInterpreters

    # ListingCommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | <datecode> | access (<n>) | push (<n>) # do not show until | done (<n>) | program (<n>) | expose (<n>) | add time <n> | coredata (<n>) | position <n> <position> | move (<n>) | holiday <n> | skip | pile (<n>) | deadline (<n>) | core (<n>) | pp (<n>) # postpone | destroy (<n>) | engine (<n>) | engine-null (<n>) | priority (<n>)",
            "",
            "Transmutations: >ondate (on buffer-in)",
            "",
            "makers        : anniversary | manual countdown | wave | today | tomorrow | ondate | desktop | task | netflix | thread | pile | burner | line",
            "divings       : anniversaries | ondates | waves | desktop | boxes | cores",
            "NxBalls       : start | start (<n>) | stop | stop (<n>) | pause | pursue",
            "NxOnDate      : redate",
            "NxThreads     : sort type",
            "misc          : search | speed | commands | edit <n> | sort",
        ].join("\n")
    end

    # ListingCommandsAndInterpreters::interpreter(input, store)
    def self.interpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                DoNotShowUntil::setUnixtime(item, unixtime)
                Listing::removeLstOrd(item)
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

        if Interpreting::match("line", input) then
            line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
            return if line == ""
            line = NxLines::issue(line)
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ")
            Events::publishItemAttributeUpdate(line["uuid"], "list-ord-03", ordinal.to_f)
            return
        end

        if Interpreting::match("sort", input) then
            items = store.items().select{|item| item["mikuType"] != "NxStrat" }
            selected, unselected = LucilleCore::selectZeroOrMore("items", [], items, lambda{|item| PolyFunctions::toString(item) })
            selected
                .reverse
                .each_with_index{|item, indx|
                    Events::publishItemAttributeUpdate(item["uuid"], "list-ord-03", -indx.to_f/100)
                }
            return
        end

        if Interpreting::match("priority *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if !["NxTask", "NxThread"].include?(item["mikuType"]) then
                puts "We only assign priority status to NxTasks and NxThreads"
                LucilleCore::pressEnterToContinue()
                return
            end
            Events::publishItemAttributeUpdate(item["uuid"], "isPriorityTodo-8", true)
            return
        end

        if Interpreting::match("engine *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if !["NxTask", "NxThread"].include?(item["mikuType"]) then
                puts "We only assign TxEngines to NxTasks and NxThreads"
                LucilleCore::pressEnterToContinue()
                return
            end
            engine = TxEngine::interactivelyMakeOrNull()
            return if engine.nil?
            Events::publishItemAttributeUpdate(item["uuid"], "drive-nx1", engine)
            return
        end

        if Interpreting::match("engine-null *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Events::publishItemAttributeUpdate(item["uuid"], "drive-nx1", nil)
            return
        end

        if Interpreting::match("sort type *", input) then
            _, _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["mikuType"] != "NxThread" then
                puts "sort type command only for NxThreads"
                LucilleCore::pressEnterToContinue()
                return
            end
            Events::publishItemAttributeUpdate(item["uuid"], "sortType", NxThreads::interactivelySelectSortType())
            return
        end

        if Interpreting::match("today", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("cores", input) then
            TxCores::program2()
            return
        end

        if Interpreting::match("skip", input) then
            item = store.getDefault()
            return if item.nil?
            Events::publishItemAttributeUpdate(item["uuid"], "tmpskip1", CommonUtils::today())
            return
        end

        if Interpreting::match("netflix", input) then
            title = LucilleCore::askQuestionAnswerAsString("title: ")
            task = NxTasks::descriptionToTask("netflix: #{title}")
            threaduuid = "c7ae8253-0650-478e-9c95-e99f553bc7f3" # netflix viewings thread in Infinity
            Events::publishItemAttributeUpdate(task["uuid"], "lineage-nx128", threaduuid)
            thread = Catalyst::itemOrNull(threaduuid)
            position = NxThreads::newNextPosition(thread)
            Events::publishItemAttributeUpdate(task["uuid"], "coordinate-nx129", position)
            return
        end

        if Interpreting::match("task", input) then
            item = NxTasks::interactivelyIssueNewOrNull()
            Catalyst::moveTaskables([item])
            return
        end

        if Interpreting::match("threads", input) then
            NxThreads::program2()
            return
        end

        if Interpreting::match("core", input) then
            item = store.getDefault()
            return if item.nil?
            puts PolyFunctions::toString(item).green
            core = TxCores::interactivelySelectOneOrNull()
            return if core.nil?
            Events::publishItemAttributeUpdate(item["uuid"], "coreX-2300", core["uuid"])
            if item["description"].include?("(buffer-in)") then
                Events::publishItemAttributeUpdate(item["uuid"], "description", item["description"].gsub("(buffer-in)", "").strip)
            end
            if item["mikuType"] == "NxTask" then
                Events::publishItemAttributeUpdate(item["uuid"], "isPriorityTodo-8", LucilleCore::askQuestionAnswerAsBoolean("is priority ? "))
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
            Events::publishItemAttributeUpdate(item["uuid"], "coreX-2300", core["uuid"])
            if item["description"].include?("(buffer-in)") then
                Events::publishItemAttributeUpdate(item["uuid"], "description", item["description"].gsub("(buffer-in)", "").strip)
            end
            if item["mikuType"] == "NxTask" then
                Events::publishItemAttributeUpdate(item["uuid"], "isPriorityTodo-8", LucilleCore::askQuestionAnswerAsBoolean("is priority ? "))
            end
            return
        end

        if Interpreting::match("move", input) then
            item = store.getDefault()
            return if item.nil?
            puts PolyFunctions::toString(item).green
            Catalyst::moveTaskables([item])
            return
        end

        if Interpreting::match("move *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            puts PolyFunctions::toString(item).green
            Catalyst::moveTaskables([item])
            return
        end

        if Interpreting::match("pp", input) then
            item = store.getDefault()
            return if item.nil?
            Catalyst::postpone(item)
            Listing::removeLstOrd(item)
            return
        end

        if Interpreting::match("pp *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Catalyst::postpone(item)
            Listing::removeLstOrd(item)
            return
        end

        if Interpreting::match("thread", input) then
            thread = NxThreads::interactivelyIssueNewOrNull()
            return if thread.nil?
            NxThreads::program1(thread)
            return
        end

        if Interpreting::match("burner", input) then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return if description == ""
            NxBurners::issue(description)
            return
        end

        if Interpreting::match("pile", input) then
            item = store.getDefault()
            return if item.nil?
            Stratification::pile3(item)
            return
        end

        if Interpreting::match("pile *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Stratification::pile3(item)
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

        if Interpreting::match("position * *", input) then
            _, listord, position = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Events::publishItemAttributeUpdate(item["uuid"], "coordinate-nx129", position.to_f)
        end

        if Interpreting::match("add time *", input) then
            _, _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            puts "adding time for '#{PolyFunctions::toString(item).green}'"
            timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
            PolyActions::addTimeToItem(item, timeInHours*3600)
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
            Events::publishItemAttributeUpdate(item["uuid"], "field11", reference)
            return
        end

        if Interpreting::match("coredata *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            reference =  CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(item["uuid"])
            return if reference.nil?
            Events::publishItemAttributeUpdate(item["uuid"], "field11", reference)
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
            DoNotShowUntil::setUnixtime(item, unixtime)
            Listing::removeLstOrd(item)
            return
        end

        if Interpreting::match("push *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
            return if unixtime.nil?
            DoNotShowUntil::setUnixtime(item, unixtime)
            Listing::removeLstOrd(item)
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

        if Interpreting::match(">ondate", input) then
            item = store.getDefault()
            return if item.nil?
            if !(item["mikuType"] == "NxTask" and item["description"].include?("(buffer-in)")) then
                puts "For the moment we only run >ondate on buffer in NxTasks"
                LucilleCore::pressEnterToContinue()
                return
            end
            Events::publishItemAttributeUpdate(item["uuid"], "description", item["description"].gsub("(buffer-in)", "").strip)
            Events::publishItemAttributeUpdate(item["uuid"], "datetime", CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode())
            Events::publishItemAttributeUpdate(item["uuid"], "mikuType", "NxOndate")
            return
        end


        if Interpreting::match(">ondate *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Events::publishItemAttributeUpdate(item["uuid"], "description", item["description"].gsub("(buffer-in)", "").strip)
            Events::publishItemAttributeUpdate(item["uuid"], "datetime", CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode())
            Events::publishItemAttributeUpdate(item["uuid"], "mikuType", "NxOndate")
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
            Events::publishItemAttributeUpdate(item["uuid"], "datetime", "#{CommonUtils::nDaysInTheFuture(1)} 07:00:00+00:00")
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
