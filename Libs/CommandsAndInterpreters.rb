# encoding: UTF-8

class CommandsAndInterpreters

    # CommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : ..(.) | <datecode> | access (*) | start (*) | done (*) | program * | expose * | add time * | skip * hours (default item) | bank accounts * | payload * | bank data * | donation * | push * | dismiss * | * on <datecode> | edit * | destroy *",
            "makers        : anniversary | wave | today | tomorrow | desktop | float | todo | ondate | on <weekday> | backup | line after <item number> | priority | priorities | project",
            "              : transmute *",
            "divings       : anniversaries | ondates | waves | desktop | backups | floats | cores | projects | lines | todays | dive *",
            "NxBalls       : start * | stop * | pause * | pursue *",
            "misc          : search | commands | fsck | probe-head | sort",
        ].join("\n")
    end

    # CommandsAndInterpreters::interpreter(input, store)
    def self.interpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                NxBalls::stop(item)
                "dot not show until: #{Time.at(unixtime).to_s}".yellow
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                Index0::removeEntry(item["uuid"])
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

       if Interpreting::match("sort", input) then
            items = store.items()
            selected, _ = LucilleCore::selectZeroOrMore("elements", [], items, lambda{|i| PolyFunctions::toString(i) })
            selected.reverse.each{|i|
                position = 0.9 * [Index0::firstPositionInDatabase(), 0.20].min
                Index0::setPositionOverride(i["uuid"], position)
            }
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
            Index4::getRecords(item["uuid"])
                .sort_by{|record| record["date"] }
                .each{|record|
                    puts "recorduuid: #{record["recorduuid"]}; uuid: #{record["id"]}, date: #{record["date"]}, value: #{"%9.2f" % record["_value_"]}"
                }
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("probe-head", input) then
            Operations::probeHead()
            return
        end

        if Interpreting::match("priority", input) then
            NxBalls::activeItems().each{|item| 
                NxBalls::pause(item)
            }
            item = NxLines::interactivelyIssueNewOrNull()
            return if item.nil?
            payload = UxPayload::makeNewOrNull(item["uuid"])
            if payload then
                item["uxpayload-b4e4"] = payload
                Index3::setAttribute(item["uuid"], "uxpayload-b4e4", payload)
            end
            item = Operations::interactivelySetDonation(item)
            Index0::insertUpdateEntryComponents1(item, Index0::firstPositionInDatabase()*0.9, nil, Index0::decideListingLine(item))
            NxBalls::start(item)
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
                    item = NxLines::interactivelyIssueNew(nil, line)
                    Operations::interactivelySetDonation(item)
                    item = Index3::itemOrNull(item["uuid"])
                    Index0::insertUpdateEntryComponents1(item, Index0::firstPositionInDatabase()*0.9, nil, Index0::decideListingLine(item))
                    last_item = item
                }
            if last_item then
                NxBalls::start(last_item)
            end
            return
        end

        if Interpreting::match("backups", input) then
            Operations::program3(lambda { Index1::mikuTypeItems("NxBackup").sort_by{|item| item["description"] } })
            return
        end

        if Interpreting::match("line after *", input) then
            _, _, n = Interpreting::tokenizer(input)
            n = n.to_i
            items = store.items()
            items = items.drop(n)
            position = 0.5*(Index0::getPositionOrNull(items[0]["uuid"]) + Index0::getPositionOrNull(items[1]["uuid"]))
            puts "deciding position: #{position}"
            line = LucilleCore::askQuestionAnswerAsString("description: ")
            item = NxLines::interactivelyIssueNew(nil, line)
            Operations::interactivelySetDonation(item)
            item = Index3::itemOrNull(item["uuid"])
            Index0::insertUpdateEntryComponents1(item, position, nil, Index0::decideListingLine(item))
            return
        end

        if Interpreting::match("payload *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            payload = UxPayload::makeNewOrNull(item["uuid"])
            return if payload.nil?
            Index3::setAttribute(item["uuid"], "uxpayload-b4e4", payload)
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
            Operations::interactivelySetDonation(item)
            Index0::evaluate(item["uuid"])
            return
        end

        if Interpreting::match("today", input) then
            item = NxDateds::interactivelyIssueTodayOrNull()
            return if item.nil?
            Operations::interactivelySetDonation(item)
            item = Index3::itemOrNull(item["uuid"])
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
            Operations::interactivelySetDonation(item)
            return
        end

        if Interpreting::match("skip * hours", input) then
            _, d, _ = Interpreting::tokenizer(input)
            item = store.getDefault()
            return if item.nil?
            Index3::setAttribute(item["uuid"], "skip-0843", Time.new.to_i+3600*d.to_f)
            Index0::evaluate(item["uuid"])
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
            NxTasks::interactivelyIssueNewOrNull()
            return
        end

        if Interpreting::match("float", input) then
            NxFloats::interactivelyIssueNewOrNull()
            return
        end

        if Interpreting::match("lines", input) then
            Operations::program3(lambda { Index1::mikuTypeItems("NxLine").sort_by{|item| item["unixtime"] } })
            return
        end

        if Interpreting::match("projects", input) then
            Operations::program3(lambda { Index1::mikuTypeItems("NxProject").sort_by{|item| item["project-position"] } })
            return
        end

        if Interpreting::match("floats", input) then
            Operations::program3(lambda { Index1::mikuTypeItems("NxFloat").sort_by{|item| item["unixtime"] } })
            return
        end

        if Interpreting::match("cores", input) then
            Operations::program3(lambda { Index1::mikuTypeItems("NxCore").sort_by{|item| NxCores::ratio(item) } })
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
            Index0::evaluate(item["uuid"])
            return
        end

        if Interpreting::match("description *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::editDescription(item)
            Index0::evaluate(item["uuid"])
            return
        end

        if Interpreting::match("edit", input) then
            item = store.getDefault()
            return if item.nil?
            Operations::editItem(item)
            Index0::evaluate(item["uuid"])
            return
        end

        if Interpreting::match("edit *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Operations::editItem(item)
            Index0::evaluate(item["uuid"])
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
            Index0::removeEntry(item["uuid"])
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

        if Interpreting::match("program *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::program(item)
            return
        end

        if Interpreting::match("ondates", input) then
            Operations::program3(lambda { Index1::mikuTypeItems("NxDated").sort_by{|item| item["date"][0, 10] }})
            return
        end

        if Interpreting::match("todays", input) then
            Operations::program3(lambda { 
                Index1::mikuTypeItems("NxDated")
                    .select{|item| item["date"][0, 10] <= CommonUtils::today() }
                    .sort_by{|item| item["unixtime"] }
            })
            return
        end

        if Interpreting::match("pause", input) then
            item = store.getDefault()
            return if item.nil?
            NxBalls::pause(item)
            Index0::evaluate(item["uuid"])
            return
        end

        if Interpreting::match("pause *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxBalls::pause(item)
            Index0::evaluate(item["uuid"])
            return
        end

        if Interpreting::match("pursue", input) then
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::pursue(item)
            Index0::evaluate(item["uuid"])
            return
        end

        if Interpreting::match("pursue *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::pursue(item)
            Index0::evaluate(item["uuid"])
            return
        end

        if Interpreting::match("redate *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxBalls::stop(item)
            datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
            Index3::setAttribute(item["uuid"], "date", datetime)
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
            Operations::interactivelySetDonation(item)
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
