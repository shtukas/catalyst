# encoding: UTF-8

class CommandsAndInterpreters

    # CommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | <datecode> | access (<n>) | push (<n>) # do not show until | done (<n>) | program (<n>) | expose (<n>) | add time <n> | skip (<n>) | transmute * | stack * | pile * | core * | uncore * | bank accounts * | donation * | move * | payload * | completed * | destroy *",
            "",
            "makers        : anniversary | manual-countdown | wave | today | tomorrow | ondate | todo | desktop | project | priority | stack | ringworld-mission | singular-non-work-quest | timecore",
            "divings       : anniversaries | ondates | waves | desktop | engines | ringworld-missions | singular-non-work-quests | backups | orbitals | uxcores",
            "NxBalls       : start | start (<n>) | stop | stop (<n>) | pause | pursue",
            "misc          : search | speed | commands | edit <n> | sort | move | unstack * | reload | contribution | numbers",
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
            PolyActions::doubledots(item)
            return
        end

        if Interpreting::match(".. *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::doubledots(item)
            return
        end

        if Interpreting::match("donation * ", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Catalyst::interactivelySetDonations(item)
            return
        end

        if Interpreting::match("numbers", input) then

            Cubes2::mikuType("TxTimeCore")
                .each{|core|
                    puts "#{"#{core["description"]}:".ljust(26)} rt: #{"%5.2f" % Bank2::recoveredAverageHoursPerDay(core["uuid"])}, (day completion ratio: #{TxEngines::dayCompletionRatio(core).round(2)})"
                }
            puts "ringworld missions:        rt: #{"%5.2f" % Bank2::recoveredAverageHoursPerDay("3413fd90-cfeb-4a66-af12-c1fc3eefa9ce")}"
            puts "singular non world quests: rt: #{"%5.2f" % Bank2::recoveredAverageHoursPerDay("043c1f2e-3baa-4313-af1c-22c4b6fcb33b")}"
            puts "orbital control:           rt: #{"%5.2f" % Bank2::recoveredAverageHoursPerDay("9f891bc1-ca32-4792-8d66-d66612a4e7c6")}"
            puts "wave control:              rt: #{"%5.2f" % Bank2::recoveredAverageHoursPerDay("67df9561-a0bf-4eb6-b963-a8e6f83f65b6")}"

            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("reload", input) then
            CoreData::reloadDataFromScratch()
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
            item = NxTodos::descriptionToTask1(SecureRandom.hex, line)
            puts JSON.pretty_generate(item)
            Ox1::putAtTop(item)
            NxBalls::activeItems().each{|i1|
                NxBalls::pause(i1)
            }
            Catalyst::interactivelySetDonations(item)
            if LucilleCore::askQuestionAnswerAsBoolean("start ? ") then
                NxBalls::start(item)
            end
            return
        end

        if Interpreting::match("ringworld-mission", input) then
            item = NxRingworldMissions::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            Catalyst::interactivelySetDonations(item)
            return
        end

        if Interpreting::match("singular-non-work-quest", input) then
            item = NxSingularNonWorkQuests::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            Catalyst::interactivelySetDonations(item)
            return
        end

        if Interpreting::match("project", input) then
            item = NxTodos::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("orbitals", input) then
            Catalyst::program2(Cubes2::mikuType("NxOrbital"))
            return
        end

        if Interpreting::match("contribution", input) then
            uxcore = TxTimeCores::interactivelySelectOneOrNull()
            return if uxcore.nil?
            timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours for '#{PolyFunctions::toString(uxcore).green}': ").to_f
            PolyActions::addTimeToItem(uxcore, timeInHours*3600)
            return
        end

        if Interpreting::match("uxcores", input) then
            Catalyst::program2(Cubes2::mikuType("TxTimeCore"))
            return
        end

        if Interpreting::match("backups", input) then
            items = Cubes2::mikuType("NxBackup").sort_by{|item| item["description"] }
            Catalyst::program2(items)
            return
        end

        if Interpreting::match("ringworld-missions", input) then
            items = Cubes2::mikuType("NxRingworldMission")
                        .sort_by{|item| item["lastDoneUnixtime"] }
            Catalyst::program2(items)
            return
        end

        if Interpreting::match("singular-non-work-quests", input) then
            items = Cubes2::mikuType("NxSingularNonWorkQuest")
                        .sort_by{|item| item["unixtime"] }
            Catalyst::program2(items)
            return
        end

        if Interpreting::match("engines", input) then
            items = Cubes2::items()
                        .select{|item| item["engine-0020"] }
                        .sort_by{|item| TxEngines::listingCompletionRatio(item["engine-0020"]) }
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
            if item["mikuType"] == "NxTodo" then
                NxTodos::pile(item)
                return
            end
            NxStrats::interactivelyPile(item)
            return
        end

        if Interpreting::match("move *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            return if item["mikuType"] != "NxTodo"
            target = Catalyst::interactivelySelectNodeOrNull()
            return if target.nil?
            Cubes2::setAttribute(item["uuid"], "parentuuid-0032", target["uuid"])
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
            Catalyst::selectSubsetOfItemsAndMove(store.items())
            return
        end

        if input == "timecore" then
            TxTimeCores::interactivelyMakeNewOrNull()
            return
        end

        if Interpreting::match("stack", input) then
            text = CommonUtils::editTextSynchronously("").strip
            return if text == ""
            text.lines.reverse.each{|line|
                task = NxTodos::descriptionToTask1(SecureRandom.uuid, line.strip)
                Ox1::putAtTop(task)
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
            if item["mikuType"] == "NxTodo" then
                PolyActions::destroy(item)
            end
            return
        end

        if Interpreting::match("today", input) then
            item = NxOndates::interactivelyIssueAtDatetimeNewOrNull(CommonUtils::nowDatetimeIso8601())
            return if item.nil?
            puts JSON.pretty_generate(item)
            Catalyst::interactivelySetDonations(item)
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

        if Interpreting::match("todo", input) then
            options = ["regular tree positioned todo", "ringworld mission", "singular non work quest"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            return if option.nil?
            if option == "regular tree positioned todo" then
                item = NxTodos::interactivelyIssueNewOrNull()
                return if item.nil?
                NxTodos::properlyPositionNewlyCreatedTodo(item)
            end
            if option == "regular tree positioned todo" then
                item = NxRingworldMissions::interactivelyIssueNewOrNull()
                return if item.nil?
                puts JSON.pretty_generate(item)
                Catalyst::interactivelySetDonations(item)
            end
            if option == "singular non work quest" then
                item = NxSingularNonWorkQuests::interactivelyIssueNewOrNull()
                return if item.nil?
                puts JSON.pretty_generate(item)
                Catalyst::interactivelySetDonations(item)
            end
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
            core2 = TxEngines::interactivelyMakeNewOrNull(item["engine-0020"])
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
