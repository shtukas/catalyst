class NxCores

    # NxCores::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
        Items::init(uuid)
        Items::setAttribute(uuid, "mikuType", "NxCore")
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "hours", hours)
        Items::itemOrNull(uuid)
    end

    # NxCores::makeNewNearTopNx1949InInfinityOrNull()
    def self.makeNewNearTopNx1949InInfinityOrNull()
        coreuuid = NxCores::infinityuuid()
        core = Items::itemOrNull(coreuuid)
        return nil if core.nil?
        position = PolyFunctions::random_10_20_position_in_parent(core)
        {
            "position" => position,
            "parentuuid" => core["uuid"]
        }
    end

    # ------------------
    # Data

    # NxCores::toString(item)
    def self.toString(item)
        "⏱️  #{item["description"]} #{NxCores::ratioString(item)}"
    end

    # NxCores::ratio(core)
    def self.ratio(core)
        hours = core["hours"].to_f
        [Bank1::recoveredAverageHoursPerDay(core["uuid"]), 0].max.to_f/(hours/7)
    end

    # NxCores::shouldShow(core)
    def self.shouldShow(core)
        return false if !DoNotShowUntil::isVisible(core["uuid"])
        Bank1::recoveredAverageHoursPerDay(core["uuid"]) < (core["hours"].to_f/7)
    end

    # NxCores::ratioString(core)
    def self.ratioString(core)
        "(#{"%6.2f" % (100 * NxCores::ratio(core))} %; #{"%5.2f" % core["hours"]} h/w)".yellow
    end

    # NxCores::infinityuuid()
    def self.infinityuuid()
        "427bbceb-923e-4feb-8232-05883553bb28"
    end

    # NxCores::cores()
    def self.cores()
        Items::mikuType("NxCore")
    end

    # NxCores::totalHoursPerWeek()
    def self.totalHoursPerWeek()
        NxCores::cores().map{|item| item["hours"] }.inject(0, :+)
    end

    # NxCores::coresInRatioOrder()
    def self.coresInRatioOrder()
        NxCores::cores()
            .sort_by{|core| NxCores::ratio(core) }
    end

    # NxCores::listingItems()
    def self.listingItems()
        NxCores::cores()
            .sort_by{|core| NxCores::ratio(core) }
            .select{|core| NxCores::ratio(core) < 1 }
    end

    # NxCores::interactivelySelectOrNull()
    def self.interactivelySelectOrNull()
        l = lambda{|core| "#{NxCores::ratioString(core)} #{core["description"]}#{DoNotShowUntil::suffix1(core["uuid"]).yellow}" }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", NxCores::coresInRatioOrder(), l)
    end

    # NxCores::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        l = lambda{|core| "#{NxCores::ratioString(core)} #{core["description"]}#{DoNotShowUntil::suffix1(core["uuid"]).yellow}" }
        cores = NxCores::coresInRatioOrder()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, l)
    end

    # NxCores::selectCoreByUUIDOrNull(coreuuid)
    def self.selectCoreByUUIDOrNull(coreuuid)
        NxCores::cores().select{|core| core["uuid"] == coreuuid }.first
    end

    # NxCores::childrenForPrefix(core)
    def self.childrenForPrefix(core)
        PolyFunctions::childrenInOrder(core).take(3)
    end

    # ------------------
    # Ops

    # NxCores::program1(core)
    def self.program1(core)

        if core["isPureTodoFile"] then
            puts "You cannot land on #{core["description"].green} because isPureTodoFile is true"
            LucilleCore::pressEnterToContinue()
            return
        end

        loop {

            store = ItemStore.new()

            puts ""

            PolyFunctions::childrenInOrder(core)
                .each{|element|
                    store.register(element, Listing::canBeDefault(element))
                    puts Listing::toString2(store, element)
                }

            puts ""

            puts "todo (here, with position selection) | hours | pile | activate * | position * | move * | sort"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                position = PolyFunctions::interactivelySelectGlobalPositionInParent(core)
                nx1949 = {
                    "position" => position,
                    "parentuuid" => core["uuid"]
                }
                todo = NxTasks::interactivelyIssueNewOrNull(nx1949)
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
                    position = PolyFunctions::firstPositionInParent(core) - 1
                    nx1949 = {
                        "position" => position,
                        "parentuuid" => core["uuid"]
                    }
                    todo = NxTasks::descriptionToTask(line, nx1949)
                    puts JSON.pretty_generate(todo)
                }
                next
            end

            if input.start_with?("activate") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                nx1609 = NxTasks::interactivelyMakeNx1609OrNull()
                return if nx1609.nil?
                Items::setAttribute(i["uuid"], "nx1609", nx1609)
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = PolyFunctions::interactivelySelectGlobalPositionInParent(core)
                nx1949 = {
                    "position" => position,
                    "parentuuid" => core["uuid"]
                }
                Items::setAttribute(i["uuid"], "nx1949", nx1949)
                next
            end

            if input.start_with?("move *") then
                listord = input[4, input.size].strip.to_i
                item = store.get(listord.to_i)
                next if item.nil?
                NxTasks::performItemPositioning(item)
                next
            end


            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], PolyFunctions::childrenInOrder(core).sort_by{|item| item["nx1949"]["position"] }, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    position = PolyFunctions::firstPositionInParent(core) - 1
                    nx1949 = {
                        "position" => position,
                        "parentuuid" => core["uuid"]
                    }
                    Items::setAttribute(i["uuid"], "nx1949", nx1949)
                }
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
