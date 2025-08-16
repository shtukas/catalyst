# encoding: UTF-8

class CommandsAndInterpreters

    # CommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | ... | <datecode> | access (*) | start (*) | done (*) | program (*) | expose (*) | add time * | skip * hours (default item) | bank accounts * | payload (*) | bank data * | donation * | push * | dismiss * | * on <datecode> | edit * | replace * | destroy *",
            "NxTasks       : move (*)",
            "makers        : anniversary | wave | today | tomorrow | desktop | float | todo | ondate | on <weekday> | backup | priority | priorities | project",
            "              : transmute *",
            "divings       : anniversaries | ondates | waves | desktop | backups | floats | cores | todays | dive *",
            "NxBalls       : start (*) | stop (*) | pause (*) | pursue (*)",
            "misc          : search | commands | fsck | probe-head | sort | maintenance",
        ].join("\n")
    end

    # CommandsAndInterpreters::interpreter(input, store)
    def self.interpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                NxBalls::stop(item)
                "dot not show until: #{Time.at(unixtime).to_s}".yellow
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                ListingService::removeEntry(item["uuid"])
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

        if Interpreting::match("...", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::tripleDots(item)
            return
        end

        if Interpreting::match("... *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::tripleDots(item)
            return
        end

        if Interpreting::match(">>", input) then
            item = store.getDefault()
            return if item.nil?
            Transmutation::transmute2(item)
            return
        end

        if Interpreting::match(">> *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Transmutation::transmute2(item)
            return
        end

        if Interpreting::match("* on *", input) then
            listord, _, datecode = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            unixtime = CommonUtils::codeToUnixtimeOrNull(datecode)
            NxBalls::stop(item)
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            return
        end

        if Interpreting::match("maintenance", input) then
            Operations::globalMaintenance()
            return
        end

        if Interpreting::match("sort", input) then
            items = store.items()
            selected, _ = LucilleCore::selectZeroOrMore("elements", [], items, lambda{|i| PolyFunctions::toString(i) })
            selected.reverse.each{|i|
                position = 0.9 * [ListingService::firstPositionInDatabase(), 0.20].min
                ListingService::setPosition(i["uuid"], position, "override")
            }
            return
        end

        if Interpreting::match("sort *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Operations::generalSort(item)
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

        if Interpreting::match("move", input) then
            item = store.getDefault()
            return if item.nil?
            return if item["mikuType"] != "NxTask"
            packet = Operations::decideParentAndPositionOrNull()
            return if packet.nil?
            Parenting::insertEntry(packet["parent"]["uuid"], item["uuid"], packet["position"])
            return
        end

        if Interpreting::match("move *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            return if item["mikuType"] != "NxTask"
            parentuuid, position = Operations::decideParentAndPosition()
            Parenting::insertEntry(parentuuid, item["uuid"], position)
            return
        end

        if Interpreting::match("replace", input) then
            item = store.getDefault()
            return if item.nil?
            Operations::replace(item)
            return
        end

        if Interpreting::match("replace *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Operations::replace(item)
            return
        end

        if Interpreting::match("dismiss *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            unixtime = CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone()
            puts "pushing until '#{Time.at(unixtime).to_s.green}'"
            NxBalls::stop(item)
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            return
        end

        if Interpreting::match("bank data *", input) then
            _, _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            BankVault::getRecords(item["uuid"])
                .sort_by{|record| record["date"] }
                .each{|record|
                    puts "recorduuid: #{record["recorduuid"]}; uuid: #{record["id"]}, date: #{record["date"]}, value: #{"%9.2f" % record["value"]}"
                }
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("probe-head", input) then
            Operations::probeHead()
            return
        end

        if Interpreting::match("project", input) then
            item = NxProjects::interactivelyIssueNewOrNull()
            return if item.nil?
            item = Donations::interactivelySetDonation(item)
            ListingService::ensure(item)
            return
        end

        if Interpreting::match("numbers", input) then
            [
                {
                    "prefix" => "NxDated         :",
                    "rt" => BankData::recoveredAverageHoursPerDay("6a114b28-d6f2-4e92-9364-fadb3edc1122")
                },
                {
                    "prefix" => "Wave            :",
                    "rt" => BankData::recoveredAverageHoursPerDay("e0d8f86a-1783-4eb7-8f63-11562d8972a2")
                },
                {
                    "prefix" => "NxCore & NxTask :",
                    "rt" => BankData::recoveredAverageHoursPerDay("69297ca5-d92e-4a73-82cc-1d009e63f4fe")
                }
            ]
                .sort_by{|packet| packet["rt"] }
                .each{|packet|
                    puts "#{packet["prefix"]} #{packet["rt"]}"
                }
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("priority", input) then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return if description == ""
            NxBalls::activeItems().each{|item|
                NxBalls::pause(item)
            }
            item = NxTasks::descriptionToTask(description)
            item = Donations::interactivelySetDonation(item)
            ListingService::ensureAtOverridenPosition(item, ListingService::firstPositionInDatabase()*0.9)
            if LucilleCore::askQuestionAnswerAsBoolean("start ? ", true) then
                NxBalls::start(item)
            end
            return
        end

        if Interpreting::match("priorities", input) then
            NxBalls::activeItems().each{|item| 
                NxBalls::pause(item)
            }
            last_item = nil
            Operations::interactivelyGetLines()
                .reverse
                .each{|line|
                    puts "processing: #{line}".green
                    item = NxTasks::descriptionToTask(line)
                    item = Donations::interactivelySetDonation(item)
                    ListingService::ensureAtOverridenPosition(item, ListingService::firstPositionInDatabase()*0.9)
                    last_item = item
                }
            if last_item then
                if LucilleCore::askQuestionAnswerAsBoolean("start ? ", true) then
                    NxBalls::start(last_item)
                end
            end
            return
        end

        if Interpreting::match("backups", input) then
            Operations::program3(lambda { Items::mikuType("NxBackup").sort_by{|item| item["description"] } })
            return
        end

        if Interpreting::match("payload", input) then
            item = store.getDefault()
            return if item.nil?
            UxPayload::payloadProgram(item)
            return
        end

        if Interpreting::match("payload *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            UxPayload::payloadProgram(item)
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

        if Interpreting::match("donation *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Donations::interactivelySetDonation(item)
            ListingService::evaluate(item["uuid"])
            return
        end

        if Interpreting::match("today", input) then
            item = NxDateds::interactivelyIssueTodayOrNull()
            return if item.nil?
            Donations::interactivelySetDonation(item)
            item = Items::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("fsck", input) then
            Fsck::fsckAll()
            return
        end

        if Interpreting::match("ondate", input) then
            item = NxDateds::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            Donations::interactivelySetDonation(item)
            return
        end

        if Interpreting::match("skip * hours", input) then
            _, d, _ = Interpreting::tokenizer(input)
            item = store.getDefault()
            return if item.nil?
            Items::setAttribute(item["uuid"], "skip-0843", Time.new.to_i+3600*d.to_f)
            ListingService::evaluate(item["uuid"])
            return
        end

        if Interpreting::match("backup", input) then
            item = NxBackups::interactivelyIssueNewOrNull()
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

        if Interpreting::match("todo", input) then
            todo = NxTasks::interactivelyIssueNewOrNull()
            parentuuid, position = Operations::decideParentAndPosition()
            Parenting::insertEntry(parentuuid, todo["uuid"], position)
            ListingService::evaluate(todo["uuid"])
            return
        end

        if Interpreting::match("float", input) then
            NxFloats::interactivelyIssueNewOrNull()
            return
        end

        if Interpreting::match("floats", input) then
            Operations::program3(lambda { Items::mikuType("NxFloat").sort_by{|item| item["unixtime"] } })
            return
        end

        if Interpreting::match("cores", input) then
            Operations::program3(lambda { Items::mikuType("NxCore").sort_by{|item| NxCores::ratio(item) } })
            return
        end

        if Interpreting::match("dive *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Operations::diveItem(item)
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
            ListingService::evaluate(item["uuid"])
            return
        end

        if Interpreting::match("description *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::editDescription(item)
            ListingService::evaluate(item["uuid"])
            return
        end

        if Interpreting::match("edit", input) then
            item = store.getDefault()
            return if item.nil?
            Operations::editItem(item)
            ListingService::evaluate(item["uuid"])
            return
        end

        if Interpreting::match("edit *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Operations::editItem(item)
            ListingService::evaluate(item["uuid"])
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

        if Interpreting::match("push *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::stop(item)
            Operations::interactivelyPush(item)
            ListingService::removeEntry(item["uuid"])
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
            Operations::program3(lambda { Items::mikuType("NxDated").sort_by{|item| item["date"][0, 10] }})
            return
        end

        if Interpreting::match("todays", input) then
            Operations::program3(lambda { 
                Items::mikuType("NxDated")
                    .select{|item| item["date"][0, 10] <= CommonUtils::today() }
                    .sort_by{|item| item["unixtime"] }
            })
            return
        end

        if Interpreting::match("pause", input) then
            item = store.getDefault()
            return if item.nil?
            NxBalls::pause(item)
            ListingService::evaluate(item["uuid"])
            return
        end

        if Interpreting::match("pause *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxBalls::pause(item)
            ListingService::evaluate(item["uuid"])
            return
        end

        if Interpreting::match("pursue", input) then
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::pursue(item)
            ListingService::evaluate(item["uuid"])
            return
        end

        if Interpreting::match("pursue *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::pursue(item)
            ListingService::evaluate(item["uuid"])
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
            Donations::interactivelySetDonation(item)
            return
        end

        if input == "wave" then
            item = Waves::issueNewWaveInteractivelyOrNull(SecureRandom.uuid)
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if input == "waves" then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", ["full", "listing"])
            return if option.nil?
            if option == "full" then
                Waves::program1()
            end
            if option == "listing" then
                Waves::program2()
            end
            return
        end
    end
end
