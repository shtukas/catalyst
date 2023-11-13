# encoding: UTF-8

class ListingCommandsAndInterpreters

    # ListingCommandsAndInterpreters::commands()
    def self.commands()
        [
            "on items : .. | <datecode> | access (<n>) | push (<n>) # do not show until | done (<n>) | program (<n>) | expose (<n>) | add time <n> | coredata (<n>) | skip (<n>) | unstack * | pile * | engine * | donation * | move * | move # multiple to core | active * | destroy (<n>)",
            "",
            "Transmutations:",
            "              : (task)   >ondate (<n>)",
            "              : (ondate) >task (<n>)",
            "",
            "mikuTypes:",
            "   - NxOndate : redate (*)",
            "",
            "makers        : anniversary | manual-countdown | wave | today | tomorrow | ondate | task | core | desktop",
            "divings       : anniversaries | ondates | waves | desktop | cores | engined",
            "NxBalls       : start | start (<n>) | stop | stop (<n>) | pause | pursue",
            "misc          : search | speed | commands | edit <n> | move | >> # push intelligently",
        ].join("\n")
    end

    # ListingCommandsAndInterpreters::interpreter(input, store)
    def self.interpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                Updates::itemAttributeUpdate(item["uuid"], "trajectory", nil)
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        if Interpreting::match("..", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::naturalProgression(item)
            return
        end

        if Interpreting::match(".. *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::naturalProgression(item)
            return
        end

        if Interpreting::match(">task", input) then
            item = store.getDefault()
            return if item.nil?
            if item["mikuType"] != "NxOndate" then
                puts "For the moment we only run >task on buffer in NxOndates"
                LucilleCore::pressEnterToContinue()
                return
            end
            status = TxCores::interactivelySelectAndPutInCore(item)
            return if !status
            Updates::itemAttributeUpdate(item["uuid"], "mikuType", "NxTask")
            return
        end

        if Interpreting::match(">task *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["mikuType"] != "NxOndate" then
                puts "For the moment we only run >task on buffer in NxOndates"
                LucilleCore::pressEnterToContinue()
                return
            end
            status = TxCores::interactivelySelectAndPutInCore(item)
            return if !status
            Updates::itemAttributeUpdate(item["uuid"], "mikuType", "NxTask")
            return
        end

        if Interpreting::match(">ondate", input) then
            item = store.getDefault()
            return if item.nil?
            if item["mikuType"] != "NxTask" then
                puts "For the moment we only run >ondate on NxTasks"
                LucilleCore::pressEnterToContinue()
                return
            end
            Updates::itemAttributeUpdate(item["uuid"], "description", item["description"].gsub("(buffer-in)", "").strip)
            Updates::itemAttributeUpdate(item["uuid"], "datetime", CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode())
            Updates::itemAttributeUpdate(item["uuid"], "mikuType", "NxOndate")
            return
        end

        if Interpreting::match(">ondate *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["mikuType"] != "NxTask" then
                puts "For the moment we only run >ondate on NxTasks"
                LucilleCore::pressEnterToContinue()
                return
            end
            Updates::itemAttributeUpdate(item["uuid"], "description", item["description"].gsub("(buffer-in)", "").strip)
            Updates::itemAttributeUpdate(item["uuid"], "datetime", CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode())
            Updates::itemAttributeUpdate(item["uuid"], "mikuType", "NxOndate")
            return
        end

        if Interpreting::match("active * ", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Updates::itemAttributeUpdate(item["uuid"], "active", true)
            return
        end

        if Interpreting::match("pile * ", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxStrats::interactivelyPile(item)
            return
        end

        if Interpreting::match("today", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match(">>", input) then
            item = store.getDefault()
            return if item.nil?

            getNextManagedCursor = (lambda {
                cursor = XCache::getOrNull("0c441bf5-b565-4207-acb4-1a6b2e6817d3")
                if cursor.nil? then
                    cursor = Time.new.to_f
                else
                    cursor = cursor.to_f
                end
                cursor = cursor + 3600*3
                loop {
                    time = Time.at(cursor)
                    if time.hour < 8 then
                        cursor = cursor + 3600
                        next
                    end
                    if time.hour > 21 then
                        cursor = cursor + 3600
                        next
                    end
                    break
                }
                XCache::set("0c441bf5-b565-4207-acb4-1a6b2e6817d3", cursor)
                return cursor
            })

            cursor = (lambda {|item|
                if item["mikuType"] == "PhysicalTarget" then
                    return Time.new.to_f + 3600 + rand*3600
                end
                if item["mikuType"] == "Wave" and item["interruption"] then
                    return Time.new.to_f + 3600 + rand*3600
                end
                if item["mikuType"] == "Wave" and !item["interruption"] then
                    return getNextManagedCursor.call()
                end
                if item["mikuType"] == "NxOndate" then
                    return getNextManagedCursor.call()
                end
                if item["mikuType"] == "NxTask" then
                    return getNextManagedCursor.call()
                end
                raise "I don't know how to >> mikuType: #{item["mikuType"].green}"
            }).call(item)

            puts "Pushing '#{PolyFunctions::toString(item).green}' to #{Time.at(cursor).utc.iso8601}"
            DoNotShowUntil::setUnixtime(item["uuid"], cursor)
            return
        end

        if Interpreting::match("donation *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            core = TxCores::interactivelySelectOneOrNull()
            return if core.nil?
            if item["donation-1605"].nil? then
                donations = [core["uuid"]]
            else
                donations = (item["donation-1605"] + [core["uuid"]]).uniq.select{|uuid| !Catalyst::itemOrNull(uuid).nil? }
            end
            Updates::itemAttributeUpdate(item["uuid"], "donation-1605", donations)
            return
        end

        if Interpreting::match("move", input) then
            items = store.items().select{|i| ["NxTask", "TxCore"].include?(i["mikuType"])}
            Catalyst::selectSubsetAndMoveToSelectedCore(items)
            return
        end

        if Interpreting::match("move *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            TxCores::interactivelySelectAndPutInCore(item)
            return
        end

        if Interpreting::match("skip", input) then
            item = store.getDefault()
            return if item.nil?
            Updates::itemAttributeUpdate(item["uuid"], "tmpskip1", CommonUtils::today())
            return
        end

        if Interpreting::match("skip *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Updates::itemAttributeUpdate(item["uuid"], "tmpskip1", CommonUtils::today())
            return
        end

        if Interpreting::match("task", input) then
            item = NxTasks::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["core", "engine", "ondate"])
            return if option.nil?
            if option == "core" then
                core = TxCores::interactivelySelectOneOrNull()
                if core then
                    Updates::itemAttributeUpdate(item["uuid"], "coreX-2137", core["uuid"])
                end
            end
            if option == "engine" then
                engine = TxEngines::interactivelyMakeNewOrNull()
                if engine then
                    Updates::itemAttributeUpdate(item["uuid"], "engine-0916", engine)
                end
            end
            if option == "ondate" then
                datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
                Updates::itemAttributeUpdate(item["uuid"], "datetime", datetime)
                Updates::itemAttributeUpdate(item["uuid"], "mikuType", "NxOndate")
            end
            return
        end

        if Interpreting::match("core", input) then
            item = TxCores::interactivelyIssueNewOrNull()
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

        if Interpreting::match("coredata", input) then
            item = store.getDefault()
            return if item.nil?
            reference =  CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(item["uuid"])
            return if reference.nil?
            Updates::itemAttributeUpdate(item["uuid"], "field11", reference)
            return
        end

        if Interpreting::match("coredata *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            reference =  CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(item["uuid"])
            return if reference.nil?
            Updates::itemAttributeUpdate(item["uuid"], "field11", reference)
            return
        end

        if Interpreting::match("commands", input) then
            puts ListingCommandsAndInterpreters::commands().yellow
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

        if Interpreting::match("engine", input) then
            item = store.getDefault()
            return if item.nil?
            if !["TxCore", "NxTask", "NxOndate"].include?(item["mikuType"]) then
                puts "At the moment we are only doing engines for TxCore, NxTask and NxOndate"
                LucilleCore::pressEnterToContinue()
                return
            end
            engine = TxEngines::interactivelyMakeNewOrNull()
            return if engine.nil?
            Updates::itemAttributeUpdate(item["uuid"], "engine-0916", engine)
            return
        end

        if Interpreting::match("engine *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if !["TxCore", "NxTask", "NxOndate"].include?(item["mikuType"]) then
                puts "At the moment we are only doing engines for TxCore, NxTask and NxOndate"
                LucilleCore::pressEnterToContinue()
                return
            end
            engine = TxEngines::interactivelyMakeNewOrNull()
            return if engine.nil?
            Updates::itemAttributeUpdate(item["uuid"], "engine-0916", engine)
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

        if Interpreting::match("destroy", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::destroy(item)
            return
        end

        if Interpreting::match("destroy *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::destroy(item)
            return
        end

        if Interpreting::match("push", input) then
            item = store.getDefault()
            return if item.nil?
            unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
            return if unixtime.nil?
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            return
        end

        if Interpreting::match("push *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
            return if unixtime.nil?
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            return
        end

        if Interpreting::match("expose", input) then
            item = store.getDefault()
            return if item.nil?
            puts JSON.pretty_generate(item)
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("expose *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            puts JSON.pretty_generate(item)
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

        if Interpreting::match("cores", input) then
            cores = Catalyst::mikuType("TxCore")
                        .sort_by{|item| TxEngines::dailyRelativeCompletionRatio(item["engine-0916"]) }
            Catalyst::program2(cores)
            return
        end

        if Interpreting::match("engined", input) then
            items = Catalyst::catalystItems()
                        .select{|item| item["engine-0916"] }
                        .sort_by{|item| TxEngines::dailyRelativeCompletionRatio(item["engine-0916"]) }
            Catalyst::program2(items)
            return
        end

        if Interpreting::match("actives", input) then
            items = Catalyst::catalystItems()
                        .select{|item| item["active"] }
            Catalyst::program2(items)
            return
        end

        if Interpreting::match("ondates", input) then
            items = Catalyst::mikuType("NxOndate")
                        .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            Catalyst::program2(items)
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

        if Interpreting::match("unstack *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            Updates::itemAttributeUpdate(item["uuid"], "ordinal-1051", nil)
            return
        end

        if Interpreting::match("redate", input) then
            item = store.getDefault()
            return if item.nil?
            if item["mikuType"] != "NxOndate" then
                puts "redate is reserved for NxOndates"
                LucilleCore::pressEnterToContinue()
                return
            end
            NxBalls::stop(item)
            NxOndates::redate(item)
            return
        end

        if Interpreting::match("redate *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["mikuType"] != "NxOndate" then
                puts "redate is reserved for NxOndates"
                LucilleCore::pressEnterToContinue()
                return
            end
            NxBalls::stop(item)
            NxOndates::redate(item)
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
                Updates::itemAttributeUpdate(item["uuid"], "ordinal-1051", nil)
            end
            Updates::itemAttributeUpdate(item["uuid"], "trajectory", nil)
            NxBalls::stop(item)
            return
        end

        if Interpreting::match("stop *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["ordinal-1051"] then
                Updates::itemAttributeUpdate(item["uuid"], "ordinal-1051", nil)
            end
            Updates::itemAttributeUpdate(item["uuid"], "trajectory", nil)
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
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            Updates::itemAttributeUpdate(item["uuid"], "datetime", "#{CommonUtils::nDaysInTheFuture(1)} 07:00:00+00:00")
            return
        end

        if input == "wave" then
            item = Waves::issueNewWaveInteractivelyOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if input == "waves" then
            Waves::program1()
            return
        end

        if Interpreting::match("speed", input) then
            LucilleCore::pressEnterToContinue()
            return
        end
    end
end
