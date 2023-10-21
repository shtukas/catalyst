# encoding: UTF-8

class ListingCommandsAndInterpreters

    # ListingCommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | <datecode> | access (<n>) | push (<n>) # do not show until | done (<n>) | program (<n>) | expose (<n>) | add time <n> | coredata (<n>) | skip (<n>) | pile * | deadline (<n>) | unparent <n> | move * | engine *  | thread * | destroy (<n>)",
            "",
            "Transmutations:",
            "              : (task)   >ondate (<n>)",
            "              : (ondate) >task (<n>)",
            "",
            "mikuTypes:",
            "   - NxOndate : redate (*)",
            "   - NxThread : sorting-style (*)",
            "",
            "makers        : anniversary.new | manual-countdown.new | wave.new | today.new | tomorrow.new | ondate.new | task.new | thread.new | desktop | pile | hours of.new",
            "divings       : anniversaries | ondates | waves | desktop | boxes | engined | buffer-ins",
            "NxBalls       : start | start (<n>) | stop | stop (<n>) | pause | pursue",
            "misc          : search | speed | commands | edit <n> | move | >> # move default to Infinity",
        ].join("\n")
    end

    # ListingCommandsAndInterpreters::interpreter(input, store)
    def self.interpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
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
            status = NxThreads::interactivelySelectAndInstallInThread(item)
            return if !status
            Updates::itemAttributeUpdate(item["uuid"], "mikuType", "NxTask")
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
            status = NxThreads::interactivelySelectAndInstallInThread(item)
            return if !status
            Updates::itemAttributeUpdate(item["uuid"], "mikuType", "NxTask")
            return
        end

        if Interpreting::match(">ondate", input) then
            item = store.getDefault()
            return if item.nil?
            if item["mikuType"] != "NxTask" then
                puts "For the moment we only run >ondate on NxTasks"
                LucilleCore::pressEnterToContinue()
                return
            end
            Updates::itemAttributeUpdate(item["uuid"], "description", item["description"].gsub("(buffer-in)", "").strip)
            Updates::itemAttributeUpdate(item["uuid"], "datetime", CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode())
            Updates::itemAttributeUpdate(item["uuid"], "mikuType", "NxOndate")
            return
        end

        if Interpreting::match(">ondate *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["mikuType"] != "NxTask" then
                puts "For the moment we only run >ondate on NxTasks"
                LucilleCore::pressEnterToContinue()
                return
            end
            Updates::itemAttributeUpdate(item["uuid"], "description", item["description"].gsub("(buffer-in)", "").strip)
            Updates::itemAttributeUpdate(item["uuid"], "datetime", CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode())
            Updates::itemAttributeUpdate(item["uuid"], "mikuType", "NxOndate")
            return
        end

        if Interpreting::match("move", input) then
            items = store.items().select{|i| ["NxTask", "NxThread"].include?(i["mikuType"])}
            Catalyst::selectSubsetAndMoveToSelectedThread(items)
            return
        end

        if Interpreting::match("move * ", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if !["NxTask", "NxThread"].include?(item["mikuType"]) then
                puts "We can only move tasks and threads"
                LucilleCore::pressEnterToContinue()
                return
            end
            NxThreads::interactivelySelectAndInstallInThread(item)
            return
        end

        if Interpreting::match("pile * ", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxStrats::interactivelyPile(item)
            return
        end

        if Interpreting::match("hours of.new", input) then
            hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
            targetIndex = LucilleCore::askQuestionAnswerAsString("index: ").to_i
            target = store.get(targetIndex)
            return if target.nil?
            item = NxLifters::issue(target["uuid"], hours)
            puts JSON.pretty_generate(item)
            Ox1s::markAtTop(item)
            return
        end

        if Interpreting::match("today.new", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match(">>", input) then
            item = store.getDefault()
            return if item.nil?
            if !["NxOndate", "NxTask"].include?(item["mikuType"]) then
                puts "We are only threading ondates and tasks"
                LucilleCore::pressEnterToContinue()
                return
            end
            thread = Catalyst::itemOrNull("7cf30bc6-d791-4c0c-b03f-16c728396f22") # Infinity Thread
            raise "(error: 60de96bb-fa67-49df-a924-d938847c9f35)" if thread.nil?
            Updates::itemAttributeUpdate(item["uuid"], "parent-1328", thread["uuid"])
            if item["mikuType"] == "NxOndate" then
                puts "Before moving it, we need to transform the ondate into a task"
                LucilleCore::pressEnterToContinue()
                Updates::itemAttributeUpdate(item["uuid"], "mikuType", "NxTask")
            end
            return
        end

        if Interpreting::match("thread", input) then
            item = store.getDefault()
            return if item.nil?
            if !["NxOndate", "NxTask"].include?(item["mikuType"]) then
                puts "We are only threading ondates and tasks"
                LucilleCore::pressEnterToContinue()
                return
            end
            thread = NxThreads::interactivelySelectOneOrNullUsingTopDownNavigation(nil)
            return if thread.nil?
            Updates::itemAttributeUpdate(item["uuid"], "parent-1328", thread["uuid"])
            if item["mikuType"] == "NxOndate" then
                puts "Before moving it, we need to transform the ondate into a task"
                LucilleCore::pressEnterToContinue()
                Updates::itemAttributeUpdate(item["uuid"], "mikuType", "NxTask")
            end
            return
        end

        if Interpreting::match("thread *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if !["NxOndate", "NxTask"].include?(item["mikuType"]) then
                puts "We are only threading ondates and tasks"
                LucilleCore::pressEnterToContinue()
                return
            end
            thread = NxThreads::interactivelySelectOneOrNullUsingTopDownNavigation(nil)
            return if thread.nil?
            Updates::itemAttributeUpdate(item["uuid"], "parent-1328", thread["uuid"])
            if item["mikuType"] == "NxOndate" then
                puts "Before moving it, we need to transform the ondate into a task"
                LucilleCore::pressEnterToContinue()
                Updates::itemAttributeUpdate(item["uuid"], "mikuType", "NxTask")
            end
            return
        end

        if Interpreting::match("skip", input) then
            item = store.getDefault()
            return if item.nil?
            Updates::itemAttributeUpdate(item["uuid"], "tmpskip1", CommonUtils::today())
            return
        end

        if Interpreting::match("skip *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Updates::itemAttributeUpdate(item["uuid"], "tmpskip1", CommonUtils::today())
            return
        end

        if Interpreting::match("task.new", input) then
            item = NxTasks::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            loop {
                thread = NxThreads::interactivelySelectOneOrNullUsingTopDownNavigation(nil)
                next if thread.nil?
                Updates::itemAttributeUpdate(item["uuid"], "parent-1328", thread["uuid"])
                break
            }
            return
        end

        if Interpreting::match("thread.new", input) then
            item = NxThreads::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
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
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Updates::itemAttributeUpdate(item["uuid"], "parent-1328", nil)
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

        if Interpreting::match("anniversary.new", input) then
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
            Updates::itemAttributeUpdate(item["uuid"], "field11", reference)
            return
        end

        if Interpreting::match("coredata *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            reference =  CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(item["uuid"])
            return if reference.nil?
            Updates::itemAttributeUpdate(item["uuid"], "field11", reference)
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

        if Interpreting::match("engine", input) then
            item = store.getDefault()
            return if item.nil?
            engine = TxEngines::interactivelyMakeNewOrNull()
            return if engine.nil?
            Updates::itemAttributeUpdate(item["uuid"], "engine-0916", engine)
            return
        end

        if Interpreting::match("engine *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            engine = TxEngines::interactivelyMakeNewOrNull()
            return if engine.nil?
            Updates::itemAttributeUpdate(item["uuid"], "engine-0916", engine)
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
            return
        end

        if Interpreting::match("push *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
            return if unixtime.nil?
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
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

        if Interpreting::match("manual-countdown.new", input) then
            PhysicalTargets::issueNewOrNull()
            return
        end

        if Interpreting::match("ondate.new", input) then
            item = NxOndates::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("buffer-ins", input) then
            selector = lambda {
                Catalyst::mikuType("NxTask").select{|item| item["parent-1328"].nil? }
                        .select{|item| item["engine-0916"].nil? }
                        .sort_by{|item| item["unixtime"] || 0 }
            }
            Catalyst::program3(selector)
            return
        end

        if Interpreting::match("engined", input) then
            items = Catalyst::catalystItems()
                        .select{|item| item["mikuType"] != "NxThePhantomMenace" }
                        .select{|item| item["engine-0916"] }
                        .sort_by{|item| TxEngines::listingCompletionRatio(item["engine-0916"]) }
            Catalyst::program2(items)
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

        if Interpreting::match("pile", input) then
            text = CommonUtils::editTextSynchronously("").strip
            return if text == ""
            text
                .lines
                .map{|line| line.strip }
                .reverse
                .each{|line|
                    task = NxTasks::descriptionToTask1(SecureRandom.uuid, line)
                    puts JSON.pretty_generate(task)
                    Ox1s::markAtTop(task["uuid"])
                }
            return
        end

        if Interpreting::match("sort", input) then
            selected, _ = LucilleCore::selectZeroOrMore("ordering", [], store.items(), lambda {|item| PolyFunctions::toString(item) })
            selected.reverse.each{|item|
                Ox1s::markAtTop(item["uuid"])
            }
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

        if Interpreting::match("sorting-style", input) then
            item = store.getDefault()
            return if item.nil?
            if item["mikuType"] != "NxThread" then
                puts "sorting-style is reserved for NxThreads"
                LucilleCore::pressEnterToContinue()
                return
            end
            style = NxThreads::interactivelySelectSortingStyleOrNull()
            return if style.nil?
            Updates::itemAttributeUpdate(item["uuid"], "sorting-style", style)
            return
        end

        if Interpreting::match("sorting-style *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["mikuType"] != "NxThread" then
                puts "sorting-style is reserved for NxThreads"
                LucilleCore::pressEnterToContinue()
                return
            end
            style = NxThreads::interactivelySelectSortingStyleOrNull()
            return if style.nil?
            Updates::itemAttributeUpdate(item["uuid"], "sorting-style", style)
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
            NxBalls::stop(item)
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
            NxBalls::stop(item)
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

        if Interpreting::match("tomorrow.new", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            Updates::itemAttributeUpdate(item["uuid"], "datetime", "#{CommonUtils::nDaysInTheFuture(1)} 07:00:00+00:00")
            return
        end

        if input == "wave.new" then
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
