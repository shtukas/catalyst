
class NxOrbitals

    # NxOrbitals::infinityuuid()
    def self.infinityuuid()
        "9297479b-17de-427e-8622-a7e52f90020c"
    end

    # -------------------------
    # IO

    # NxOrbitals::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        engine = TxEngines::interactivelyMakeEngineOrDefault()
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxOrbital", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "engine", engine)
        DarkEnergy::itemOrNull(uuid)
    end

    # -------------------------
    # Data

    # NxOrbitals::orbitalToNxTasks(clique)
    def self.orbitalToNxTasks(clique)
        if clique["uuid"] == NxOrbitals::infinityuuid() then
            return DarkEnergy::mikuType("NxTask")
                .select{|item| item["cliqueuuid"].nil? }
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
            .select{|task| task["cliqueuuid"] == clique["uuid"] }
    end

    # NxOrbitals::orbitalToTaskNewFirstPosition(clique)
    def self.orbitalToTaskNewFirstPosition(clique)
        positions = NxOrbitals::orbitalToNxTasks(clique).map{|task| task["position"] }
        return 1 if positions.size == 0
        position = positions.sort.first
        if position > 1 then
            position.to_f / 2
        else
            position - 1
        end
    end

    # NxOrbitals::orbitalSuffix(item)
    def self.orbitalSuffix(item)
        return "" if item["mikuType"] != "NxTask"
        clique = DarkEnergy::itemOrNull(item["cliqueuuid"])
        return "" if clique.nil?
        return "" if clique["description"].nil?
        " (#{clique["description"]})".green
    end

    # NxOrbitals::toString(clique)
    def self.toString(clique)
        padding = XCache::getOrDefaultValue("ba9117eb-7a6f-474c-b53e-1c7a80ac0c6c", "0").to_i
        suffix =
            if clique["engine"] then
                " #{TxEngines::toString1(clique["engine"])}".green
            else
                ""
            end
        "🔹 #{clique["description"].ljust(padding)}#{suffix}"
    end

    # NxOrbitals::management()
    def self.management()
        padding = DarkEnergy::mikuType("NxOrbital").map{|clique| clique["description"].size }.max
        XCache::set("ba9117eb-7a6f-474c-b53e-1c7a80ac0c6c", padding)
    end

    # NxOrbitals::listingRatio(clique)
    def self.listingRatio(clique)
        engine = clique["engine"]
        0.9 * TxEngines::dayCompletionRatio(engine) + 0.1 * TxEngines::periodCompletionRatio(engine)
    end

    # -------------------------
    # Ops

    # NxOrbitals::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        cliques = DarkEnergy::mikuType("NxOrbital")
                    .select{|clique| clique["uuid"] != NxOrbitals::infinityuuid() }
                    .sort_by{|clique| clique["unixtime"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", cliques, lambda{|clique| NxOrbitals::toString(clique) })
    end

    # NxOrbitals::interactivelySelectTaskPositionInOrbital(clique)
    def self.interactivelySelectTaskPositionInOrbital(clique)
        tasks = NxOrbitals::orbitalToNxTasks(clique)
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

    # NxOrbitals::program2(orbital)
    def self.program2(orbital)

        if orbital["uuid"] == NxOrbitals::infinityuuid() then
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
            puts NxOrbitals::toString(orbital)
            
            puts ""
            NxBurners::itemsForOrbital(orbital)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::itemToListingLine(store: store, item: item)
                }

            puts ""
            NxOrbitals::orbitalToNxTasks(orbital).sort_by{|t| t["position"] }
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
                    position = NxOrbitals::orbitalToTaskNewFirstPosition(orbital)
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

        if NxOrbitals::orbitalToNxTasks(orbital).empty? then
            puts "You are leaving an empty orbital"
            if LucilleCore::askQuestionAnswerAsBoolean("Would you like to destroy it ? ") then
                DarkEnergy::destroy(orbital["uuid"])
            end
        end
    end

    # NxOrbitals::program3()
    def self.program3()
        loop {
            clique = NxOrbitals::interactivelySelectOneOrNull()
            break if clique.nil?
            NxOrbitals::program2(clique)
        }
    end
end
