# encoding: UTF-8

class CommandsAndInterpreters

    # CommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | ... | <datecode> | access (*) | start (*) | done (*) | program (*) | expose (*) | add time * | skip * hours (default item) | bank accounts * | payload (*) | bank data * | push * | dismiss * | * on <datecode> | edit * | destroy * | >> * (update behaviour)",
            "makers        : anniversary | wave | today | tomorrow | desktop | todo | ondate | on <weekday> | backup | priority | priorities | project | event | await | in progress | polymorph",
            "divings       : anniversaries | ondates | waves | desktop | backups | todays | projects | projects | events | awaits",
            "NxBalls       : start (*) | stop (*) | pause (*) | pursue (*)",
            "misc          : search | commands | fsck | sort | maintenance | morning | recalibrate",
        ].join("\n")
    end

    # CommandsAndInterpreters::interpreter(input, store)
    def self.interpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                NxBalls::stop(item)
                "dot not show until: #{Time.at(unixtime).to_s}".yellow
                NxPolymorphs::doNotShowUntil(item, unixtime)
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
            NxBalls::stop(item)
            NxPolymorphs::doNotShowUntil(item, unixtime)
            return
        end

        if Interpreting::match(">> *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            behaviour = TxBehaviour::interactivelyMakeBehaviourOrNull()
            return if behaviour.nil?
            Items::setAttribute(item["uuid"], "behaviours", [behaviour] + item["behaviours"])
            return
        end

        if Interpreting::match("maintenance", input) then
            Operations::globalMaintenance()
            return
        end

        if Interpreting::match("morning", input) then
            Operations::morning()
            return
        end

        if Interpreting::match("recalibrate", input) then
            Operations::recalibrate()
            return
        end

        if Interpreting::match("sort", input) then
            items = store.items().select{|item| item["mikuType"] == "NxPolymorph" }
            cursor = NxPolymorphs::listingFirstPosition()
            selected, _ = LucilleCore::selectZeroOrMore("elements", [], items, lambda{|i| PolyFunctions::toString(i) })
            selected.reverse.each{|item|
                cursor = 0.95 * cursor
                behavior = {
                    "btype" => "listing-position",
                    "position" => cursor
                }
                Items::setAttribute(item["uuid"], "behaviours", [behavior] + item["behaviours"])
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
            NxPolymorphs::doNotShowUntil(item, unixtime)
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

        if Interpreting::match("priority", input) then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            Operations::issuePriority(description)
            return
        end

        if input.start_with?("priority ") then
            description = input[8, input.size].strip
            Operations::issuePriority(description)
            return
        end

        if Interpreting::match("priorities", input) then
            NxBalls::activeItems().each{|item| 
                NxBalls::pause(item)
            }
            last_item = nil
            Operations::interactivelyGetLinesUsingTextEditor()
                .reverse
                .each{|line|
                    puts "processing: #{line}".green
                    description = line

                    uuid = SecureRandom.uuid
                    behaviour = {
                        "btype" => "listing-position",
                        "position" => NxPolymorphs::listingFirstPosition()
                    }
                    Items::init(uuid)
                    payload = nil
                    item = NxPolymorphs::issueNew(uuid, description, [behaviour], nil)

                    last_item = item
                }
            if last_item then
                if LucilleCore::askQuestionAnswerAsBoolean("start ? ", true) then
                    PolyActions::start(last_item)
                end
            end
            return
        end

        if Interpreting::match("event", input) then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            uuid = SecureRandom.uuid
            behaviour = {
                 "btype" => "calendar-event",
                 "creationUnixtime" => Time.new.to_f,
                 "date" => CommonUtils::interactivelyMakeADate()
            }
            Items::init(uuid)
            payload = UxPayload::makeNewOrNull(uuid)
            item = NxPolymorphs::issueNew(uuid, description, [behaviour], payload)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("events", input) then
            Operations::program3ItemsWithGivenBehaviour("calendar-event")
            return
        end

        if Interpreting::match("backup", input) then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            period = LucilleCore::askQuestionAnswerAsString("period (in days): ").to_f
            uuid = SecureRandom.uuid
            Items::init(uuid)
            behaviour = {
                "btype" => "backup",
                "period" => period
            }
            payload = UxPayload::makeNewOrNull(uuid)
            item = NxPolymorphs::issueNew(uuid, description, [behaviour], payload)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("backups", input) then
            Operations::program3ItemsWithGivenBehaviour("backup")
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
            uuid = SecureRandom.uuid
            Items::init(uuid)
            behaviour = {
                "btype" => "ondate",
                "creationUnixtime" => Time.new.to_f,
                "date" => date
            }
            payload = UxPayload::makeNewOrNull(uuid)
            item = NxPolymorphs::issueNew(uuid, description, [behaviour], payload)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("today", input) then
            date = CommonUtils::today()
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            uuid = SecureRandom.uuid
            Items::init(uuid)
            behaviour = {
                "btype" => "ondate",
                "creationUnixtime" => Time.new.to_f,
                "date" => date
            }
            payload = UxPayload::makeNewOrNull(uuid)
            item = NxPolymorphs::issueNew(uuid, description, [behaviour], payload)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("todays", input) then
            Operations::program3(lambda { 
                Items::mikuType("NxPolymorph")
                    .select{|item| item["behaviours"].first["btype"] == "ondate" } 
                    .select{|item| item["behaviours"].first["date"] <= CommonUtils::today() }
                    .sort_by{|item| item["behaviours"].first["date"] }
            })
            return
        end

        if Interpreting::match("tomorrow", input) then
            date = CommonUtils::tomorrow()
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            uuid = SecureRandom.uuid
            Items::init(uuid)
            behaviour = {
                "btype" => "ondate",
                "creationUnixtime" => Time.new.to_f,
                "date" => date
            }
            payload = UxPayload::makeNewOrNull(uuid)
            item = NxPolymorphs::issueNew(uuid, description, [behaviour], payload)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ondate", input) then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            uuid = SecureRandom.uuid
            Items::init(uuid)
            behaviour = {
                "btype" => "ondate",
                "creationUnixtime" => Time.new.to_f,
                "date" => CommonUtils::interactivelyMakeADate()
            }
            payload = UxPayload::makeNewOrNull(uuid)
            item = NxPolymorphs::issueNew(uuid, description, [behaviour], payload)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ondates", input) then
            Operations::program3(lambda { 
                Items::mikuType("NxPolymorph")
                    .select{|item| item["behaviours"].first["btype"] == "ondate" } 
                    .select{|item| item["behaviours"].first["date"] <= CommonUtils::today() }
                    .sort_by{|item| item["behaviours"].first["date"] }
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

        if Interpreting::match("polymorph", input) then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            uuid = SecureRandom.uuid
            Items::init(uuid)
            behaviour = TxBehaviour::interactivelyMakeBehaviourOrNull()
            if behaviour.nil? then
                Items::deleteItem(uuid)
                return
            end
            payload = UxPayload::makeNewOrNull(uuid)
            item = NxPolymorphs::issueNew(uuid, description, [behaviour], payload)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("morph *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            behaviour = TxBehaviour::interactivelyMakeBehaviourOrNull()
            if behaviour.nil? then
                return
            end
            Items::setAttribute(item["uuid"], "behaviours", [behaviour])
            return
        end

        if Interpreting::match("await", input) then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            uuid = SecureRandom.uuid
            Items::init(uuid)
            behaviour = {
                "btype" => "NxAwait",
                "creationUnixtime" => Time.new.to_i
            }
            payload = UxPayload::makeNewOrNull(uuid)
            item = NxPolymorphs::issueNew(uuid, description, [behaviour], payload)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("awaits", input) then
            Operations::program3ItemsWithGivenBehaviour("NxAwait")
            return
        end

        if Interpreting::match("anniversary", input) then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            behaviour = TxBehaviourAnniversary::makeNew()
            b1 = {
                "btype" => "do-not-show-until",
                "unixtime" => DateTime.parse("#{behaviour["next_celebration"]}T00:00:00Z").to_time.to_i
            }
            uuid = SecureRandom.uuid
            Items::init(uuid)
            payload = UxPayload::makeNewOrNull(uuid)
            item = NxPolymorphs::issueNew(uuid, description, [b1, behaviour], payload)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("anniversaries", input) then
            Operations::program3(lambda { 
                Items::mikuType("NxPolymorph")
                    .select{|item| NxPolymorphs::itemHasBehaviour(item, "anniversary") }
                    .sort_by{|item| 
                        item["behaviours"]
                            .select{|behaviour| behaviour["btype"] == "anniversary" }
                            .first["next_celebration"]
                    }
            })
            return
        end

        if Interpreting::match("todo", input) then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            behaviour = {
                "btype" => "task",
                "unixtime" => Time.new.to_i
            }
            uuid = SecureRandom.uuid
            Items::init(uuid)
            payload = UxPayload::makeNewOrNull(uuid)
            item = NxPolymorphs::issueNew(uuid, description, [behaviour], payload)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("project", input) then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            timeCommitment = NxTimeCommitment::interactivelyMakeNewOrNull()
            return if timeCommitment.nil?
            behaviour = {
                "btype" => "project",
                "timeCommitment" => timeCommitment
            }
            uuid = SecureRandom.uuid
            Items::init(uuid)
            payload = UxPayload::makeNewOrNull(uuid)
            item = NxPolymorphs::issueNew(uuid, description, [behaviour], payload)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("projects", input) then
            Operations::program3ItemsWithGivenBehaviour("project")
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
            NxBalls::stop(item)
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
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            uuid = SecureRandom.uuid
            Items::init(uuid)
            behaviour = TxBehaviourWave::interactivelyMakeNewOrNull()
            payload = UxPayload::makeNewOrNull(uuid)
            item = NxPolymorphs::issueNew(uuid, description, [behaviour], payload)
            puts JSON.pretty_generate(item)
            return
        end

        if input == "waves" then
            Operations::program3(lambda { 
                Items::mikuType("NxPolymorph")
                    .select{|item| NxPolymorphs::itemHasBehaviour(item, "wave") }
                    .sort_by{|item| 
                        item["behaviours"]
                            .select{|behaviour| behaviour["btype"] == "wave" }
                            .first["lastDoneUnixtime"]
                    }
            })
            return
        end

        if Interpreting::match("await", input) then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            uuid = SecureRandom.uuid
            Items::init(uuid)
            behaviour = {
                "btype" => "NxAwait",
                "creationUnixtime" => Time.new.to_i
            }
            payload = UxPayload::makeNewOrNull(uuid)
            item = NxPolymorphs::issueNew(uuid, description, [behaviour], payload)
            puts JSON.pretty_generate(item)
            return
        end
    end
end
