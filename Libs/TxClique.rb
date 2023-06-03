
class TxClique

    # TxClique::newClique()
    def self.newClique()
        {
            "mikuType"    => "TxClique",
            "cliqueuuid"  => SecureRandom.hex,
            "position"    => 1,
            "description" => nil
        }
    end

    # TxClique::cliqueUUIDToNxTasks(cliqueuuid)
    def self.cliqueUUIDToNxTasks(cliqueuuid)
        Solingen::mikuTypeItems("NxTask")
            .select{|task| task["clique"] }
            .select{|task| task["clique"]["cliqueuuid"] == cliqueuuid }
    end

    # TxClique::engineUUIDOptToCliqueUUIDs(engineuuidOpt)
    def self.engineUUIDOptToCliqueUUIDs(engineuuidOpt)
        Solingen::mikuTypeItems("NxTask")
            .select{|task| task["engineuuid"] == engineuuidOpt }
            .select{|task| task["clique"] }
            .map{|task| task["clique"]["cliqueuuid"] }
            .uniq
    end

    # TxClique::cliqueUUIDToNewFirstPosition(cliqueuuid)
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

    # TxClique::cliqueUUIDToLastPosition(cliqueuuid)
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

    # TxClique::getCliqueDescriptionOrNull(cliqueuuid)
    def self.getCliqueDescriptionOrNull(cliqueuuid)
        Solingen::mikuTypeItems("NxTask")
            .select{|task| task["clique"] }
            .map{|task| task["clique"] }
            .select{|clique| clique["cliqueuuid"] == cliqueuuid }
            .map{|clique| clique["description"] }
            .compact
            .first
    end

    # TxClique::architectCliqueInEngineOpt(engineuuidOpt)
    def self.architectCliqueInEngineOpt(engineuuidOpt)
        cliqueuuids = TxClique::engineUUIDOptToCliqueUUIDs(engineuuidOpt)
        if cliqueuuids.size == 0 then
            return TxClique::newClique()
        end
        cliqueuuids = cliqueuuids.select{|cliqueuuid| TxClique::cliqueUUIDToNxTasks(cliqueuuid).size < 40 }
        if cliqueuuids.size == 0 then
            return TxClique::newClique()
        end
        cliqueuuid = cliqueuuids.first
        {
            "mikuType"    => "TxClique",
            "cliqueuuid"  => cliqueuuid,
            "position"    => TxClique::cliqueUUIDToLastPosition(cliqueuuid) + 1,
            "description" => TxClique::getCliqueDescriptionOrNull(cliqueuuid)
        }
    end

    # TxClique::interactivelySelectNamedClique()
    def self.interactivelySelectNamedClique()
        descriptions = Solingen::mikuTypeItems("NxTask").map{|task| task["clique"]["description"] }.compact.uniq
        description = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", descriptions)
        return if description.nil?
        Solingen::mikuTypeItems("NxTask").each{|task|
            if task["clique"]["description"] == description then
                return task["clique"]
            end
        }
    end

    # TxClique::program1Item(item)
    def self.program1Item(item)
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

    # TxClique::program2Clique(cliqueuuid)
    def self.program2Clique(cliqueuuid)
        getRepresentativeClique = lambda{
            TxClique::cliqueUUIDToNxTasks(cliqueuuid).first["clique"].clone
        }
        getEngineuuidOpt = lambda{
            TxClique::cliqueUUIDToNxTasks(cliqueuuid).map{|t| t["engineuuid"] }.compact.first
        }
        getDescriptionOpt = lambda{
            TxClique::cliqueUUIDToNxTasks(cliqueuuid).map{|t| t["engine"]["description"] }.compact.first
        }

        loop {
            items = TxClique::cliqueUUIDToNxTasks(cliqueuuid)
                        .sort_by{|t| t["clique"]["position"] }
            store = ItemStore.new()

            Listing::printEvalItems(store, [], items)

            puts ""
            [
                "rename clique",
                "stack items on top",
                "put line at position"
            ]
                .each{|t| puts t }
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""
            return if input == "exit"

            if input == "rename clique" then
                clique = getRepresentativeClique.call()
                puts "old name: #{clique["description"]}"
                newname = LucilleCore::askQuestionAnswerAsString("new name (empty to abort): ")
                next if newname == ""
                TxClique::cliqueUUIDToNxTasks(cliqueuuid).each{|t|
                    clique = t["clique"]
                    clique["description"] = newname
                    Solingen::setAttribute2(t["uuid"], "clique", clique)
                }
            end
            if input == "stack items on top" then
                newItems = CommonUtils::editTextSynchronously("").strip
                next if newItems == ""
                newItems.lines.map{|l| l.strip }.reverse.each{|line|
                    t = NxTasks::lineToTask(line)
                    Solingen::setAttribute2(t["uuid"], "engineuuid", getEngineuuidOpt.call())
                    position = TxClique::cliqueUUIDToNewFirstPosition(cliqueuuid)
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

    # TxClique::program3Cliques()
    def self.program3Cliques()
        clique = TxClique::interactivelySelectNamedClique()
        TxClique::program2Clique(clique["cliqueuuid"])
    end

    # TxClique::cliqueSuffix(item)
    def self.cliqueSuffix(item)
        return "" if item["mikuType"] != "NxTask"
        clique = item["clique"]
        return "" if clique["description"].nil?
        " (#{clique["description"]})".green
    end
end
