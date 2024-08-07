# encoding: UTF-8

class CommandsAndInterpreters

    # CommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | <datecode> | access (<n>) | push <n> # do not show until | done (<n>) | program (<n>) | expose (<n>) | add time <n> | skip (<n>) | bank accounts * | donation * | payload * | parent * | bank data * | hours * | move * | condition * | move * | transmute * | mini * | destroy *",
            "",
            "makers        : anniversary | manual-countdown | wave | today | tomorrow | ondate | task | desktop | stack | float | thread | core | mini | pile",
            "divings       : anniversaries | ondates | waves | desktop | backups | floats | cores | minis",
            "NxBalls       : start | start (<n>) | stop | stop (<n>) | pause | pursue",
            "misc          : search | speed | commands | edit <n> | > (move default) | sort",
        ].join("\n")
    end

    # CommandsAndInterpreters::interpreter(input, store)
    def self.interpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                NxBalls::stop(item)
                DoNotShowUntil1::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        if Interpreting::match(">", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            parent = Catalyst::interactivelySelectOneHierarchyParentOrNull(nil)
            return if parent.nil?
            position = Catalyst::interactivelySelectPositionInParent(parent)
            Items::setAttribute(item["uuid"], "parentuuid-0032", parent["uuid"])
            Items::setAttribute(item["uuid"], "global-positioning", position)
            return
        end

        if Interpreting::match("..", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::doubledots(item)
            return
        end

        if Interpreting::match(".. *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::doubledots(item)
            return
        end

        if Interpreting::match("''", input) then
            puts "activating condition toggle"
            cx11 = Cx11s::interactivelySelectCx11OrNull()
            return if cx11.nil?
            cx11["status"] = !cx11["status"]
            Cx11s::getItemsByConditionName(Items::items(), cx11["name"]).each{|item|
                Cx11s::setCondition(item, cx11)
            }
            return
        end

        if Interpreting::match("'' *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            puts "select Cx11 for '#{PolyFunctions::toString(item).green}'"
            cx11 = Cx11s::architectNewOrNull()
            return if cx11.nil?
            Cx11s::setCondition(item, cx11)
            return
        end

        if Interpreting::match("transmute *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Transmutations::transmute1(item)
            return
        end

        if Interpreting::match("move *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            parent = Catalyst::interactivelySelectOneHierarchyParentOrNull(nil)
            return if parent.nil?
            position = Catalyst::interactivelySelectPositionInParent(parent)
            Items::setAttribute(item["uuid"], "parentuuid-0032", parent["uuid"])
            Items::setAttribute(item["uuid"], "global-positioning", position)
            return
        end

        if Interpreting::match("sort", input) then
            items = Listing::items()
            items = items.select{|item| Cx11s::itemShouldBeListed(item) }
            items = Listing::applyListingOverridePosition(items)

            selected, _ = LucilleCore::selectZeroOrMore("elements", [], items, lambda{|i| PolyFunctions::toString(i) })
            selected.reverse.each{|item|
                Items::setAttribute(item["uuid"], "listing-override-position-14", {
                        "date" => CommonUtils::today(),
                        "position" => Listing::getTopListingOverridePosition()-1
                    })
            }
        end

        if Interpreting::match("pile", input) then
            Catalyst::interactivelyGetLinesParentToChildren()
                .each{|description|
                    item = NxOndates::interactivelyIssueAtTodayFromDescription(description)
                    Items::setAttribute(item["uuid"], "listing-override-position-14", {
                        "date" => CommonUtils::today(),
                        "position" => Listing::getTopListingOverridePosition()-1
                    })
                    cursor = item
                }
            return
        end

        if Interpreting::match("pile *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Catalyst::interactivelyPile(item)
            return
        end

        if Interpreting::match("donation * ", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Catalyst::interactivelySetDonation(item)
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
            puts Bank1::getRecords(item["uuid"]).sort_by{|record| record["_date_"] }
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("backups", input) then
            items = Items::mikuType("NxBackup").sort_by{|item| item["description"] }
            Catalyst::program2(items)
            return
        end

        if Interpreting::match("payload *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            payload = UxPayload::makeNewOrNull()
            return if payload.nil?
            Items::setAttribute(item["uuid"], "uxpayload-b4e4", payload)
            return
        end

        if Interpreting::match("mini *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxMiniProjects::transformToMini(item)
            return
        end

        if Interpreting::match("parent *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            parent = Catalyst::interactivelySelectOneHierarchyParentOrNull(nil)
            return if parent.nil?
            Items::setAttribute(item["uuid"], "parentuuid-0032", parent["uuid"])
            return
        end

        if Interpreting::match("hours *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if !["NxCollection", "NxTask"].include?(item["mikuType"]) then
                puts "You can only set hours to NxCollection and NxTask"
                LucilleCore::pressEnterToContinue()
                return
            end
            hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
            hours = (hours == 0) ? 1 : hours
            Items::setAttribute(item["uuid"], "hours-1905", hours)
            return
        end

        if Interpreting::match("thread", input) then
            thread = NxCollections::interactivelyIssueNewOrNull()
            return if thread.nil?
            puts JSON.pretty_generate(thread)
            puts "select parent"
            parent = Catalyst::interactivelySelectOneHierarchyParentOrNull(nil)
            return if parent.nil?
            Items::setAttribute(thread["uuid"], "parentuuid-0032", parent["uuid"])
            return
        end

        if Interpreting::match("today", input) then
            item = NxOndates::interactivelyIssueAtDatetimeNewOrNull(CommonUtils::nowDatetimeIso8601())
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

        if Interpreting::match("task", input) then
            item = NxTasks::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            parent = Catalyst::interactivelySelectOneHierarchyParentOrNull(nil)
            return if parent.nil?
            Items::setAttribute(item["uuid"], "parentuuid-0032", parent["uuid"])
            position = Catalyst::interactivelySelectPositionInParent(parent)
            Items::setAttribute(item["uuid"], "global-positioning", position)
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

        if Interpreting::match("mini", input) then
            NxMiniProjects::interactivelyIssueNewOrNull()
            return
        end

        if Interpreting::match("floats", input) then
            items = Items::mikuType("NxFloat").sort_by{|item| item["unixtime"] }
            Catalyst::program2(items)
            return
        end

        if Interpreting::match("minis", input) then
            items = Items::mikuType("NxMiniProject").sort_by{|item| item["unixtime"] }
            Catalyst::program2(items)
            return
        end

        if Interpreting::match("cores", input) then
            TxCores::program2()
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

        if Interpreting::match("edit *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Catalyst::editItem(item)
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

        if Interpreting::match("move *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            return if item["mikuType"] != "NxTask"
            NxCollections::move(item)
            return
        end

        if Interpreting::match("push *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            puts "push '#{PolyFunctions::toString(item).green}'"
            unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
            return if unixtime.nil?
            NxBalls::stop(item)
            puts "pushing until '#{Time.at(unixtime).to_s.green}'"
            DoNotShowUntil1::setUnixtime(item["uuid"], unixtime)
            return
        end

        if Interpreting::match("expose", input) then
            item = store.getDefault()
            return if item.nil?
            puts JSON.pretty_generate(item)
            puts "Do not show until: #{DoNotShowUntil1::getUnixtimeOrNull(item["uuid"])}"
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("expose *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            puts JSON.pretty_generate(item)
            puts "Do not show until: #{DoNotShowUntil1::getUnixtimeOrNull(item["uuid"])}"
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

        if Interpreting::match("manual-countdown", input) then
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
            elements = Items::mikuType("NxOndate").sort_by{|item| item["datetime"] }
            Catalyst::program2(elements)
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
            Items::setAttribute(item["uuid"], "datetime", datetime)
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
            if item["ordinal-1051"] then
                Items::setAttribute(item["uuid"], "ordinal-1051", nil)
            end
            NxBalls::stop(item)
            return
        end

        if Interpreting::match("stop *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["ordinal-1051"] then
                Items::setAttribute(item["uuid"], "ordinal-1051", nil)
            end
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

        if Interpreting::match("tomorrow", input) then
            item = NxOndates::interactivelyIssueAtDatetimeNewOrNull(CommonUtils::tomorrow())
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
