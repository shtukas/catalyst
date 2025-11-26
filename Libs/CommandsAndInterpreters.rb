# encoding: UTF-8

class CommandsAndInterpreters

    # CommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | ... | <datecode> | access (*) | start (*) | done (*) | program (*) | expose (*) | add time * | skip * hours (default item) | bank accounts * | payload (*) | bank data * | push * | * on <datecode> | edit * | destroy * | >> * (update behaviour) | delist * | lift * (promote to sequence carrier) | move * (move to sequence) | dive * (dive sequence items)",
            "makers        : anniversary | wave | today | tomorrow | desktop | todo | ondate | on <weekday> | backup | priority | priorities | project | await | in progress | polymorph | sequence item",
            "divings       : anniversaries | ondates | waves | desktop | backups | todays | projects | awaits",
            "NxBalls       : start (*) | stop (*) | pause (*) | pursue (*)",
            "misc          : search | commands | fsck | maintenance | sort",
        ].join("\n")
    end

    # CommandsAndInterpreters::interpreter(input, store)
    def self.interpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                PolyActions::stop(item)
                "dot not show until: #{Time.at(unixtime).to_s}".yellow
                Operations::doNotShowUntil(item, unixtime)
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
            Operations::doNotShowUntil(item, unixtime)
            return
        end

        if Interpreting::match(">> *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            behaviour = TxBehaviour::interactivelyMakeBehaviourOrNull()
            return if behaviour.nil?
            Items::setAttribute(item["uuid"], "bx42", behaviour)
            return
        end

        if Interpreting::match("sort", input) then
            items = store.items().select{|item| item["mikuType"] == "NxPolymorph" }
            selected, _ = LucilleCore::selectZeroOrMore("elements", [], items, lambda{|i| PolyFunctions::toString(i) })
            selected.reverse.each{|item|
                Items::setAttribute(item["uuid"], "nx41", {
                    "unixtime" => Time.new.to_f,
                    "position" => ListingPosition::firstNegativeListingPosition() - 1,
                })
            }
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

        if Interpreting::match("move", input) then
            item = store.getDefault()
            return if item.nil?
            Sequences::moveToSequence(item)
            return
        end

        if Interpreting::match("move *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Sequences::moveToSequence(item)
            return
        end

        if Interpreting::match("maintenance", input) then
            Operations::globalMaintenance()
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

        if Interpreting::match("sequence item", input) then
            positioning = Sequences::interactivelyDecidePositioningOrNull_ExistingSequence() # {"sequenceuuid", "ordinal"}
            return if positioning.nil?
            item = NxSequenceItem::interactivelyIssueNewGetReferenceOrNull(positioning["sequenceuuid"], positioning["ordinal"])
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("lift *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?

            # creating the new payload
            payload2uuid = UxPayloads::issueNewSequenceGetReference()

            # If there is an existing payload, we make it a sequence item
            if item["payload-uuid-1141"] then
                uuid2 = SecureRandom.uuid
                Items::init(uuid2)
                Items::setAttribute(uuid2, "unixtime", Time.new.to_i)
                Items::setAttribute(uuid2, "datetime", Time.new.utc.iso8601)
                Items::setAttribute(uuid2, "sequenceuuid", payload2["sequenceuuid"])
                Items::setAttribute(uuid2, "ordinal", 1)
                Items::setAttribute(uuid2, "description", "#{item["description"]} (lifted)")
                Items::setAttribute(uuid2, "payload-uuid-1141", item["payload-uuid-1141"])
                Items::setAttribute(uuid2, "mikuType", "NxSequenceItem")
                sequenceItem = Items::itemOrNull(uuid2)
                puts "sequenceItem: #{JSON.pretty_generate(sequenceItem)}"
            end

            # We create the carrier
            Items::setAttribute(item["uuid"], "payload-uuid-1141", payload2uuid)
            return
        end

        if Interpreting::match("unlift *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if Sequences::isNonEmptySequence(item) then
                puts "You cannot unlift a non empty sequence carrier"
                LucilleCore::pressEnterToContinue()
                return
            end
            Items::setAttribute(item["uuid"], "payload-uuid-1141", nil)
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
            NxPriorities::issue(description, ListingPosition::firstNegativeListingPosition() - 1)
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
                    item = NxPriorities::issue(line, ListingPosition::firstNegativeListingPosition() - 1)
                    last_item = item
                }
            if last_item then
                if LucilleCore::askQuestionAnswerAsBoolean("start ? ", true) then
                    PolyActions::start(last_item)
                end
            end
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
            payload = UxPayloads::makeNewPayloadOrNull()
            item = NxPolymorphs::issueNew(uuid, description, behaviour, payload)
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


        if Interpreting::match("dive *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if !Sequences::itemPayloadIsSequenceCarrier(item) then
                puts "You can only dive a sequence carrier"
                LucilleCore::pressEnterToContinue()
                return
            end
            payload = Items::itemOrNull(item["payload-uuid-1141"])
            sequenceuuid = payload["sequenceuuid"]
            lx = lambda {
                Sequences::sequenceElements(sequenceuuid)
                    .sort_by{|item| item["ordinal"] }
            }
            Operations::program3(lx)
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
                "date" => date
            }
            payload = UxPayloads::makeNewPayloadOrNull()
            item = NxPolymorphs::issueNew(uuid, description, behaviour, payload)
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
                "date" => date
            }
            payload = UxPayloads::makeNewPayloadOrNull()
            item = NxPolymorphs::issueNew(uuid, description, behaviour, payload)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("todays", input) then
            Operations::program3(lambda { 
                Items::mikuType("NxPolymorph")
                    .select{|item| item["bx42"]["btype"] == "ondate" } 
                    .select{|item| item["bx42"]["date"] <= CommonUtils::today() }
                    .sort_by{|item| item["bx42"]["date"] }
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
                "date" => date
            }
            payload = UxPayloads::makeNewPayloadOrNull()
            item = NxPolymorphs::issueNew(uuid, description, behaviour, payload)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ondate", input) then
            date = CommonUtils::interactivelyMakeADate()
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            uuid = SecureRandom.uuid
            Items::init(uuid)
            behaviour = {
                "btype" => "ondate",
                "date" => date
            }
            payload = UxPayloads::makeNewPayloadOrNull()
            item = NxPolymorphs::issueNew(uuid, description, behaviour, payload)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ondates", input) then
            Operations::program3(lambda { 
                Items::mikuType("NxPolymorph")
                    .select{|item| item["bx42"]["btype"] == "ondate" }
                    .sort_by{|item| item["bx42"]["date"] }
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
                Items::deleteObject(uuid)
                return
            end
            payload = UxPayloads::makeNewPayloadOrNull()
            item = NxPolymorphs::issueNew(uuid, description, behaviour, payload)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("morph *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            behaviour = TxBehaviour::interactivelyMakeBehaviourOrNull()
            return if behaviour.nil?
            Items::setAttribute(item["uuid"], "bx42", behaviour)
            return
        end

        if Interpreting::match("await", input) then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            uuid = SecureRandom.uuid
            Items::init(uuid)
            behaviour = {
                "btype" => "NxAwait"
            }
            payload = UxPayloads::makeNewPayloadOrNull()
            item = NxPolymorphs::issueNew(uuid, description, behaviour, payload)
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
            behaviour = Anniversary::makeNew()
            b1 = {
                "btype" => "do-not-show-until",
                "unixtime" => DateTime.parse("#{behaviour["next_celebration"]}T00:00:00Z").to_time.to_i
            }
            uuid = SecureRandom.uuid
            Items::init(uuid)
            payload = UxPayloads::makeNewPayloadOrNull()
            item = NxPolymorphs::issueNew(uuid, description, [b1, behaviour], payload)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("anniversaries", input) then
            Operations::program3(lambda { 
                Items::mikuType("NxPolymorph")
                    .select{|item| item["bx42"]["btype"] == "anniversary" }
                    .sort_by{|item| item["bx42"]["next_celebration"] }
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
            payload = UxPayloads::makeNewPayloadOrNull()
            item = NxPolymorphs::issueNew(uuid, description, behaviour, payload)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("project", input) then
            item = NxProjects::interactivelyIssueNewProjectOrNull()
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("projects", input) then
            NxProjects::program()
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
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            uuid = SecureRandom.uuid
            Items::init(uuid)
            behaviour = Wave::interactivelyMakeNewOrNull()
            payload = UxPayloads::makeNewPayloadOrNull()
            item = NxPolymorphs::issueNew(uuid, description, behaviour, payload)
            puts JSON.pretty_generate(item)
            return
        end

        if input == "waves" then
            Operations::program3(lambda { 
                Items::mikuType("NxPolymorph")
                    .select{|item| item["bx42"]["btype"] == "wave" }
                    .sort_by{|item| item["bx42"]["lastDoneUnixtime"] }
            })
            return
        end

        if Interpreting::match("await", input) then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return if description == ""
            uuid = SecureRandom.uuid
            Items::init(uuid)
            behaviour = {
                "btype" => "NxAwait"
            }
            payload = UxPayloads::makeNewPayloadOrNull()
            item = NxPolymorphs::issueNew(uuid, description, behaviour, payload)
            puts JSON.pretty_generate(item)
            return
        end
    end
end
