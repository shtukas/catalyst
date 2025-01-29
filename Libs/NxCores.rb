
class NxCores

    # NxCores::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        payload = UxPayload::makeNewOrNull(uuid)
        hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
        Items::itemInit(uuid, "NxCore")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "hours", hours)
        Items::itemOrNull(uuid)
    end

    # NxCores::interactivelySelectPrefixMode()
    def self.interactivelySelectPrefixMode()
        loop {
            options = ["strictly-sequential", "choice", "top3-bank-order", "all-bank-order"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("prefix mode", options)
            return option if option
        }
    end

    # ------------------
    # Data

    # NxCores::ratio(item)
    def self.ratio(item)
        hours = item["hours"].to_f
        [Bank1::recoveredAverageHoursPerDay(item["uuid"]), 0].max.to_f/(hours/7)
    end

    # NxCores::ratioString(item)
    def self.ratioString(item)
        "(#{"%6.2f" % (100 * NxCores::ratio(item))} %; #{"%5.2f" % item["hours"]} h/w)".yellow
    end

    # NxCores::ratioPrelude(item)
    def self.ratioPrelude(item)
        "(#{"%5.3f" % NxCores::ratio(item)})".green
    end

    # NxCores::toString(item)
    def self.toString(item)
        "⏱️  #{NxCores::ratioPrelude(item)} #{item["description"]} #{NxCores::ratioString(item)}"
    end

    # NxCores::inRatioOrder()
    def self.inRatioOrder()
        Items::mikuType("NxCore").sort_by{|item| NxCores::ratio(item) }
    end

    # NxCores::listingItems(usePrecomputation = false)
    def self.listingItems(usePrecomputation = false)
        if usePrecomputation then
            return Precomputations::coresForListing()
        end
        Items::mikuType("NxCore")
            .select{|item| NxCores::ratio(item) < 1 }
            .sort_by{|item| NxCores::ratio(item) }
    end

    # NxCores::interactivelySelectOrNull()
    def self.interactivelySelectOrNull()
        items = Items::mikuType("NxCore").sort_by{|item| NxCores::ratio(item) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("target", items, lambda{|item| PolyFunctions::toString(item) })
    end

    # NxCores::infinityuuid()
    def self.infinityuuid()
        "427bbceb-923e-4feb-8232-05883553bb28"
    end

    # NxCores::totalHoursPerWeek()
    def self.totalHoursPerWeek()
        Items::mikuType("NxCore").map{|item| item["hours"] }.sum
    end

    # NxCores::bankingCorrectionFactor()
    def self.bankingCorrectionFactor()
        [NxCores::totalHoursPerWeek().to_f/84 , 1].max
    end

    # ------------------
    # Ops

    # NxCores::program1(core)
    def self.program1(core)

        if core["description"].start_with?("[open cycle]") then
            puts "You cannot { land on / program } #{PolyFunctions::toString(core).green} (starts with `[open cycle]`)"
            LucilleCore::pressEnterToContinue()
            return
        end

        loop {

            core = Items::itemOrNull(core["uuid"])
            return if core.nil?

            #system("clear")

            store = ItemStore.new()

            puts ""

            store.register(core, false)
            puts Listing::toString2(store, core)

            puts ""

            [
                PolyFunctions::naturalChildren(core).sort_by{|item| item["global-positioning-4233"] },
                PolyFunctions::computedChildren(core).sort_by{|item| item["global-positioning-4233"] }
            ]
                .flatten
                .sort_by{|item| item["global-positioning-4233"] }
                .each{|element|
                    store.register(element, Listing::canBeDefault(element))
                    puts Listing::toString2(store, element)
                }

            puts ""

            puts "todo (here, with position selection) | hours | pile | position * | move * | sort"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                todo = NxTasks::interactivelyIssueNewOrNull()
                next if todo.nil?
                Items::setAttribute(todo["uuid"], "parentuuid-0014", core["uuid"])
                position = Operations::interactivelySelectGlobalPositionInParent(core)
                Items::setAttribute(todo["uuid"], "global-positioning-4233", position)
                todo = Items::itemOrNull(todo["uuid"])
                puts JSON.pretty_generate(todo)
                next
            end

            if input == "hours" then
                hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
                Items::setAttribute(core["uuid"], "hours", hours)
                next
            end

            if input == "pile" then
                text = CommonUtils::editTextSynchronously("")
                lines = text.strip.lines.map{|line| line.strip }
                lines = lines.reverse
                lines.each{|line|
                    todo = NxTasks::descriptionToTask(line)
                    Items::setAttribute(todo["uuid"], "parentuuid-0014", core["uuid"])
                    position = PolyFunctions::firstPositionInParent(core) - 1
                    Items::setAttribute(todo["uuid"], "global-positioning-4233", position)
                    todo = Items::itemOrNull(todo["uuid"])
                    puts JSON.pretty_generate(todo)
                }
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = Operations::interactivelySelectGlobalPositionInParent(core)
                Items::setAttribute(i["uuid"], "global-positioning-4233", position)
                next
            end

            if input.start_with?("move") then
                listord = input[4, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                NxTasks::performItemPositioningInCore(i)
                next
            end


            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], PolyFunctions::naturalChildren(core).sort_by{|item| item["global-positioning-4233"] }, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Items::setAttribute(i["uuid"], "global-positioning-4233", PolyFunctions::firstPositionInParent(core) - 1)
                }
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxCores::program2()
    def self.program2()
        loop {
 
            # system("clear")
 
            store = ItemStore.new()
 
            puts ""
            puts "weekly total     : #{NxCores::totalHoursPerWeek()} hours"
            puts "correction factor: #{NxCores::bankingCorrectionFactor()}"
            puts ""

            NxCores::inRatioOrder()
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts Listing::toString2(store, item)
                }
 
            puts ""
            puts "core | hours *"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""
 
            if input == "core" then
                core = NxCores::interactivelyIssueNewOrNull()
                next if core.nil?
                puts JSON.pretty_generate(core)
                next
            end
 
            if input.start_with?("hours") then
                item = store.get(input[5, 99].strip.to_i)
                next if item.nil?
                hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
                Items::setAttribute(item["uuid"], "hours", hours)
                next
            end
 
            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
