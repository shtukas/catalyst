
class TxCliques

    # -------------------------
    # IO

    # TxCliques::issueNewClique(engineuuidOpt, descriptionOpt)
    def self.issueNewClique(engineuuidOpt, descriptionOpt)
        uuid = SecureRandom.uuid
        Solingen::init("TxClique", uuid)
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "engineuuid", engineuuidOpt)
        Solingen::setAttribute2(uuid, "description", descriptionOpt)
        Solingen::getItemOrNull(uuid)
    end

    # -------------------------
    # Data

    # TxCliques::cliqueToNxTasks(clique)
    def self.cliqueToNxTasks(clique)
        Solingen::mikuTypeItems("NxTask")
            .select{|task| task["cliqueuuid"] == clique["uuid"] }
    end

    # TxCliques::cliqueToNewFirstPosition(clique)
    def self.cliqueToNewFirstPosition(clique)
        positions = TxCliques::cliqueToNxTasks(clique).map{|task| task["position"] }
        return 1 if positions.size == 0
        position = positions.sort.first
        if position > 1 then
            position.to_f / 2
        else
            position - 1
        end
    end

    # TxCliques::cliqueToNewLastPosition(clique)
    def self.cliqueToNewLastPosition(clique)
        positions = TxCliques::cliqueToNxTasks(clique).map{|task| task["position"] }
        return 1 if positions.size == 0
        positions.sort.last + rand
    end

    # TxCliques::cliqueSuffix(item)
    def self.cliqueSuffix(item)
        return "" if item["mikuType"] != "NxTask"
        clique = Solingen::getItemOrNull(item["cliqueuuid"])
        return "" if clique.nil?
        return "" if clique["description"].nil?
        " (#{clique["description"]})".green
    end

    # TxCliques::toString(clique)
    def self.toString(clique)
        name1 = clique["description"] ? clique["description"] : clique["uuid"]
        
        suffix =
            if clique["engineuuid"] then
                engine = Solingen::getItemOrNull(clique["engineuuid"])
                if engine then
                    " (#{engine["description"]})".green
                else
                    ""
                end
            else
                ""
            end

        " 🔹  #{name1}#{suffix}"
    end

    # TxCliques::cliquesWithoutEngine()
    def self.cliquesWithoutEngine()
        Solingen::mikuTypeItems("TxClique")
            .select{|clique| clique["engineuuid"].nil? }
    end

    # -------------------------
    # Ops

    # TxCliques::architectCliqueInEngine(engine)
    def self.architectCliqueInEngine(engine)
        TxEngines::ensureEachCliqueOfAnEngineHasAName()
        clique = TxCliques::interactivelySelectCliqueOrNull(engine)
        return clique if clique
        loop {
            description = LucilleCore::askQuestionAnswerAsString("new clique description: ")
            break if description != ""
        }
        TxCliques::issueNewClique(engine["uuid"], description)
    end

    # TxCliques::cliqueForNewItemAtNoEngine()
    def self.cliqueForNewItemAtNoEngine()
        clique = TxEngines::engineUUIDOptToCliques(engineuuidOpt)
                    .sort_by{|clique| clique["unixtime"] }
                    .last
        if clique and TxCliques::cliqueToNxTasks(clique).size < 40 then
            return clique
        end
        return TxCliques::issueNewClique(nil, nil)
    end

    # TxCliques::interactivelySelectCliqueOrNull(engine)
    def self.interactivelySelectCliqueOrNull(engine)
        cliques = TxEngines::engineToCliques(engine)
                    .sort_by{|clique| clique["unixtime"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", cliques, lambda{|clique| TxCliques::toString(clique) })
    end

    # TxCliques::interactivelySelectPositionInClique(clique)
    def self.interactivelySelectPositionInClique(clique)
        tasks = TxCliques::cliqueToNxTasks(clique)
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

    # TxCliques::program2(clique)
    def self.program2(clique)

        loop {
            system("clear")
            items = TxCliques::cliqueToNxTasks(clique)
                        .sort_by{|t| t["position"] }
            store = ItemStore.new()

            puts ""
            puts TxCliques::toString(clique)
            puts ""

            items
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::itemToListingLine(store: store, item: item)
                }

            puts ""
            puts "rename clique | stack items on top | put line at position"
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            break if input == ""
            break if input == "exit"

            if input == "rename clique" then
                puts "old description: #{clique["description"]}"
                description = LucilleCore::askQuestionAnswerAsString("new description (empty to abort): ")
                next if description == ""
                Solingen::setAttribute2(clique["uuid"], "description", description)
            end
            if input == "stack items on top" then
                text = CommonUtils::editTextSynchronously("").strip
                next if text == ""
                text.lines.map{|l| l.strip }.reverse.each{|line|
                    position = TxCliques::cliqueToNewFirstPosition(clique)
                    t = NxTasks::lineToCliqueTask(line, clique["engineuuid"], clique["uuid"], position)
                    puts JSON.pretty_generate(t)
                }
            end
            if input == "put line at position" then
                line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                t = NxTasks::lineToCliqueTask(line, clique["engineuuid"], clique["uuid"], position)
                puts JSON.pretty_generate(t)
            end

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }

        if TxCliques::cliqueToNxTasks(clique).empty? then
            puts "You are leaving an empty Clique"
            if LucilleCore::askQuestionAnswerAsBoolean("Would you like to destroy it ? ") then
                Solingen::destroy(clique["uuid"])
            end
        end
    end

    # TxCliques::program3()
    def self.program3()
        loop {
            engine = TxEngines::interactivelySelectOneOrNull()
            return if engine.nil?
            clique = TxCliques::interactivelySelectCliqueOrNull(engine)
            next if clique.nil?
            TxCliques::program2(clique)
        }
    end
end
