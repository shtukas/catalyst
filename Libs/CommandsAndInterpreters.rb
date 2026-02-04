# encoding: UTF-8

class CommandsAndInterpreters

    # CommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | ... | <datecode> | access (*) | start (*) | done (*) | program (*) | expose (*) | add time * | skip * hours (default item) | bank accounts * | payload (*) | bank data * | push * | * on <datecode> | edit * | destroy * | delist * | move (*) | time commitment * | transmute * | donation * | engine (*) | transmute * | dismiss | duration *",
            "NxListing     : dive (*)",
            "makers        : anniversary | wave | today | tomorrow | desktop | todo | ondate | on <weekday> | backup | priority | float | counter",
            "divings       : anniversaries | ondates | waves | desktop | backups | tomorrows | todays | floats | listings | engined | counters",
            "NxBalls       : start (*) | stop (*) | pause (*) | pursue (*)",
            "misc          : search | commands | fsck | fsck-force | maintenance | sort | resolve | wind",
        ].join("\n")
    end

    # CommandsAndInterpreters::interpreter(input, store)
    def self.interpreter(input, store)

        # We have a special handling for ++, which doesn't delist, unlike the other timecodes
        if Interpreting::match("++", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::stop(item)
            unixtime = Time.new.to_i + 3600
            puts "dot not show until: #{Time.at(unixtime).to_s}".yellow
            DoNotShowUntil::doNotShowUntil(item, unixtime)
            return
        end

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                PolyActions::stop(item)
                puts "dot not show until: #{Time.at(unixtime).to_s}".yellow
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
            Transmute::transmute(item)
            return
        end

        if Interpreting::match("resolve", input) then
            uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
            item = Blades::itemOrNull(uuid)
            if item.nil? then
                puts "could not resolve uuid: #{uuid}"
            else
                puts JSON.pretty_generate(item)
            end
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("dismiss", input) then
            item = store.getDefault()
            return if item.nil?
            unixtime = CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone()
            puts "dot not show until: #{Time.at(unixtime).to_s}".yellow
            DoNotShowUntil::doNotShowUntil(item, unixtime)
        end

        if Interpreting::match("transmute *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Transmute::transmute(item)
            return
        end

        if Interpreting::match("sort", input) then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["global", "priorities", "today special"])
            return if option.nil?

            if option == "global" then
                items  = FrontPage::itemsAndBucketPositionsForListing()
                            .map{|packet| packet["item"] }
                selected = CommonUtils::selectZeroOrMore(items, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|item|
                    Blades::setAttribute(item["uuid"], "nx42", ListingPosition::firstGlobalListingPosition() - 1)
                }
                return
            end

            if option == "priorities" then
                items  = FrontPage::itemsAndBucketPositionsForListing()
                            .select{|packet| packet["bucket&position"][0] == "priorities" }
                            .map{|packet| packet["item"] }
                selected = CommonUtils::selectZeroOrMore(items, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|item|
                    Blades::setAttribute(item["uuid"], "nx42", ListingPosition::newPrioritiesListingPosition())
                }
                return
            end

            if option == "today special" then
                items  = FrontPage::itemsAndBucketPositionsForListing()
                            .select{|packet| ["today special", "today", "today or next days"].include?(packet["bucket&position"][0]) }
                            .map{|packet| packet["item"] }
                selected = CommonUtils::selectZeroOrMore(items, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|item|
                    position = ListingPosition::newTodaySpecialListingPosition()
                    puts "#{PolyFunctions::toString(item).green} at position: #{position.to_s.green}"
                    Blades::setAttribute(item["uuid"], "nx42", position)
                }
                return
            end
        end

        if Interpreting::match("transmute *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Transmute::transmute(item)
            return
        end

        if Interpreting::match("duration *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            duration = LucilleCore::askQuestionAnswerAsString("duration in minutes : ").to_f
            Blades::setAttribute(item["uuid"], "duration-38", duration)
            return
        end

        if Interpreting::match("move", input) then
            item = store.getDefault()
            return if item.nil?
            Operations::move(item)
            return
        end

        if Interpreting::match("move *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Operations::move(item)
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

        if Interpreting::match("maintenance", input) then
            Operations::globalMaintenanceSync()
            return
        end

        if Interpreting::match("time commitment *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["mikuType"] == "NxTask" then
                hours = LucilleCore::askQuestionAnswerAsString("commitment per day in hours: ").to_f
                Blades::setAttribute(item["uuid"], "tc-15", hours)
                return
            end
            if item["mikuType"] == "NxToday" then
                hours = LucilleCore::askQuestionAnswerAsString("commitment per day in hours: ").to_f
                Blades::setAttribute(item["uuid"], "tc-15", hours)
                Blades::setAttribute(item["uuid"], "mikuType", "NxTask")
                return
            end
            puts "I do not know how to add a time commitment to a #{item["mikuType"]}"
            LucilleCore::pressEnterToContinue()
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
            Blades::setAttribute(item["uuid"], "nx42", ListingPosition::firstGlobalListingPosition() - 1)
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

        if Interpreting::match("listings", input) then
            NxListings::dive()
            return
        end

        if Interpreting::match("payload", input) then
            item = store.getDefault()
            return if item.nil?
            UxPayloads::payloadProgram(item)
            return
        end

        if Interpreting::match("engine", input) then
            item = store.getDefault()
            return if item.nil?
            NxEngines::setEngine(item)
            return
        end

        if Interpreting::match("engine *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxEngines::setEngine(item)
            return
        end

        if Interpreting::match("donation", input) then
            item = store.getDefault()
            return if item.nil?
            Donations::interactivelySetDonation(item)
            return
        end

        if Interpreting::match("donation *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Donations::interactivelySetDonation(item)
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
            return if item["mikuType"] != "NxListing"
            NxListings::diveListing(item["uuid"])
            return
        end

        if Interpreting::match("dive *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            return if item["mikuType"] != "NxListing"
            NxListings::diveListing(item["uuid"])
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

        if Interpreting::match("today *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["mikuType"] == "Wave" then
                uuid = SecureRandom.uuid
                Blades::init(uuid)
                Blades::setAttribute(uuid, "unixtime", Time.new.to_i)
                Blades::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
                Blades::setAttribute(uuid, "description", "wavelet: #{item["description"]}")
                Blades::setAttribute(uuid, "payload-37", item["payload-37"])
                Blades::setAttribute(uuid, "mikuType", "NxToday")
                wavelet = Blades::itemOrNull(uuid)
                puts JSON.pretty_generate(wavelet)
                Waves::performDone(item)
                return
            end
            puts "I do not know how to today * a #{item["mikuType"]}"
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("todays", input) then
            Operations::program3(lambda { 
                Blades::mikuType("NxToday")
            })
            return
        end

        if Interpreting::match("counter", input) then
            item = NxCounters::interactivelyIssueNewOrNull()
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("counters", input) then
            Operations::program3(lambda { 
                Blades::mikuType("NxCounter")
            })
            return
        end

        if Interpreting::match("float", input) then
            item = Floats::interactivelyIssueNewOrNull()
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("floats", input) then
            Operations::program3(lambda { 
                Blades::mikuType("Float")
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

        if Interpreting::match("tomorrows", input) then
            Operations::program3(lambda { 
                Blades::mikuType("NxOndate")
                    .select{|item| item["date"] == CommonUtils::tomorrow() }
            })
            return
        end

        if Interpreting::match("engined", input) then
            Operations::program3(lambda {
                Blades::items().select{|item| item["engine-24"] }
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
            item = NxEngines::setEngine(item)
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
                w1, w2 = Blades::mikuType("Wave").partition{|item| DoNotShowUntil::isVisible(item) }
                w2 + w1 # we put the done ones first
            })
            return
        end

        if input == "wind" then
            # We use wind 04 to avoid presenting them in the same order all the time
            # Once it's been presented, whether or notit's been actioned, it goes to the
            # end of the line
            Blades::mikuType("Wave")
                .select{|item| DoNotShowUntil::isVisible(item) }
                .sort_by{|item| item["wind-04"] || 0 }
                .reduce(0){|counter, item|
                    if counter < 10 then
                        Blades::setAttribute(item["uuid"], "wind-04", Time.new.to_i)
                        if LucilleCore::askQuestionAnswerAsBoolean("do '#{PolyFunctions::toString(item).green}' ? ") then
                            PolyActions::tripleDots(item)
                            counter = counter + 1
                        end
                    end
                    counter
                }
            return
        end

    end
end
