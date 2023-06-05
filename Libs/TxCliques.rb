
class TxCliques

    # TxCliques::newClique()
    def self.newClique()
        {
            "mikuType"    => "TxClique",
            "cliqueuuid"  => SecureRandom.hex,
            "position"    => 1,
            "description" => nil
        }
    end

    # TxCliques::cliqueUUIDToNxTasks(cliqueuuid)
    def self.cliqueUUIDToNxTasks(cliqueuuid)
        Solingen::mikuTypeItems("NxTask")
            .select{|task| task["clique"] }
            .select{|task| task["clique"]["cliqueuuid"] == cliqueuuid }
    end

    # TxCliques::cliqueUUIDToNewFirstPosition(cliqueuuid)
    def self.cliqueUUIDToNewFirstPosition(cliqueuuid)
        position = Solingen::mikuTypeItems("NxTask")
            .select{|task| task["clique"] }
            .map{|task| task["clique"] }
            .select{|clique| clique["cliqueuuid"] == cliqueuuid }
            .map{|clique| clique["position"] }
            .reduce(1){|highest, position|
                [highest, position].min
            }
        if position > 1 then
            position.to_f / 2
        else
            position - 1
        end
    end

    # TxCliques::cliqueUUIDToLastPosition(cliqueuuid)
    def self.cliqueUUIDToLastPosition(cliqueuuid)
        Solingen::mikuTypeItems("NxTask")
            .select{|task| task["clique"] }
            .map{|task| task["clique"] }
            .select{|clique| clique["cliqueuuid"] == cliqueuuid }
            .map{|clique| clique["position"] }
            .reduce(1){|highest, position|
                [highest, position].max
            }
    end

    # TxCliques::cliqueUUIDToDescriptionOrNull(cliqueuuid)
    def self.cliqueUUIDToDescriptionOrNull(cliqueuuid)
        Solingen::mikuTypeItems("NxTask")
            .select{|task| task["clique"] }
            .map{|task| task["clique"] }
            .select{|clique| clique["cliqueuuid"] == cliqueuuid }
            .map{|clique| clique["description"] }
            .compact
            .first
    end

    # TxCliques::cliqueUUIDToRepresentativeClique(cliqueuuid)
    def self.cliqueUUIDToRepresentativeClique(cliqueuuid)
        task = TxCliques::cliqueUUIDToNxTasks(cliqueuuid).first
        return nil if task.nil?
        task["clique"].clone
    end

    # TxCliques::architectCliqueInEngineOpt(engineuuidOpt)
    def self.architectCliqueInEngineOpt(engineuuidOpt)
        cliqueuuids = TxEngines::engineUUIDOptToCliqueUUIDs(engineuuidOpt)
        if cliqueuuids.size == 0 then
            return TxCliques::newClique()
        end

        if engineuuidOpt then
            namedClique = TxCliques::interactivelySelectNamedCliqueOrNull(engineuuidOpt)
            return namedClique if namedClique
        end

        cliqueuuids = cliqueuuids.select{|cliqueuuid| TxCliques::cliqueUUIDToNxTasks(cliqueuuid).size < 40 }
        if cliqueuuids.size == 0 then
            return TxCliques::newClique()
        end
        cliqueuuid = cliqueuuids.first
        {
            "mikuType"    => "TxClique",
            "cliqueuuid"  => cliqueuuid,
            "position"    => TxCliques::cliqueUUIDToLastPosition(cliqueuuid) + 1,
            "description" => TxCliques::cliqueUUIDToDescriptionOrNull(cliqueuuid)
        }
    end

    # TxCliques::interactivelySelectNamedCliqueOrNull(engineuuidOpt)
    def self.interactivelySelectNamedCliqueOrNull(engineuuidOpt)
        descriptions = Solingen::mikuTypeItems("NxTask")
                            .select{|task| task["engineuuid"] == engineuuidOpt }
                            .map{|task| task["clique"]["description"] }
                            .compact
                            .uniq
        description = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", descriptions)
        return nil if description.nil?
        Solingen::mikuTypeItems("NxTask").each{|task|
            if task["clique"]["description"] == description then
                return task["clique"]
            end
        }
        nil
    end

    # TxCliques::program1CatalystItem(item)
    def self.program1CatalystItem(item)
        loop {
            item = Solingen::getItemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            actions = [
                "lift item to new clique",
            ]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
            return if action.nil?
            if action == "lift item to new clique" then
                description = LucilleCore::askQuestionAnswerAsString("clique description: ")
                clique = {
                    "mikuType"    => "TxClique",
                    "cliqueuuid"  => SecureRandom.hex,
                    "position"    => 1,
                    "description" => description
                }
                Solingen::setAttribute2(item["uuid"], "clique", clique)
            end
        }
    end

    # TxCliques::program2Clique(cliqueuuid)
    def self.program2Clique(cliqueuuid)
        getEngineuuidOpt = lambda{
            TxCliques::cliqueUUIDToNxTasks(cliqueuuid).map{|t| t["engineuuid"] }.compact.first
        }
        getDescriptionOpt = lambda{
            TxCliques::cliqueUUIDToNxTasks(cliqueuuid).map{|t| t["engine"]["description"] }.compact.first
        }

        loop {
            items = TxCliques::cliqueUUIDToNxTasks(cliqueuuid)
                        .sort_by{|t| t["clique"]["position"] }
            store = ItemStore.new()

            Listing::printEvalItems(store, [], items)

            puts ""
            puts "rename clique | stack items on top | put line at position"
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""
            return if input == "exit"

            if input == "rename clique" then
                clique = TxCliques::cliqueUUIDToRepresentativeClique(cliqueuuid)
                puts "old name: #{clique["description"]}"
                newname = LucilleCore::askQuestionAnswerAsString("new name (empty to abort): ")
                next if newname == ""
                TxCliques::renameClique(cliqueuuid, newname)
            end
            if input == "stack items on top" then
                newItems = CommonUtils::editTextSynchronously("").strip
                next if newItems == ""
                newItems.lines.map{|l| l.strip }.reverse.each{|line|
                    t = NxTasks::lineToTask(line)
                    Solingen::setAttribute2(t["uuid"], "engineuuid", getEngineuuidOpt.call())
                    position = TxCliques::cliqueUUIDToNewFirstPosition(cliqueuuid)
                    description = getDescriptionOpt.call()
                    clique = {
                        "mikuType"    => "TxClique",
                        "cliqueuuid"  => SecureRandom.hex,
                        "position"    => position,
                        "description" => description
                    }
                    Solingen::setAttribute2(t["uuid"], "clique", clique)
                }
            end
            if input == "put line at position" then
                line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                t = NxTasks::lineToTask(line)
                Solingen::setAttribute2(t["uuid"], "engineuuid", getEngineuuidOpt.call())
                description = getDescriptionOpt.call()
                clique = {
                    "mikuType"    => "TxClique",
                    "cliqueuuid"  => SecureRandom.hex,
                    "position"    => position,
                    "description" => description
                }
                Solingen::setAttribute2(t["uuid"], "clique", clique)
            end

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end

    # TxCliques::program3Cliques()
    def self.program3Cliques()
        loop {
            engineuuidOpt = TxEngines::interactivelySelectOneUUIDOrNull()
            return if engineuuidOpt.nil?
            clique = TxCliques::interactivelySelectNamedCliqueOrNull(engineuuidOpt)
            next if clique.nil?
            TxCliques::program2Clique(clique["cliqueuuid"])
        }
    end

    # TxCliques::cliqueSuffix(item)
    def self.cliqueSuffix(item)
        return "" if item["mikuType"] != "NxTask"
        clique = item["clique"]
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

    # TxCliques::renameClique(cliqueuuid, description)
    def self.renameClique(cliqueuuid, description)
        TxCliques::cliqueUUIDToNxTasks(cliqueuuid).each{|t|
            clique = t["clique"]
            clique["description"] = description
            Solingen::setAttribute2(t["uuid"], "clique", clique)
        }
    end
end
