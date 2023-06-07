
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
        if clique["description"] then
            "(clqu) #{clique["description"]}"
        else
            "(clqu) #{clique["cliqueuuid"]}"
        end
    end

    # -------------------------
    # Ops

    # TxCliques::architectCliqueInEngineOpt(engineuuidOpt)
    def self.architectCliqueInEngineOpt(engineuuidOpt)
        TxEngines::ensureEachCliqueOfAnEngineHasAName()
        if engineuuidOpt then
            engineuuid = engineuuidOpt
            clique = TxCliques::interactivelySelectCliqueOrNull(engineuuid)
            return clique if clique
            loop {
                description = LucilleCore::askQuestionAnswerAsString("new clique description: ")
                break if description != ""
            }
            return TxCliques::issueNewClique(engineuuid, description)
        else
            clique = TxEngines::engineUUIDOptToCliques(engineuuidOpt)
                        .sort_by{|clique| clique["unixtime"] }
                        .last
            if clique and TxCliques::cliqueToNxTasks(clique).size < 40 then
                return clique
            end
            return TxCliques::issueNewClique(nil, nil)
        end
    end

    # TxCliques::interactivelySelectCliqueOrNull(engineuuidOpt)
    def self.interactivelySelectCliqueOrNull(engineuuidOpt)
        cliques = Solingen::mikuTypeItems("TxClique")
                            .select{|clique| clique["engineuuid"] == engineuuidOpt }
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
            items = TxCliques::cliqueToNxTasks(clique)
                        .sort_by{|t| t["position"] }
            store = ItemStore.new()

            Listing::printEvalItems(store, [], items)

            puts ""
            puts "rename clique | stack items on top | put line at position"
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""
            return if input == "exit"

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
    end

    # TxCliques::program3()
    def self.program3()
        loop {
            engine = TxEngines::interactivelySelectOneOrNull()
            return if engine.nil?
            clique = TxCliques::interactivelySelectCliqueOrNull(engine["uuid"])
            next if clique.nil?
            TxCliques::program2(clique)
        }
    end
end
