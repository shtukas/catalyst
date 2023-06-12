

class NxTasks

    # --------------------------------------------------
    # Makers

    # NxTasks::coreFreePositions()
    def self.coreFreePositions()
        DarkEnergy::mikuType("NxTask")
            .select{|task| task["sequenceuuid"].nil? }
            .map{|task| task["position"] || 0 }
    end

    # NxTasks::coordinates(item or null)
    def self.coordinates(item)
        core = 
            if item then
                if item["coreuuid"] then
                    DarkEnergy::itemOrNull(item["coreuuid"])
                else
                    NxCores::interactivelySelectOneOrNull()
                end
            else
                 NxCores::interactivelySelectOneOrNull()
            end

        if core then
            if LucilleCore::askQuestionAnswerAsBoolean("manually set position ? ", true) then
                position = NxCores::interactivelySelectPositionAmongTop(core)
            else
                position = NxCores::firstPositionInCore(core) - 1
            end
        else
            position = CommonUtils::computeThatPosition(NxTasks::coreFreePositions().sort.first(100))
        end

        [core ? core["uuid"] : nil, position]
    end

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreData::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        DarkEnergy::init("NxPure", uuid)

        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()

        coreuuid, position = NxTasks::coordinates(nil)

        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::patch(uuid, "coreuuid", coreuuid)
        DarkEnergy::patch(uuid, "position", position)
        DarkEnergy::patch(uuid, "mikuType", "NxTask")

        item = DarkEnergy::itemOrNull(uuid)
        if LucilleCore::askQuestionAnswerAsBoolean("set engine ? ", false) then
            item = TxEngines::setItemEngine(item)
        end
        item
    end

    # NxTasks::viennaUrl(url)
    def self.viennaUrl(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid

        DarkEnergy::init("NxPure", uuid)

        nhash = DarkMatter::putBlob(url)
        coredataref = "url:#{nhash}"

        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::patch(uuid, "mikuType", "NxTask")
        DarkEnergy::itemOrNull(uuid)
    end

    # NxTasks::lineToOrbitalTask(line, sequenceuuid, position)
    def self.lineToOrbitalTask(line, sequenceuuid, position)
        uuid = SecureRandom.uuid
        description = line
        DarkEnergy::init("NxPure", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "sequenceuuid", sequenceuuid)
        DarkEnergy::patch(uuid, "position", position)
        DarkEnergy::patch(uuid, "mikuType", "NxTask")
        DarkEnergy::itemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        "👨🏻‍💻 (#{"%5.2f" % (item["position"] || 0)}) #{item["description"]}"
    end

    # NxTasks::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxTask").first(1000)
    end

    # NxTasks::latestUUIDs(size)
    def self.latestUUIDs(size)
        DarkEnergy::mikuType("NxTask").sort_by{|task| task["unixtime"] }.reverse.take(size).map{|item| item["uuid"] }
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::stackEntryToString(entry)
    def self.stackEntryToString(entry)
        if entry["variant"] == "origin" then
            return "#{"%7.3f" % entry["position"]} #{entry["description"]}"
        end
        if entry["variant"] == "plus" then
            return "#{"%7.3f" % entry["position"]} #{entry["line"]}"
        end
    end

    # NxTasks::access(task)
    def self.access(task)

        if task["field11"] == "null" then
            task["field11"] = nil
            DarkEnergy::patch(task["uuid"], "field11", nil)
        end

        if task["variant"].nil? or task["variant"] == "classic" then
            if LucilleCore::askQuestionAnswerAsBoolean("> access ? ") then
                CoreData::access(task["uuid"], task["field11"])
            end
            return
        end

        if task["field11"] and LucilleCore::askQuestionAnswerAsBoolean("> access field11 ? ") then
            CoreData::access(task["uuid"], task["field11"])
        end

        loop  {
            puts "@stack:"
            task["stack"]
                .sort_by{|entry| entry["position"] }
                .each{|entry|
                    puts "   ・ #{NxTasks::stackEntryToString(entry)}"
                }
            puts ""
            puts "> add | top | stack | done | exit"
            command = LucilleCore::askQuestionAnswerAsString("commands: ")
            return if (command == "" or command == "exit")
            if command == "add" then
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                line = LucilleCore::askQuestionAnswerAsString("line: ")
                task["stack"] << NxTasks::makeStackPlusEntry(position, line)
                DarkEnergy::commit(task)
            end
            if command == "top" then
                position = task["stack"].map{|entry| entry["position"] }.min - rand
                line = LucilleCore::askQuestionAnswerAsString("line: ")
                task["stack"] << NxTasks::makeStackPlusEntry(position, line)
                DarkEnergy::commit(task)
            end
            if command == "done" then
                entries = task["stack"].sort_by{|entry| entry["position"] }
                entry = LucilleCore::selectEntityFromListOfEntitiesOrNull("entry", entries, lambda{|entry| entryToString.call(entry) })
                task["stack"] = task["stack"].reject{|e| e["uuid"] == entry["uuid"] }
                DarkEnergy::commit(task)
            end
            if command == "stack" then
                text = CommonUtils::editTextSynchronously("").strip
                next if text == ""
                lines = text.lines.to_a.reverse.map{|line| line.strip }
                lines.each{|line|
                    position = task["stack"].map{|entry| entry["position"] }.min - rand
                    task["stack"] << NxTasks::makeStackPlusEntry(position, line)
                }
                DarkEnergy::commit(task)
            end
        }
    end

    # NxTasks::maintenance()
    def self.maintenance()
        DarkEnergy::mikuType("NxTask").each{|task|
            next if task["coreuuid"].nil?
            core = DarkEnergy::itemOrNull(task["coreuuid"])
            if core.nil? then
                DarkEnergy::patch(task["uuid"], "coreuuid", nil)
            end
        }
    end

    # --------------------------------------------------
    # Stacks Ops

    # NxTasks::makeStackPlusEntry(position, line)
    def self.makeStackPlusEntry(position, line)
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "StackEntry",
            "variant"  => "plus",
            "position" => position,
            "line"     => line
        }
    end

    # NxTasks::initiateStack(item)
    def self.initiateStack(item)
        if item["mikuType"] != "NxTask" then
            puts "You cannot stack a non NxTask"
            LucilleCore::pressEnterToContinue()
            return
        end
        if item["variant"].nil? or item["variant"] == "classic" then
            item["variant"] = "stack"
            item["stack"] = []
            item["stack"] << {
                "uuid"        => SecureRandom.uuid,
                "mikuType"    => "StackEntry",
                "variant"     => "origin",
                "position"    => 0,
                "description" => item["description"],
                "field11"     => item["field11"]
            }
            DarkEnergy::commit(item)
        end
        NxTasks::access(item)
    end
end
