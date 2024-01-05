# encoding: UTF-8

class ListingCommandsAndInterpreters

    # ListingCommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | <datecode> | access (<n>) | push (<n>) # do not show until | done (<n>) | program (<n>) | expose (<n>) | add time <n> | skip (<n>) | transmute * | stack * | pile * | core * | uncore * | bank accounts * | donation * | move * | payload * | destroy *",
            "",
            "makers        : anniversary | manual-countdown | wave | today | tomorrow | ondate | todo or task | desktop | block | monitor | priority | stack | mission",
            "divings       : anniversaries | ondates | waves | desktop | blocks | monitors | engines | missions",
            "NxBalls       : start | start (<n>) | stop | stop (<n>) | pause | pursue",
            "misc          : search | speed | commands | edit <n> | sort | move | unstack * | reload",
        ].join("\n")
    end

    # ListingCommandsAndInterpreters::interpreter(input, store)
    def self.interpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                Ox1::detach(item)
                DoNotShowUntil2::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        if Interpreting::match("..", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::natural(item)
            return
        end

        if Interpreting::match(".. *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::natural(item)
            return
        end

        if Interpreting::match("donation * ", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            blocks = NxBlocks::selectZeroOrMore()
            donation = ((item["donation-1752"] || []) + blocks.map{|block| block["uuid"] }).uniq
            Cubes2::setAttribute(item["uuid"], "donation-1752", donation)
            return
        end

        if Interpreting::match("reload", input) then
            CoreData::reloadDataFromScratch()
            return
        end

        if Interpreting::match("monitor", input) then
            item = NxMonitors::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("bank accounts *", input) then
            _, _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            puts JSON.pretty_generate(PolyFunctions::itemToBankingAccounts(item))
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("priority", input) then
            line = LucilleCore::askQuestionAnswerAsString("description: ")
            return if line == ""
            item = NxTasks::descriptionToTask1(SecureRandom.hex, line)
            puts JSON.pretty_generate(item)
            Ox1::putAtTop(item)
            NxBalls::activeItems().each{|i1|
                NxBalls::pause(i1)
            }
            NxBlocks::interactivelySelectBlockAndAddTo(item["uuid"])
            if LucilleCore::askQuestionAnswerAsBoolean("start ? ") then
                NxBalls::start(item)
            end
            return
        end

        if Interpreting::match("mission", input) then
            mission = NxMissions::interactivelyIssueNewOrNull()
            return if mission.nil?
            puts JSON.pretty_generate(mission)
            NxBlocks::interactivelySelectBlockAndAddTo(mission["uuid"])
            return
        end

        if Interpreting::match("block", input) then
            item = NxBlocks::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("blocks", input) then
            NxBlocks::program2()
            return
        end

        if Interpreting::match("monitors", input) then
            items = Cubes2::mikuType("NxMonitor").sort_by{|item| item["datetime"] }
            Catalyst::program2(items)
            return
        end

        if Interpreting::match("missions", input) then
            items = Cubes2::mikuType("NxMission")
                        .sort_by{|item| item["lastDoneUnixtime"] }
            Catalyst::program2(items)
            return
        end

        if Interpreting::match("engines", input) then
            items = Cubes2::items()
                        .select{|item| item["engine-0020"] }
                        .sort_by{|item| TxCores::coreDayCompletionRatio(item["engine-0020"]) }
            Catalyst::program2(items)
            return
        end

        if Interpreting::match("transmute *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Transmutations::transmute1(item)
            return
        end

        if Interpreting::match("pile *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["mikuType"] == "NxBlock" then
                NxBlocks::pile(item)
                return
            end
            NxStrats::interactivelyPile(item)
            return
        end

        if Interpreting::match("move *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxBlocks::interactivelySelectBlockAndAddTo(item["uuid"])
            return
        end

        if Interpreting::match("payload *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            TxPayload::edit(item)
            return
        end

        if input == "move" then
            NxBlocks::selectSubsetAndMoveToSelectedBlock(store.items())
            return
        end

        if Interpreting::match("stack", input) then
            text = CommonUtils::editTextSynchronously("").strip
            return if text == ""
            text.lines.reverse.each{|line|
                task = NxTasks::descriptionToTask1(SecureRandom.uuid, line.strip)
                Ox1::putAtTop(task)
                puts "> deciding block for task: '#{PolyFunctions::toString(task)}'"
                block = NxBlocks::interactivelySelectBlockUsingTopDownNavigationOrNull()
                if block then
                    Cubes2::setAttribute(task["uuid"], "donation-1752", [block["uuid"]])
                end
            }
            return
        end

        if Interpreting::match("stack *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Ox1::putAtTop(item)
        end

        if Interpreting::match("unstack *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Ox1::detach(item)
            return
        end

        if Interpreting::match("today", input) then
            item = NxOndates::interactivelyIssueAtDatetimeNewOrNull(CommonUtils::nowDatetimeIso8601())
            return if item.nil?
            puts JSON.pretty_generate(item)
            NxBlocks::interactivelySelectBlockAndAddTo(item["uuid"])
            return
        end

        if Interpreting::match("sort", input) then
            selected, _ = LucilleCore::selectZeroOrMore("item", [], store.items(), lambda{|item| PolyFunctions::toString(item) })
            selected.reverse.each{|item|
                Ox1::putAtTop(item)
            }
            return
        end

        if Interpreting::match("skip", input) then
            item = store.getDefault()
            return if item.nil?
            Cubes2::setAttribute(item["uuid"], "skip-0843", Time.new.to_i+3600*2)
            return
        end

        if Interpreting::match("skip *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Cubes2::setAttribute(item["uuid"], "skip-0843", Time.new.to_i+3600*2)
            return
        end

        if Interpreting::match("todo", input) or Interpreting::match("task", input) then
            item = NxTasks::interactivelyIssueNewOrNull()
            return if item.nil?
            option = nil
            loop {
                option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["cargo of block", "with own engine"])
                if option.nil? then
                    if LucilleCore::askQuestionAnswerAsBoolean("You did not specify an option, are you sure you want to leave this tasks without a block or its own engine ? ", false) then
                        break
                    end
                    next
                end
                if option == "cargo of block" then
                    block = NxBlocks::interactivelySelectBlockUsingTopDownNavigationOrNull()
                    next if block.nil?
                    Cubes2::setAttribute(item["uuid"], "parentuuid-0032", block["uuid"])
                    return
                end
                if option == "with own engine" then
                    core = TxCores::interactivelyMakeNew()
                    next if core.nil?
                    Cubes2::setAttribute(item["uuid"], "engine-0020", core)
                    return
                end
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

        if Interpreting::match("core *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            puts "setting core for '#{PolyFunctions::toString(item).green}'"
            if item["mikuType"] == "NxOndate" or item["mikuType"] == "NxMonitor" then
                puts "You are adding a core to a #{item["mikuType"]}"
                if LucilleCore::askQuestionAnswerAsBoolean("Would you like to transmute it to a NxBlock ? ") then
                    Transmutations::transmute2(item, "NxBlock")
                    item = Cubes2::itemOrNull(item["uuid"])
                    return
                end
            end
            core2 = TxCores::interactivelyMakeNewOrNull(item["engine-0020"])
            return if core2.nil?
            Cubes2::setAttribute(item["uuid"], "engine-0020", core2)
            return
        end

        if Interpreting::match("uncore *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Cubes2::setAttribute(item["uuid"], "engine-0020", nil)
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
            NxBalls::stop(item)
            DoNotShowUntil2::setUnixtime(item["uuid"], unixtime)
            return
        end

        if Interpreting::match("push *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
            return if unixtime.nil?
            NxBalls::stop(item)
            DoNotShowUntil2::setUnixtime(item["uuid"], unixtime)
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

        if Interpreting::match("manual-countdown", input) then
            PhysicalTargets::issueNewOrNull()
            return
        end

        if Interpreting::match("ondate", input) then
            item = NxOndates::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("actives", input) then
            items = Cubes2::items()
                        .select{|item| item["active"] }
            Catalyst::program2(items)
            return
        end

        if Interpreting::match("ondates", input) then
            elements = Cubes2::mikuType("NxOndate").sort_by{|item| item["datetime"] }
            Catalyst::program2(elements)
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

        if Interpreting::match("redate *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxBalls::stop(item)
            datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
            Cubes2::setAttribute(item["uuid"], "datetime", datetime)
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
            if item["ordinal-1051"] then
                Cubes2::setAttribute(item["uuid"], "ordinal-1051", nil)
            end
            NxBalls::stop(item)
            return
        end

        if Interpreting::match("stop *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["ordinal-1051"] then
                Cubes2::setAttribute(item["uuid"], "ordinal-1051", nil)
            end
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
            item = NxOndates::interactivelyIssueAtDatetimeNewOrNull(CommonUtils::tomorrow())
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if input == "wave" then
            item = Waves::issueNewWaveInteractivelyOrNull(SecureRandom.uuid)
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
