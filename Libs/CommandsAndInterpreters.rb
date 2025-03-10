# encoding: UTF-8

class CommandsAndInterpreters

    # CommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | <datecode> | access (<n>) | done (<n>) | program (<n>) | expose (<n>) | add time <n> | skip (<n>) | bank accounts * | payload * | bank data * | donation * | push * | pile * | activate * | destroy *",
            "",
            "makers        : anniversary | wave | today | tomorrow | desktop | float | todo | ondate | on <weekday> | priority",
            "              : transmute *",
            "divings       : anniversaries | ondates | waves | desktop | backups | floats | cores | active items",
            "NxBalls       : start (<n>) | stop (<n>) | pause (<n>) | pursue (<n>)",
            "misc          : search | commands | edit <n> | speed | push core",
        ].join("\n")
    end

    # CommandsAndInterpreters::interpreter(input, store)
    def self.interpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                NxBalls::stop(item)
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

        if Interpreting::match("transmute *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Transmutation::transmute2(item)
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

        if Interpreting::match("bank data *", input) then
            _, _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Bank1::getRecords(item["uuid"])
                .sort_by{|record| record["_date_"] }
                .each{|record|
                    puts "recorduuid: #{record["_recorduuid_"]}; uuid: #{record["_id_"]}, date: #{record["_date_"]}, value: #{"%9.2f" % record["_value_"]}"
                }
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("backups", input) then
            Operations::program3(lambda { Items::mikuType("NxBackup").sort_by{|item| item["description"] } })
            return
        end

        if Interpreting::match("priority", input) then
            NxBalls::activeItems().each{|item| NxBalls::pause(item) }
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return if description == ''
            item = NxStackPriorities::interactivelyIssueNewOrNull(description)
            Operations::setDonation(item)
            item = Items::itemOrNull(item["uuid"])
            NxBalls::start(item)
            return
        end

        if Interpreting::match("payload *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            payload = UxPayload::makeNewOrNull(item["uuid"])
            return if payload.nil?
            Items::setAttribute(item["uuid"], "uxpayload-b4e4", payload)
            return
        end

        if Interpreting::match("on *", input) then
            _, weekdayName = Interpreting::tokenizer(input)
            return if !["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"].include?(weekdayName)
            date = CommonUtils::selectDateOfNextNonTodayWeekDay(weekdayName)
            item = NxDateds::interactivelyIssueAtGivenDateOrNull(date)
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("pile *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxStrats::pile(item)
            return
        end

        if Interpreting::match("donation *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Operations::setDonation(item)
            return
        end

        if Interpreting::match("today", input) then
            item = NxDateds::interactivelyIssueTodayOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if input == 'active items' then
            lx = lambda { NxTasks::activeItemsInRatioOrder() }
            Operations::program3(lx)
            return
        end

        if Interpreting::match("ondate", input) then
            item = NxDateds::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("skip", input) then
            item = store.getDefault()
            return if item.nil?
            Items::setAttribute(item["uuid"], "skip-0843", Time.new.to_i+3600*2)
            return
        end

        if Interpreting::match("skip *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Items::setAttribute(item["uuid"], "skip-0843", Time.new.to_i+3600*2)
            return
        end

        if Interpreting::match("todo", input) then
            item = NxTasks::interactivelyIssueNewOrNull()
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

        if Interpreting::match("float", input) then
            NxFloats::interactivelyIssueNewOrNull()
            return
        end

        if Interpreting::match("speed", input) then
            t1 = Time.new.to_f
            Listing::listingOnce(lambda{|line| })
            t2 = Time.new.to_f
            puts "Listing::listingOnce() in #{(t2-t1).round(3)} seconds"
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("floats", input) then
            Operations::program3(lambda { Items::mikuType("NxFloat").sort_by{|item| item["unixtime"] } })
            return
        end

        if Interpreting::match("cores", input) then
            NxCores::program2()
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

        if Interpreting::match("activate *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            return if item["mikuType"] != "NxTask"
            nx1608 = NxTasks::interactivelyMakeNx1608OrNull()
            return if nx1608.nil?
            Items::setAttribute(item["uuid"], "nx1608", nx1608)
            return
        end


        if Interpreting::match("edit *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Operations::editItem(item)
            return
        end

        if Interpreting::match("desktop", input) then
            system("open '#{Desktop::filepath()}'")
            return
        end

        if Interpreting::match("done", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::done(item, true)
            return
        end

        if Interpreting::match("done *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::done(item, true)
            return
        end

        if Interpreting::match("destroy *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::destroy(item)
            return
        end

        if Interpreting::match("push core", input) then
            core = NxCores::interactivelySelectOrNull()
            return if core.nil?
            unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
            return if unixtime.nil?
            puts "pushing core: '#{core["description"].green}', until '#{Time.at(unixtime).to_s.green}'"
            DoNotShowUntil::setUnixtime(core["uuid"], unixtime)
            return
        end

        if Interpreting::match("push *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Operations::interactivelyPush(item)
            return
        end

        if Interpreting::match("expose", input) then
            item = store.getDefault()
            return if item.nil?
            Operations::expose(item)
            return
        end

        if Interpreting::match("expose *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Operations::expose(item)
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

        if Interpreting::match("ondates", input) then
            Operations::program3(lambda { Items::mikuType("NxDated").sort_by{|item| item["datetime"] }})
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
            Items::setAttribute(item["uuid"], "date", datetime)
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
            PolyActions::stop(item)
            return
        end

        if Interpreting::match("stop *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::stop(item)
            return
        end

        if Interpreting::match("search", input) then
            Search::run()
            return
        end

        if Interpreting::match("tomorrow", input) then
            item = NxDateds::interactivelyIssueTomorrowOrNull()
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
    end
end
