
class NxSequences

    # NxSequences::infinityuuid()
    def self.infinityuuid()
        "9297479b-17de-427e-8622-a7e52f90020c"
    end

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
        DarkEnergy::itemOrNull(uuid)
    end

    # -------------------------
    # Data

    # NxSequences::toString(clique)
    def self.toString(clique)
        "🔹 #{clique["description"]}"
    end

    # NxSequences::nxTasks(clique)
    def self.nxTasks(clique)
        if clique["uuid"] == NxSequences::infinityuuid() then
            return DarkEnergy::mikuType("NxTask")
                .select{|item| item["sequenceuuid"].nil? }
                .sort_by{|task| task["position"] }
                .reduce([]){|selected, task|
                    if selected.size >= 6 then
                        selected
                    else
                        if Bank::recoveredAverageHoursPerDay(task["uuid"]) < 1 then
                            selected + [task]
                        else
                            selected
                        end
                    end
                }
        end

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

    # -------------------------
    # Ops

    # NxSequences::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        cliques = DarkEnergy::mikuType("NxSequence")
                    .select{|clique| clique["uuid"] != NxSequences::infinityuuid() }
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

    # NxSequences::program2(orbital)
    def self.program2(orbital)

        if orbital["uuid"] == NxSequences::infinityuuid() then
            puts "You cannot run program on Infinity"
            LucilleCore::pressEnterToContinue()
            return
        end

        loop {
            orbital = DarkEnergy::itemOrNull(orbital["uuid"])
            return if orbital.nil?
            system("clear")

            store = ItemStore.new()

            puts ""
            puts NxSequences::toString(orbital)
            
            puts ""
            NxBurners::itemsForOrbital(orbital)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::itemToListingLine(store: store, item: item)
                }

            puts ""
            NxSequences::nxTasks(orbital).sort_by{|t| t["position"] }
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::itemToListingLine(store: store, item: item)
                }

            puts ""
            puts "rename (rename orbital) | stack (stack items on top) | line (put line at position)"
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            break if input == ""
            break if input == "exit"

            if input == "rename" then
                description = CommonUtils::editTextSynchronously(orbital["description"])
                next if description == ""
                DarkEnergy::patch(orbital["uuid"], "description", description)
            end
            if input == "stack" then
                text = CommonUtils::editTextSynchronously("").strip
                next if text == ""
                text.lines.map{|l| l.strip }.reverse.each{|line|
                    position = NxSequences::tasksNewFirstPosition(orbital)
                    t = NxTasks::lineToOrbitalTask(line, orbital["uuid"], position)
                    puts JSON.pretty_generate(t)
                }
            end
            if input == "line" then
                line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                t = NxTasks::lineToOrbitalTask(line, orbital["uuid"], position)
                puts JSON.pretty_generate(t)
            end

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }

        if NxSequences::nxTasks(orbital).empty? then
            puts "You are leaving an empty orbital"
            if LucilleCore::askQuestionAnswerAsBoolean("Would you like to destroy it ? ") then
                DarkEnergy::destroy(orbital["uuid"])
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
end
