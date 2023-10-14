# encoding: UTF-8

class ListingCommandsAndInterpreters

    # ListingCommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | <datecode> | access (<n>) | push (<n>) # do not show until | done (<n>) | program (<n>) | expose (<n>) | add time <n> | coredata (<n>) | skip (<n>) | pile (<n>) | deadline (<n>) | active (<n>) | unparent <n> | red (*) | unred (*) | engine * | core * | destroy (<n>)",
            "",
            "Transmutations:",
            "              : (task)   >ondate (<n>)",
            "              : (ondate) >task (<n>)",
            "",
            "makers        : anniversary | manual countdown | wave | today | tomorrow | ondate | desktop | task | pile | thread",
            "divings       : anniversaries | ondates | waves | desktop | boxes | threads",
            "NxBalls       : start | start (<n>) | stop | stop (<n>) | pause | pursue",
            "NxOnDate      : redate",
            "NxTask        : red (<n>)",
            "misc          : search | speed | commands | edit <n> | move | stream",
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
            if !item["mikuType"] != "NxTask" then
                puts "For the moment we only run >ondate on NxTasks"
                LucilleCore::pressEnterToContinue()
                return
            end
            Updates::itemAttributeUpdate(item["uuid"], "description", item["description"].gsub("(buffer-in)", "").strip)
            Updates::itemAttributeUpdate(item["uuid"], "datetime", CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode())
            Updates::itemAttributeUpdate(item["uuid"], "mikuType", "NxOndate")
            return
        end

        if Interpreting::match("stream", input) then
            Stream::main()
            return
        end

        if Interpreting::match("tothread *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
            Updates::itemAttributeUpdate(item["uuid"], "description", description)
            Updates::itemAttributeUpdate(item["uuid"], "hours", hours)
            Updates::itemAttributeUpdate(item["uuid"], "lastResetTime", 0)
            Updates::itemAttributeUpdate(item["uuid"], "capsule", SecureRandom.hex)
            Updates::itemAttributeUpdate(item["uuid"], "mikuType", "NxThread")
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
            Updates::itemAttributeUpdate(item["uuid"], "description", item["description"].gsub("(buffer-in)", "").strip)
            Updates::itemAttributeUpdate(item["uuid"], "datetime", CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode())
            Updates::itemAttributeUpdate(item["uuid"], "mikuType", "NxOndate")
            return
        end

        if Interpreting::match("move", input) then
            Catalyst::selectSubsetAndMoveToSelectedThread(store.items())
            return
        end

        if Interpreting::match("threads", input) then
            NxThreads::program2()
            return
        end

        if Interpreting::match("today", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match(">>", input) then
            item = store.getDefault()
            return if item.nil?
            thread = NxThreads::interactivelySelectOneOrNull()
            Updates::itemAttributeUpdate(item["uuid"], "parent-1328", thread["uuid"])
            return
        end

        if Interpreting::match("red", input) then
            item = store.getDefault()
            return if item.nil?
            Updates::itemAttributeUpdate(item["uuid"], "red-1854", CommonUtils::today())
            return
        end

        if Interpreting::match("red *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Updates::itemAttributeUpdate(item["uuid"], "red-1854", CommonUtils::today())
            return
        end

        if Interpreting::match("unred", input) then
            item = store.getDefault()
            return if item.nil?
            Updates::itemAttributeUpdate(item["uuid"], "red-1854", nil)
            return
        end

        if Interpreting::match("unred *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Updates::itemAttributeUpdate(item["uuid"], "red-1854", nil)
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

        if Interpreting::match("task", input) then
            item = NxTasks::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            loop {
                thread = NxThreads::interactivelySelectOneOrNull()
                next if thread.nil?
                Updates::itemAttributeUpdate(item["uuid"], "parent-1328", thread["uuid"])
                break
            }
            return
        end

        if Interpreting::match("thread", input) then
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

        if Interpreting::match("core *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            core = TxCores::interactivelySelectOneOrNull()
            return if core.nil?
            Updates::itemAttributeUpdate(item["uuid"], "core-1919", core["uuid"])
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
            Updates::itemAttributeUpdate(item["uuid"], "datetime", "#{CommonUtils::nDaysInTheFuture(1)} 07:00:00+00:00")
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
