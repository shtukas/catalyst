# encoding: UTF-8

class CommandsAndInterpreters

    # CommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | <datecode> | access (<n>) | push (<n>) # do not show until | done (<n>) | program (<n>) | expose (<n>) | add time <n> | skip (<n>) | transmute * | stack * | pile * | core * | uncore * | bank accounts * | donation * | move * | payload * | completed * | destroy *",
            "",
            "makers        : anniversary | manual-countdown | wave | today | tomorrow | ondate | todo or task | desktop | project | monitor | priority | stack | mission",
            "divings       : anniversaries | ondates | waves | desktop | projects | engines | missions | backups",
            "NxBalls       : start | start (<n>) | stop | stop (<n>) | pause | pursue",
            "misc          : search | speed | commands | edit <n> | sort | move | unstack * | reload",
        ].join("\n")
    end

    # CommandsAndInterpreters::interpreter(input, store)
    def self.interpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                Ox1::detach(item)
                NxBalls::stop(item)
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

            options = ["project", "UxCore"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            return if option.nil?
            if option == "project" then
                NxProjects::upgradeItemDonations(item)
            end
            if option == "UxCore" then
                uxcore = LucilleCore::selectEntityFromListOfEntitiesOrNull("uxcore", Cubes1::mikuType("UxCore"), lambda{|item| PolyFunctions::toString(item) })
                return if uxcore.nil?
                donation = ((item["donation-1752"] || []) + [uxcore["uuid"]]).uniq
                Cubes2::setAttribute(item["uuid"], "donation-1752", donation)
            end
            return
        end

        if Interpreting::match("reload", input) then
            CoreData::reloadDataFromScratch()
            return
        end

        if Interpreting::match("monitor", input) then
            item = NxProjects::interactivelyIssueMonitorOrNull()
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
            NxProjects::upgradeItemDonations(item)
            if LucilleCore::askQuestionAnswerAsBoolean("start ? ") then
                NxBalls::start(item)
            end
            return
        end

        if Interpreting::match("mission", input) then
            mission = NxMissions::interactivelyIssueNewOrNull()
            return if mission.nil?
            puts JSON.pretty_generate(mission)
            NxProjects::upgradeItemDonations(mission)
            return
        end

        if Interpreting::match("project", input) then
            item = NxProjects::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("projects", input) then
            NxProjects::program2()
            return
        end

        if Interpreting::match("backups", input) then
            items = Cubes2::mikuType("NxBackup").sort_by{|item| item["description"] }
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
                        .sort_by{|item| TxCores::listingCompletionRatio(item["engine-0020"]) }
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
            if item["mikuType"] == "NxProject" then
                NxProjects::pile(item)
                return
            end
            NxStrats::interactivelyPile(item)
            return
        end

        if Interpreting::match("move *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxProjects::interactivelySelectOneAndAddTo(item["uuid"])
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
            NxProjects::selectSubsetOfItemsAndMove(store.items())
            return
        end

        if Interpreting::match("stack", input) then
            text = CommonUtils::editTextSynchronously("").strip
            return if text == ""
            text.lines.reverse.each{|line|
                task = NxTasks::descriptionToTask1(SecureRandom.uuid, line.strip)
                Ox1::putAtTop(task)
                puts "> deciding listing for task: '#{PolyFunctions::toString(task)}'"
                listing = NxProjects::interactivelySelectOneOrNull()
                if listing then
                    Cubes2::setAttribute(task["uuid"], "donation-1752", [listing["uuid"]])
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

        if Interpreting::match("completed *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["mikuType"] == "NxProject" then
                PolyActions::destroy(item)
            end
            return
        end

        if Interpreting::match("today", input) then
            item = NxOndates::interactivelyIssueAtDatetimeNewOrNull(CommonUtils::nowDatetimeIso8601())
            return if item.nil?
            puts JSON.pretty_generate(item)
            NxProjects::upgradeItemDonations(item)
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
                option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["in listing", "with own engine"])
                if option.nil? then
                    if LucilleCore::askQuestionAnswerAsBoolean("You did not specify an option, are you sure you want to leave this tasks without a listing or its own engine ? ", false) then
                        break
                    end
                    next
                end
                if option == "in listing" then
                    NxProjects::interactivelySelectOneAndAddTo(item["uuid"])
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
            puts CommandsAndInterpreters::commands().yellow
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
            MainUserInterface::speedTest()
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
