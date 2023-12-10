# encoding: UTF-8

class ListingCommandsAndInterpreters

    # ListingCommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | <datecode> | access (<n>) | push (<n>) # do not show until | done (<n>) | program (<n>) | expose (<n>) | add time <n> | coredata (<n>) | skip (<n>) | note * | transmute * | pile * | core * | bank accounts * | donation * | booster * | destroy *",
            "",
            "makers        : anniversary | manual-countdown | wave | today | tomorrow | ondate | todo | todo+booster | desktop | pile | ship | sticky | priority | stack",
            "divings       : anniversaries | ondates | waves | desktop | ships | stickies",
            "NxBalls       : start | start (<n>) | stop | stop (<n>) | pause | pursue",
            "misc          : search | speed | commands | edit <n> | sort | move | unstack",
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
            ships = NxCruisers::selectZeroOrMore()
            donation = ((item["donation-1752"] || []) + ships.map{|ship| ship["uuid"] }).uniq
            DataCenter::setAttribute(item["uuid"], "donation-1752", donation)
            return
        end

        if Interpreting::match("sticky", input) then
            item = NxStickies::interactivelyIssueNewOrNull()
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
            task = NxTasks::descriptionToTask1(SecureRandom.hex, line)
            puts JSON.pretty_generate(task)
            Ox1::putAtTop(task)
            NxBalls::activeItems().each{|i1|
                NxBalls::pause(i1)
            }
            NxCruisers::interactivelySelectShipAndAddTo(item)
            if LucilleCore::askQuestionAnswerAsBoolean("start ? ") then
                NxBalls::start(task)
            end
            return
        end

        if Interpreting::match("ship", input) then
            item = NxCruisers::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ships", input) then
            NxCruisers::program2()
            return
        end

        if Interpreting::match("pile", input) then
            item = store.items().first
            return if item.nil?
            if item["mikuType"] == "NxTask" then
                parent = NxTasks::getParentOrNull(item)
                if parent then
                    if parent["mikuType"] == "NxCruiser" then
                        NxCruisers::pile(parent)
                        return
                    end
                end
            end
            if item["mikuType"] == "NxCruiser" then
                NxCruisers::pile(item)
                return
            end
            NxStrats::interactivelyPile(item)
            return
        end

        if Interpreting::match("stickies", input) then
            items = DataCenter::mikuType("NxSticky").sort_by{|item| item["datetime"] }
            Catalyst::program2(items)
            return
        end

        if Interpreting::match("note *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            note = item["note-1531"] || ""
            note = CommonUtils::editTextSynchronously(note)
            DataCenter::setAttribute(item["uuid"], "note-1531", note)
            return
        end

        if Interpreting::match("transmute *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Transmutations::transmute(item)
            return
        end

        if Interpreting::match("pile *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["mikuType"] == "NxCruiser" then
                NxCruisers::pile(item)
                return
            end
            NxStrats::interactivelyPile(item)
            return
        end

        if input == "move" then
            NxCruisers::selectSubsetAndMoveToSelectedShip(store.items())
            return
        end

        if Interpreting::match("stack", input) then
            text = CommonUtils::editTextSynchronously("").strip
            return if text == ""
            text.lines.reverse.each{|line|
                task = NxTasks::descriptionToTask1(SecureRandom.uuid, line.strip)
                Ox1::putAtTop(task)
                puts "> deciding ship for task: '#{PolyFunctions::toString(task)}'"
                ship = NxCruisers::interactivelySelectOneOrNull()
                if ship then
                    DataCenter::setAttribute(task["uuid"], "donation-1752", [ship["uuid"]])
                end
            }
            return
        end

        if Interpreting::match("unstack", input) then
            item = store.items().first
            return if item.nil?
            Ox1::detach(item)
            return
        end

        if Interpreting::match("today", input) then
            item = NxOndates::interactivelyIssueAtDatetimeNewOrNull(CommonUtils::nowDatetimeIso8601())
            return if item.nil?
            puts JSON.pretty_generate(item)
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
            DataCenter::setAttribute(item["uuid"], "skip-0843", Time.new.to_i+3600*2)
            return
        end

        if Interpreting::match("skip *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            DataCenter::setAttribute(item["uuid"], "skip-0843", Time.new.to_i+3600*2)
            return
        end

        if Interpreting::match("booster *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            booster = TxCores::interactivelyMakeBoosterOrNull()
            return if booster.nil?
            engine = [booster] + (item["engine-0020"] || [])
            DataCenter::setAttribute(item["uuid"], "engine-0020", engine)
            return
        end

        if Interpreting::match("todo+booster", input) then
            item = NxTasks::interactivelyIssueNewOrNull()
            return if item.nil?
            booster = TxCores::interactivelyMakeBoosterOrNull()
            if booster then
                DataCenter::setAttribute(item["uuid"], "engine-0020", [booster])
            end
            NxCruisers::interactivelySelectShipAndAddTo(item)
            return
        end

        if Interpreting::match("todo", input) then
            item = NxTasks::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            NxCruisers::interactivelySelectShipAndAddTo(item)
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
            core = TxCores::interactivelyMakeNewOrNull()
            return if core.nil?
            if core["type"] == "booster" then
                engine = [core] + (item["engine-0020"] || [])
                DataCenter::setAttribute(item["uuid"], "engine-0020", engine)
            else
                DataCenter::setAttribute(item["uuid"], "engine-0020", [core])
            end
            return
        end

        if Interpreting::match("coredata", input) then
            item = store.getDefault()
            return if item.nil?
            reference =  CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(item["uuid"])
            return if reference.nil?
            DataCenter::setAttribute(item["uuid"], "field11", reference)
            return
        end

        if Interpreting::match("coredata *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            reference =  CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(item["uuid"])
            return if reference.nil?
            DataCenter::setAttribute(item["uuid"], "field11", reference)
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
            items = DataCenter::catalystItems()
                        .select{|item| item["active"] }
            Catalyst::program2(items)
            return
        end

        if Interpreting::match("ondates", input) then
            elements = DataCenter::mikuType("NxOndate").sort_by{|item| item["datetime"] }
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
            DataCenter::setAttribute(item["uuid"], "datetime", datetime)
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
                DataCenter::setAttribute(item["uuid"], "ordinal-1051", nil)
            end
            NxBalls::stop(item)
            return
        end

        if Interpreting::match("stop *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["ordinal-1051"] then
                DataCenter::setAttribute(item["uuid"], "ordinal-1051", nil)
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
