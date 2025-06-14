# encoding: UTF-8

class CommandsAndInterpreters

    # CommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | <datecode> | access <n> | start | start <n> | done | done <n> | program * | expose * | add time * | skip * | bank accounts * | payload * | bank data * | donation * | push * | dismiss * | * on <datecode> | destroy *",
            "on items : activate * | disactivate *",
            "positioning : insert at <position> | move * to <position> | release *",
            "makers        : anniversary | wave | today | tomorrow | desktop | float | todo | ondate | on <weekday> | priority | backup | pile",
            "              : transmute *",
            "divings       : anniversaries | ondates | waves | waves+ | desktop | backups | floats | cores | active items | dive *",
            "NxBalls       : start * | stop * | pause * | pursue *",
            "misc          : search | commands | edit * | fsck-all | reset-cache | sort",
        ].join("\n")
    end

    # CommandsAndInterpreters::interpreter(input, store)
    def self.interpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                NxBalls::stop(item)
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                Items::setAttribute(item["uuid"], "nx0810", nil)
                return
            end
        end

        if Interpreting::match("..", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::double_dots(item)
            return
        end

        if Interpreting::match(".. *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::double_dots(item)
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

        if Interpreting::match("reset-cache", input) then
            XCache::set("049bdc08-8833-4736-aa90-4dc2c59fd67d:#{CommonUtils::today()}", Time.new.to_f.to_s)
            return
        end

        if Interpreting::match("dismiss *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            unixtime = CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone()
            puts "pushing until '#{Time.at(unixtime).to_s.green}'"
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            
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

        if Interpreting::match("move * to *", input) then
            _, listord, _, position = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            nx0810 = {
                "position" => position.to_f
            }
            Items::setAttribute(item["uuid"], "nx0810", nx0810)
            return
        end

        if Interpreting::match("insert at *", input) then
            _, _, position = Interpreting::tokenizer(input)
            item = NxLines::interactivelyIssueNewOrNull()
            return if item.nil?
            nx0810 = {
                "position" => position.to_f
            }
            Items::setAttribute(item["uuid"], "nx0810", nx0810)
            Operations::interactivelySetDonation(item)
            return
        end

        if Interpreting::match("priority", input) then
            NxBalls::activeItems().each{|item| 
                NxBalls::pause(item)
            }
            item = NxLines::interactivelyIssueNewOrNull()
            return if item.nil?
            nx0810 = {
                "position" => PolyFunctions::topNx0810Position() * 0.9 # we work with the assumtion that the positions are always positive.
            }
            Items::setAttribute(item["uuid"], "nx0810", nx0810)
            Operations::interactivelySetDonation(item)
            item = Items::itemOrNull(item["uuid"])
            NxBalls::start(item)
            return
        end

        if Interpreting::match("pile", input) then
            text = CommonUtils::editTextSynchronously("")
            donation_package = Operations::interactivelySelectTargetForDonationOrNull()
            lines = text.strip.lines.map{|line| line.strip }
            lines = lines.reverse
            last_item = nil
            lines.each{|line|
                item = NxLines::interactivelyIssueNew(line)
                nx0810 = {
                    "position" => PolyFunctions::topNx0810Position() * 0.9 # we work with the assumtion that the positions are always positive.
                }
                Items::setAttribute(item["uuid"], "nx0810", nx0810)
                if donation_package then
                    Items::setAttribute(item["uuid"], "donation-1205", donation_package["uuid"])
                end
                last_item = Items::itemOrNull(item["uuid"])
            }
            if last_item then
                NxBalls::start(last_item)
            end
            return
        end

        if Interpreting::match("release *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Items::setAttribute(item["uuid"], "nx0810", nil)
            return
        end

        if Interpreting::match("sort", input) then
            elements = Listing::itemsForListing1()
            selected, _ = LucilleCore::selectZeroOrMore("elements", [], elements, lambda{|i| PolyFunctions::toString(i) })
            selected.reverse.each{|i|
                nx0810 = {
                    "position" => PolyFunctions::topNx0810Position() * 0.9 # we work with the assumtion that the positions are always positive.
                }
                Items::setAttribute(i["uuid"], "nx0810", nx0810)
            }
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

        if Interpreting::match("donation *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Operations::interactivelySetDonation(item)
            
            return
        end

        if Interpreting::match("today", input) then
            item = NxDateds::interactivelyIssueTodayOrNull()
            return if item.nil?
            Operations::interactivelySetDonation(item)
            item = Items::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("fsck-all", input) then
            Fsck::fsckAll()
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
            Operations::interactivelySetDonation(item)
            return
        end

        if Interpreting::match("skip *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Items::setAttribute(item["uuid"], "skip-0843", Time.new.to_i+3600*2)
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
            nx1609 = NxTasks::interactivelyMakeNx1609OrNull()
            return if nx1609.nil?
            Items::setAttribute(item["uuid"], "nx1609", nx1609)
            return
        end

        if Interpreting::match("disactivate *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            return if item["mikuType"] != "NxTask"
            Items::setAttribute(item["uuid"], "nx1609", nil)
            
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
            Operations::checkTopListingItemAndProposeToPursueIfRelevant()
            return
        end

        if Interpreting::match("done *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::done(item, true)
            Operations::checkTopListingItemAndProposeToPursueIfRelevant()
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
            Operations::program3(lambda { Items::mikuType("NxDated").sort_by{|item| item["date"][0, 10] }})
            return
        end

        if Interpreting::match("pause", input) then
            item = store.get(listord.to_i)
            return if item.nil?
            NxBalls::pause(item)
            return
        end

        if Interpreting::match("pause *", input) then
            item = store.getDefault()
            return if item.nil?
            NxBalls::pause(item)
            return
        end

        if Interpreting::match("pursue", input) then
            item = store.get(listord.to_i)
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
