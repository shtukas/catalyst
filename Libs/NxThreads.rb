
class NxThreads

    # -----------------------------------------------
    # Build

    # NxThreads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        hours = LucilleCore::askQuestionAnswerAsString("weekly hours (empty for abort): ")
        return nil if hours == ""
        hours = hours.to_f
        return nil if hours == 0

        uuid = SecureRandom.uuid
        Updates::itemInit(uuid, "NxThread")

        Updates::itemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Updates::itemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Updates::itemAttributeUpdate(uuid, "description", description)
        Updates::itemAttributeUpdate(uuid, "hours", hours)
        Updates::itemAttributeUpdate(uuid, "lastResetTime", Time.new.to_f)
        Updates::itemAttributeUpdate(uuid, "capsule", SecureRandom.hex)
        Updates::itemAttributeUpdate(uuid, "global-position", rand)

        Catalyst::itemOrNull(uuid)
    end

    # -----------------------------------------------
    # Data

    # NxThreads::periodCompletionRatio(item)
    def self.periodCompletionRatio(item)
        Bank::getValue(item["capsule"]).to_f/(item["hours"]*3600)
    end

    # NxThreads::toString(item)
    def self.toString(item)
        strings = []

        padding = XCache::getOrDefaultValue("bf986315-dfd7-44e2-8f00-ebea0271e2b2", "0").to_i

        strings << "🧶 #{item["description"].ljust(padding)}: today: #{"#{"%6.2f" % (100*Catalyst::listingCompletionRatio(item))}%".green} of #{"%5.2f" % (item["hours"].to_f/5)} hours"
        strings << ", period: #{"#{"%6.2f" % (100*NxThreads::periodCompletionRatio(item))}%".green} of #{"%5.2f" % item["hours"]} hours"

        hasReachedObjective = Bank::getValue(item["capsule"]) >= item["hours"]*3600
        timeSinceResetInDays = (Time.new.to_i - item["lastResetTime"]).to_f/86400
        itHassBeenAWeek = timeSinceResetInDays >= 7

        if hasReachedObjective and itHassBeenAWeek then
            strings << ", awaiting data management"
        end

        if hasReachedObjective and !itHassBeenAWeek then
            strings << ", objective met, #{(7 - timeSinceResetInDays).round(2)} days before reset"
        end

        if !hasReachedObjective and !itHassBeenAWeek then
            strings << ", #{(item["hours"] - Bank::getValue(item["capsule"]).to_f/3600).round(2)} hours to go, #{(7 - timeSinceResetInDays).round(2)} days left in period"
        end

        if !hasReachedObjective and itHassBeenAWeek then
            strings << ", late by #{(timeSinceResetInDays-7).round(2)} days"
        end

        strings << ""
        strings.join()
    end

    # NxThreads::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = Catalyst::mikuType("NxThread")
                    .sort_by {|item| Catalyst::listingCompletionRatio(item) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| NxThreads::toString(item) })
    end

    # NxThreads::listingItems()
    def self.listingItems()
        Catalyst::mikuType("NxThread")
            .sort_by{|item| Catalyst::listingCompletionRatio(item) }
    end

    # -----------------------------------------------
    # Ops

    # NxThreads::maintenance1(item) # item or null
    def self.maintenance1(item)
        return if NxBalls::itemIsActive(item)
        return nil if Bank::getValue(item["capsule"]).to_f/3600 < item["hours"]
        return nil if (Time.new.to_i - item["lastResetTime"]) < 86400*7
        puts "> I am about to reset item for #{item["description"]}"
        LucilleCore::pressEnterToContinue()
        Bank::put(item["capsule"], -item["hours"]*3600)
        if !LucilleCore::askQuestionAnswerAsBoolean("> continue with #{item["hours"]} hours ? ") then
            hours = LucilleCore::askQuestionAnswerAsString("specify period load in hours (empty for the current value): ")
            if hours.size > 0 then
                item["hours"] = hours.to_f
            end
        end
        item["lastResetTime"] = Time.new.to_i
        Updates::itemAttributeUpdate(item["uuid"], "hours", item["hours"])
        Updates::itemAttributeUpdate(item["uuid"], "lastResetTime", item["lastResetTime"])
    end

    # NxThreads::maintenance2()
    def self.maintenance2()
        Catalyst::mikuType("NxThread").each{|item| NxThreads::maintenance1(item) }
    end

    # NxThreads::maintenance3()
    def self.maintenance3()
        padding = (Catalyst::mikuType("NxThread").map{|item| item["description"].size } + [0]).max
        XCache::set("bf986315-dfd7-44e2-8f00-ebea0271e2b2", padding)
    end

    # NxThreads::pile3(item)
    def self.pile3(item)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text
            .lines
            .map{|line| line.strip }
            .reverse
            .each{|line|
                task = NxTasks::descriptionToTask1(SecureRandom.uuid, line)
                puts JSON.pretty_generate(task)
                Updates::itemAttributeUpdate(task["uuid"], "parent-1328", item["uuid"])
            }
    end

    # NxThreads::program1(thread)
    def self.program1(thread)
        loop {

            thread = Catalyst::itemOrNull(thread["uuid"])
            return if thread.nil?

            system("clear")

            store = ItemStore.new()

            puts  ""
            store.register(thread, false)
            puts  Listing::toString2(store, thread)
            puts  ""

            Catalyst::children(thread)
                .each{|thread|
                    store.register(thread, Listing::canBeDefault(thread))
                    puts  "(#{"%6.2f" % (thread["global-position"] || 0)}) #{Listing::toString2(store, thread)}"
                }

            puts ""
            puts "task | pile | position * | sort | move"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Updates::itemAttributeUpdate(task["uuid"], "parent-1328", thread["uuid"])
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                Updates::itemAttributeUpdate(task["uuid"], "global-position", position)
                next
            end

            if input == "pile" then
                NxThreads::pile3(thread)
                next
            end

            if Interpreting::match("position *", input) then
                _, listord = Interpreting::tokenizer(input)
                item = store.get(listord.to_i)
                next if item.nil?
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                Updates::itemAttributeUpdate(item["uuid"], "global-position", position)
                next
            end

            if Interpreting::match("sort", input) then
                items = Catalyst::children(thread)
                selected, _ = LucilleCore::selectZeroOrMore("items", [], items, lambda{|item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    Updates::itemAttributeUpdate(item["uuid"], "global-position", Catalyst::newGlobalFirstPosition())
                }
                next
            end

            if input == "move" then
                selected, _ = LucilleCore::selectZeroOrMore(Catalyst::children(thread))
                next if selected.empty?
                target = NxThreads::interactivelySelectOneOrNull()
                next if target["uuid"] == thread["uuid"]
                selected.each{|item|
                    Updates::itemAttributeUpdate(task["uuid"], "parent-1328", target["uuid"])
                }
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxThreads::program2()
    def self.program2()
        loop {
            item = NxThreads::interactivelySelectOneOrNull()
            return if item.nil?
            NxThreads::program1(item)
        }
    end
end
