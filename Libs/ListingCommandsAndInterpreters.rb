# encoding: UTF-8

class ListingCommandsAndInterpreters

    # ListingCommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | <datecode> | access (<n>) | do not show until <n> | done (<n>) | program (<n>) | expose (<n>) | add time <n> | coredata (<n>) | tx8 (<n>) | holiday <n> | skip | cloud (<n>) | position (<n>) | reorganise <n> | pile (<n>) | deadline (<n>) | core (<n>) | >> | destroy (<n>)",
            "",
            "specific types commands:",
            "    - OnDate  : redate",
            "makers        : anniversary | manual countdown | wave | today | tomorrow | ondate | desktop | task | time | times | delegate",
            "divings       : anniversaries | ondates | waves | desktop | boxes | cores | delegates",
            "NxBalls       : start | start (<n>) | stop | stop (<n>) | pause | pursue",
            "misc          : search | speed | commands | mikuTypes | edit <n> | reschedule",
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

        if Interpreting::match(">>", input) then
            item = store.getDefault()
            return if item.nil?

            # This command has different interpretations depending on the mikuType

            if item["mikuType"] == "NxTask" then
                puts PolyFunctions::toString(item).green
                thread = NxThreads::interactivelySelectOrNull()
                return if thread.nil?
                Tx8s::interactivelyPlaceItemAtParentAttempt(item, thread)
                return
            end

            unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
            return if unixtime.nil?
            DoNotShowUntil::setUnixtime(item, unixtime)
            return
        end

        if Interpreting::match("cores", input) then
            TxCores::program2()
            return
        end

        if Interpreting::match("skip", input) then
            item = store.getDefault()
            return if item.nil?
            TmpSkip1::tmpskip1(item, 1)
            return
        end

        if Interpreting::match("delegates", input) then
            NxDelegates::program1()
            return
        end

        if Interpreting::match("mikutypes", input) then
            puts JSON.pretty_generate(BladesItemised::all().map{|item| item["mikuType"] }.uniq.sort)
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("reschedule", input) then
            NxTimes::reschedule()
            return
        end

        if Interpreting::match("task", input) then
            NxTasks::interactivelyIssueNewOrNull()
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
            Tx8s::interactivelyPlaceItemAtParentAttempt(item, core)
            return
        end

        if Interpreting::match("core *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            puts PolyFunctions::toString(item).green
            core = TxCores::interactivelySelectOneOrNull()
            return if core.nil?
            Tx8s::interactivelyPlaceItemAtParentAttempt(item, core)
            return
        end

        if Interpreting::match("reorganise *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Tx8s::reorganise(item)
            return
        end

        if Interpreting::match("thread", input) then
            thread = NxThreads::interactivelyIssueNewOrNull()
            return if thread.nil?
            NxThreads::program1(thread)
            return
        end

        if Interpreting::match("thread *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            thread = NxThreads::interactivelySelectThreadAtMainListingOrNull()
            return if thread.nil?
            Tx8s::interactivelyPlaceItemAtParentAttempt(item, thread)
            return
        end

        if Interpreting::match("pile *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["mikuType"] != "NxTask" then
                puts "You can only pile * a NxTask"
                LucilleCore::pressEnterToContinue()
                return
            end
            if item["parent"].nil? then
                puts "Interestingly this item doesn't have a parent 🤔"
                LucilleCore::pressEnterToContinue()
                return
            end
            parent = BladesGI::itemOrNull(item["parent"]["uuid"])
            if parent.nil? then
                puts "Interestingly the specified parent cannot be found 🤔"
                LucilleCore::pressEnterToContinue()
                return
            end
            Tx8s::pileAtThisParent(parent)
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
            puts "adding time for '#{PolyFunctions::toString(item).green}'"
            timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
            PolyActions::addTimeToItem(item, timeInHours*3600)
        end

        if Interpreting::match("delegate", input) then
            item = NxDelegates::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("access", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::access(item)
            return
        end

        if Interpreting::match("time", input) then
            item = NxTimes::interactivelyIssueTimeOrNull()
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("times", input) then
            loop {
                puts ""
                item = NxTimes::interactivelyIssueTimeOrNull()
                return if item.nil?
                puts JSON.pretty_generate(item)
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

        if Interpreting::match("coredata", input) then
            item = store.getDefault()
            return if item.nil?
            reference =  CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(item["uuid"])
            return if reference.nil?
            BladesGI::setAttribute2(item["uuid"], "field11", reference)
            return
        end

        if Interpreting::match("coredata *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            reference =  CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(item["uuid"])
            return if reference.nil?
            BladesGI::setAttribute2(item["uuid"], "field11", reference)
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
                BladesGI::setAttribute2(item["uuid"], key, value)
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
            unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
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
            BladesGI::setAttribute2(item["uuid"], "datetime", "#{CommonUtils::nDaysInTheFuture(1)} 07:00:00+00:00")
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
