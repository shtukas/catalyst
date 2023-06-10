
class NxSequences

    # -------------------------
    # IO

    # NxSequences::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxSequence", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "description", description)
        item = DarkEnergy::itemOrNull(uuid)
        loop {
            status NxSequences::setDriverAttempt(item)
            break if status
        }
        DarkEnergy::itemOrNull(uuid)
    end

    # -------------------------
    # Data

    # NxSequences::toString(clique)
    def self.toString(clique)
        padding = XCache::getOrDefaultValue("348d7483-82bd-4a9e-9028-7d42b3952204", "0").to_i
        "🔹 #{clique["description"].ljust(padding)} (metric: #{NxSequences::listingMetric(clique).round(2)})"
    end

    # NxSequences::nxTasks(clique)
    def self.nxTasks(clique)
        DarkEnergy::mikuType("NxTask")
            .select{|task| task["sequenceuuid"] == clique["uuid"] }
    end

    # NxSequences::tasksNewFirstPosition(clique)
    def self.tasksNewFirstPosition(clique)
        positions = NxSequences::nxTasks(clique).map{|task| task["position"] }
        return 1 if positions.size == 0
        position = positions.sort.first
        if position > 1 then
            position.to_f / 2
        else
            position - 1
        end
    end

    # NxSequences::sequenceSuffix(item)
    def self.sequenceSuffix(item)
        return "" if item["sequenceuuid"].nil?
        sequence = DarkEnergy::itemOrNull(item["sequenceuuid"])
        return "" if sequence.nil?
        " (#{sequence["description"]})".green
    end

    # NxSequences::listingMetric(item)
    def self.listingMetric(item)
        numbers = [
            Metrics::coreuuid(item),
            Metrics::engineuuid(item)
        ].compact
        return (numbers.size > 0 ? (0.5 + 0.5 * numbers.max) : 0.5)
    end

    # -------------------------
    # Ops

    # NxSequences::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        cliques = DarkEnergy::mikuType("NxSequence")
                    .sort_by{|clique| clique["unixtime"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", cliques, lambda{|clique| NxSequences::toString(clique) })
    end

    # NxSequences::interactivelySelectTaskPositionInOrbital(clique)
    def self.interactivelySelectTaskPositionInOrbital(clique)
        tasks = NxSequences::nxTasks(clique)
        return 1 if tasks.empty?
        tasks
            .sort_by{|task| task["position"] }
            .each{|item| puts NxTasks::toString(item) }
        puts ""
        position = 0
        loop {
            position = LucilleCore::askQuestionAnswerAsString("position: ")
            next if position == ""
            position = position.to_f
            break
        }
        position
    end

    # NxSequences::program2(sequence)
    def self.program2(sequence)
        loop {
            sequence = DarkEnergy::itemOrNull(sequence["uuid"])
            return if sequence.nil?
            system("clear")

            store = ItemStore.new()

            puts ""
            puts NxSequences::toString(sequence)
            
            puts ""
            NxBurners::itemsForOrbital(sequence)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::itemToListingLine(store: store, item: item)
                }

            puts ""
            NxSequences::nxTasks(sequence).sort_by{|t| t["position"] }
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::itemToListingLine(store: store, item: item)
                }

            puts ""
            puts "rename (rename sequence) | stack (stack items on top) | line (put line at position)"
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            break if input == ""
            break if input == "exit"

            if input == "rename" then
                description = CommonUtils::editTextSynchronously(sequence["description"])
                next if description == ""
                DarkEnergy::patch(sequence["uuid"], "description", description)
            end
            if input == "stack" then
                text = CommonUtils::editTextSynchronously("").strip
                next if text == ""
                text.lines.map{|l| l.strip }.reverse.each{|line|
                    position = NxSequences::tasksNewFirstPosition(sequence)
                    t = NxTasks::lineToOrbitalTask(line, sequence["uuid"], position)
                    puts JSON.pretty_generate(t)
                }
            end
            if input == "line" then
                line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                t = NxTasks::lineToOrbitalTask(line, sequence["uuid"], position)
                puts JSON.pretty_generate(t)
            end

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }

        if NxSequences::nxTasks(sequence).empty? then
            puts "You are leaving an empty sequence"
            if LucilleCore::askQuestionAnswerAsBoolean("Would you like to destroy it ? ") then
                DarkEnergy::destroy(sequence["uuid"])
            end
        end
    end

    # NxSequences::program3()
    def self.program3()
        loop {
            clique = NxSequences::interactivelySelectOneOrNull()
            break if clique.nil?
            NxSequences::program2(clique)
        }
    end

    # NxSequences::giveSequenceToItemAttempt(item)
    def self.giveSequenceToItemAttempt(item)
        if item["mikuType"] == "NxCore" or item["mikuType"] == "NxSequence" then
            puts "You cannot give a sequence to a NxCore or a NxSequence"
            LucilleCore::pressEnterToContinue()
            return
        end
        sequence = NxSequences::interactivelySelectOneOrNull()
        return if sequence.nil?
        DarkEnergy::patch(item["uuid"], "sequenceuuid", sequence["uuid"])
    end

    # NxSequences::setDriverAttempt(item) # status
    def self.setDriverAttempt(item)
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["core", "engine"])
        return false if option.nil?
        if option == "core" then
            core = NxCores::interactivelySelectOneOrNull()
            if core.nil? then
                if LucilleCore::askQuestionAnswerAsBoolean("You did not select a core, would you like to create a new one ? ") then
                    core = NxCores::interactivelyIssueNewOrNull()
                    if core.nil? then
                        return nil
                    end
                end
            end
            DarkEnergy::patch(item["uuid"], "coreuuid", core["uuid"])
            return true
        end
        if option == "engine" then
            return TxEngines::interactivelyEngineSpawnAttempt(item)
        end
    end

    # NxSequences::maintenance()
    def self.maintenance()
        padding = DarkEnergy::mikuType("NxSequence").map{|core| core["description"].size }.max
        XCache::set("348d7483-82bd-4a9e-9028-7d42b3952204", padding)

        # Every sequence should have a core or an engine

        DarkEnergy::mikuType("NxSequence").each{|sequence|
            if sequence["coreuuid"] then
                core = DarkEnergy::itemOrNull(sequence["coreuuid"])
                if core.nil? then
                    DarkEnergy::patch(item["uuid"], "coreuuid", nil)
                end
            end
            if sequence["engineuuid"] then
                engine = DarkEnergy::itemOrNull(sequence["engineuuid"])
                if engine.nil? then
                    DarkEnergy::patch(item["uuid"], "engineuuid", nil)
                end
            end
        }

        # Every sequence should have a core or an engine

        DarkEnergy::mikuType("NxSequence").each{|sequence|
            if sequence["coreuuid"].nil? and sequence["engineuuid"] then
                loop {
                    status = NxSequences::setDriverAttempt(item)
                    break if status
                }
            end
        }
    end
end
