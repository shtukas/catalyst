# encoding: UTF-8

class CommandsAndInterpreters

    # CommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | ... | <datecode> | access (*) | start (*) | done (*) | program (*) | expose (*) | add time * | skip * hours (default item) | bank accounts * | payload (*) | bank data * | push * | * on <datecode> | edit * | destroy * | delist * | move * | time commitment *",
            "makers        : anniversary | wave | today | tomorrow | desktop | todo | ondate | on <weekday> | backup | priority | project",
            "divings       : anniversaries | ondates | waves | desktop | backups | tomorrows | projects | todays | todos",
            "NxBalls       : start (*) | stop (*) | pause (*) | pursue (*)",
            "misc          : search | commands | fsck | fsck-force | maintenance | sort | morning",
        ].join("\n")
    end

    # CommandsAndInterpreters::interpreter(input, store)
    def self.interpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                if item["mikuType"] == "NxTimeCommitment" then
                    puts "Nope! We don't push NxTimeCommitments"
                    LucilleCore::pressEnterToContinue()
                    return
                end
                PolyActions::stop(item)
                ListingPosition::delist(item)
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

        if Interpreting::match("sort", input) then
            items = store.items()
            selected, _ = LucilleCore::selectZeroOrMore("elements", [], items, lambda{|i| PolyFunctions::toString(i) })
            selected.reverse.each{|item|
                Blades::setAttribute(item["uuid"], "nx42", ListingPosition::firstNegativeListingPosition() - 1)
            }
            return
        end

        if Interpreting::match("move *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Parenting::move(item)
            return
        end

        if Interpreting::match("delist *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            puts "delisting #{PolyFunctions::toString(item)}"
            Blades::setAttribute(item["uuid"], "nx42", nil)
            return
        end

        if Interpreting::match("morning", input) then
            Operations::morning()
            return
        end

        if Interpreting::match("maintenance", input) then
            Operations::globalMaintenance()
            return
        end

        if Interpreting::match("time commitment *", input) then
            _, _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if ["NxToday"].include?(item["mikuType"]) then
                puts "transmuting '#{PolyFunctions::toString(item).green}' to NxTimeCommitment"
                Transmute::transmuteTo(item, "NxTimeCommitment")
                return
            end
            puts "I do not know how to transmute a #{item["mikuType"]} to NxTimeCommitment"
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
            item = NxTasks::interactivelyIssueNewOrNull()
            return if item.nil?
            Blades::setAttribute(item["uuid"], "nx42", ListingPosition::firstNegativeListingPosition() - 1)
            item = Blades::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxBalls::runningItems().each{|i|
                NxBalls::pause(i)
            }
            if LucilleCore::askQuestionAnswerAsBoolean("start `#{item["description"]}` ? ", true) then
                NxBalls::start(item)
            end
            return
        end

        if Interpreting::match("backup", input) then
            item = NxBackups::interactivelyIssueNewOrNull()
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("backups", input) then
            Operations::program3(lambda { 
                Blades::mikuType("NxBackup")
            })
            return
        end

        if Interpreting::match("project", input) then
            item = store.getDefault()
            return if item.nil?
            NxTasks::interactivelyIssueNewOrNull()
            return
        end

        if Interpreting::match("projects", input) then
            item = store.getDefault()
            return if item.nil?
            Operations::program3(lambda { 
                Blades::mikuType("NxProject")
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

        if Interpreting::match("dive", input) then
            item = store.getDefault()
            return if item.nil?
            Parenting::dive(item)
            return
        end

        if Interpreting::match("dive *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Parenting::dive(item)
            return
        end

        if Interpreting::match("fsck", input) then
            Fsck::fsckAll()
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("fsck-force", input) then
            Fsck::fsckAllForce()
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
            item = NxTodays::interactivelyIssueNewOrNull()
            return if item.nil?
            item = Blades::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("todays", input) then
            Operations::program3(lambda { 
                Blades::mikuType("NxToday")
            })
            return
        end

        if Interpreting::match("todos", input) then
            Orphans::dive()
            return
        end

        if Interpreting::match("tomorrow", input) then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            item = NxOndates::interactivelyIssueNewWithDetails(description, CommonUtils::tomorrow())
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("tomorrows", input) then
            Operations::program3(lambda { 
                Blades::mikuType("NxOndate")
                    .select{|item| item["date"] == CommonUtils::tomorrow() }
            })
            return
        end

        if Interpreting::match("ondate", input) then
            item = NxOndates::interactivelyIssueNewOrNull()
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ondates", input) then
            Operations::program3(lambda { 
                Blades::mikuType("NxOndate")
                    .sort_by{|item| item["date"] }
            })
            return
        end

        if Interpreting::match("skip * hours", input) then
            _, d, _ = Interpreting::tokenizer(input)
            item = store.getDefault()
            return if item.nil?
            Blades::setAttribute(item["uuid"], "skip-0843", Time.new.to_i+3600*d.to_f)
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
            item = Anniversary::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("anniversaries", input) then
            Operations::program3(lambda { 
                Blades::mikuType("Anniversary")
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

            if item["mikuType"] == "NxTimeCommitment" then
                puts "Nope! It's a NxTimeCommitment"
                LucilleCore::pressEnterToContinue()
                return
            end

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
            Blades::setAttribute(item["uuid"], "date", datetime)
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
                Blades::mikuType("Wave")
                    .sort_by{|item| item["lastDoneUnixtime"] }
            })
            return
        end
    end
end
