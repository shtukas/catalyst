# encoding: UTF-8

class CommandsAndInterpreters

    # CommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | ... | <datecode> | access (*) | start (*) | done (*) | done+ (*) (done the first subline) | program (*) | expose (*) | add time * | skip * hours (default item) | bank accounts * | payload (*) | bank data * | push * | * on <datecode> | edit * | destroy * | >> * (update behaviour) | delist * | insert into * | dive *",
            "makers        : anniversary | wave | today | tomorrow | desktop | todo | ondate | on <weekday> | backup | priority | happening",
            "divings       : anniversaries | ondates | waves | desktop | backups | todays | tomorrows | happenings | tasks",
            "NxBalls       : start (*) | stop (*) | pause (*) | pursue (*)",
            "misc          : search | commands | fsck | maintenance | sort | morning",
        ].join("\n")
    end

    # CommandsAndInterpreters::interpreter(input, store)
    def self.interpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                PolyActions::stop(item)
                "dot not show until: #{Time.at(unixtime).to_s}".yellow
                DoNotShowUntil::doNotShowUntil(item, unixtime)
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

        if Interpreting::match("* on *", input) then
            listord, _, datecode = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            unixtime = CommonUtils::codeToUnixtimeOrNull(datecode)
            PolyActions::stop(item)
            DoNotShowUntil::doNotShowUntil(item, unixtime)
            return
        end

        if Interpreting::match(">> *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            puts "not implemented"
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("morning", input) then
            # ondates
            puts "select ondates"
            selected1, _ = LucilleCore::selectZeroOrMore("elements", [], NxOndates::listingItems(), lambda{|i| PolyFunctions::toString(i) })
            selected1.each{|item|
                Items::setAttribute(item["uuid"], "nx41", {
                    "type"     => "override",
                    "position" => rand,
                })
            }
            # NxTasks
            puts "select tasks"
            selected2, _ = LucilleCore::selectZeroOrMore("elements", [], Items::mikuType("NxTask"), lambda{|i| PolyFunctions::toString(i) })
            selected2.each{|item|
                Items::setAttribute(item["uuid"], "nx41", {
                    "type"     => "override",
                    "position" => rand,
                })
            }
            # waves
            puts "select waves"
            selected3, _ = LucilleCore::selectZeroOrMore("elements", [], Waves::listingItems(), lambda{|i| PolyFunctions::toString(i) })
            selected3.each{|item|
                Items::setAttribute(item["uuid"], "nx41", {
                    "type"     => "override",
                    "position" => rand,
                })
            }

            puts "Morning/Today ordering"
            sleep 1

            items = selected1 + selected2 + selected3 + Items::mikuType("NxLine")
            selected, _ = LucilleCore::selectZeroOrMore("elements", [], items, lambda{|i| PolyFunctions::toString(i) })
            selected.reverse.each{|item|
                Items::setAttribute(item["uuid"], "nx41", {
                    "type"     => "override",
                    "position" => 0.5 * (1 + ListingPosition::firstTodayListingPosition()),
                })
            }

            return
        end

        if Interpreting::match("sort", input) then
            items = store.items()
            selected, _ = LucilleCore::selectZeroOrMore("elements", [], items, lambda{|i| PolyFunctions::toString(i) })
            selected.reverse.each{|item|
                Items::setAttribute(item["uuid"], "nx41", {
                    "type"     => "override",
                    "position" => ListingPosition::firstPriorityListingPosition() - 1,
                })
            }
            return
        end

        if Interpreting::match("dive *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            puts "diving into #{PolyFunctions::toString(item)}"
            Operations::dive(item)
            return
        end

        if Interpreting::match("delist *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            puts "delisting #{PolyFunctions::toString(item)}"
            Items::setAttribute(item["uuid"], "nx41", nil)
            return
        end

        if Interpreting::match("maintenance", input) then
            Operations::globalMaintenance()
            return
        end

        if Interpreting::match("insert into *", input) then
            _, _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxSublines::insert(item)
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
            Bank::getRecords(item["uuid"])
                .sort_by{|record| record["date"] }
                .each{|record|
                    puts "recorduuid: #{record["recorduuid"]}; uuid: #{record["id"]}, date: #{record["date"]}, value: #{"%9.2f" % record["value"]}"
                }
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("priority", input) then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return if description == ""
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["top", "bottom (default)"])
            position = (option == "top") ? ( ListingPosition::firstPriorityListingPosition() - 1 ) : (ListingPosition::lastPriorityListingPosition().to_f / 2)
            NxLines::issue(description, position)
            return
        end

        if Interpreting::match("backup", input) then
            item = NxBackups::interactivelyIssueNewOrNull()
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("backups", input) then
            Operations::program3(lambda { 
                Items::mikuType("NxBackup")
            })
            return
        end

        if Interpreting::match("payload", input) then
            item = store.getDefault()
            return if item.nil?
            UxPayloads::payloadProgram(item)
            return
        end

        if Interpreting::match("payload *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            UxPayloads::payloadProgram(item)
            return
        end

        if Interpreting::match("fsck", input) then
            Fsck::fsckAll()
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("on *", input) then
            _, weekdayName = Interpreting::tokenizer(input)
            return if !["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"].include?(weekdayName)
            date = CommonUtils::selectDateOfNextNonTodayWeekDay(weekdayName)
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            item = NxOndates::interactivelyIssueNewWithDetails(description, date)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("today", input) then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["top", "bottom (default)"])
            position = (option == "top") ? ListingPosition::firstTodayListingPosition().to_f/2 : (ListingPosition::lastTodayListingPosition().to_f + 1).to_f/2
            item = NxLines::issueNewInteractivelyDecidesPayload(description, position)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("tasks", input) then
            Operations::program3(lambda { 
                Items::mikuType("NxTask")
            })
            return
        end

        if Interpreting::match("todays", input) then
            Operations::program3(lambda { 
                Items::mikuType("NxOndate")
                    .select{|item| item["date"] <= CommonUtils::today() }
                    .sort_by{|item| item["date"] }
            })
            return
        end

        if Interpreting::match("tomorrows", input) then
            Operations::program3(lambda { 
                Items::mikuType("NxOndate")
                    .select{|item| item["date"] == CommonUtils::tomorrow() }
            })
            return
        end

        if Interpreting::match("tomorrow", input) then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            item = NxOndates::interactivelyIssueNewWithDetails(description, CommonUtils::tomorrow())
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ondate", input) then
            item = NxOndates::interactivelyIssueNewOrNull()
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ondates", input) then
            Operations::program3(lambda { 
                Items::mikuType("NxOndate")
                    .sort_by{|item| item["date"] }
            })
            return
        end

        if Interpreting::match("skip * hours", input) then
            _, d, _ = Interpreting::tokenizer(input)
            item = store.getDefault()
            return if item.nil?
            Items::setAttribute(item["uuid"], "skip-0843", Time.new.to_i+3600*d.to_f)
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

        if Interpreting::match("happening", input) then
            item = NxHappenings::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("happenings", input) then
            Operations::program3(lambda { 
                Items::mikuType("NxHappening")
            })
            return
        end

        if Interpreting::match("anniversary", input) then
            item = Anniversary::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("anniversaries", input) then
            Operations::program3(lambda { 
                Items::mikuType("Anniversary")
            })
            return
        end

        if Interpreting::match("todo", input) then
            item = NxTasks::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
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

        if Interpreting::match("edit", input) then
            item = store.getDefault()
            return if item.nil?
            Operations::editItem(item)
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

        if Interpreting::match("done+", input) then
            item = store.getDefault()
            return if item.nil?
            NxSublines::itemsForParentInOrder(item["uuid"]).each{|subline|
                PolyActions::destroy(subline)
                return # We just do the first one
            }
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
            PolyActions::stop(item)
            datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
            Items::setAttribute(item["uuid"], "date", datetime)
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

        if input == "wave" then
            item = Waves::interactivelyMakeNewOrNull()
            puts JSON.pretty_generate(item)
            return
        end

        if input == "waves" then
            Operations::program3(lambda { 
                Items::mikuType("Wave")
                    .sort_by{|item| item["lastDoneUnixtime"] }
            })
            return
        end
    end
end
