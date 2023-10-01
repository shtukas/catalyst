

class NxTasks

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        Events::publishItemInit("NxTask", uuid)

        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)

        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "field11", coredataref)
        Events::publishItemAttributeUpdate(uuid, "global-position", NxTasks::newGlobalLastPosition())

        if LucilleCore::askQuestionAnswerAsBoolean("send to stack ? ", false) then
            position = LucilleCore::askQuestionAnswerAsString("stack position: ").to_f
            DxStack::issue(Catalyst::itemOrNull(uuid), position)
        else
            engine = TxEngine::interactivelyMakeOrNull()
            if engine then
                Events::publishItemAttributeUpdate(uuid, "engine-2251", engine)
            end
        end
        Catalyst::itemOrNull(uuid)
    end

    # NxTasks::urlToTask(url)
    def self.urlToTask(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid

        Events::publishItemInit("NxTask", uuid)

        nhash = Datablobs::putBlob(url)
        coredataref = "url:#{nhash}"

        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "field11", coredataref)
        Catalyst::itemOrNull(uuid)
    end

    # NxTasks::bufferInLocationToTask(location)
    def self.bufferInLocationToTask(location)
        description = "(buffer-in) #{File.basename(location)}"
        uuid = SecureRandom.uuid

        Events::publishItemInit("NxTask", uuid)

        coredataref = CoreDataRefStrings::locationToAionPointCoreDataReference(uuid, location)

        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "field11", coredataref)
        Events::publishItemAttributeUpdate(uuid, "global-position", NxTasks::newGlobalLastPosition())
        Catalyst::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask1(uuid, description)
    def self.descriptionToTask1(uuid, description)
        Events::publishItemInit("NxTask", uuid)
        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "global-position", NxTasks::newGlobalLastPosition())
        Catalyst::itemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        icon = NxTasks::quarksInOrder(item).size > 0 ? "🔺" : "🔹"
        count = NxTasks::quarksInOrder(item).size
        s1 = (count > 0) ? "(#{count.to_s.rjust(3)})" : "     "
        "#{icon} #{s1} #{TxEngine::prefix(item)}#{item["description"]}#{TxCores::suffix(item)}"
    end

    # NxTasks::newGlobalFirstPosition()
    def self.newGlobalFirstPosition()
        t = Catalyst::mikuType("NxTask")
                .select{|item| item["global-position"] }
                .map{|item| item["global-position"] }
                .reduce(0){|number, x| [number, x].min}
        t - 1
    end

    # NxTasks::newGlobalLastPosition()
    def self.newGlobalLastPosition()
        t = Catalyst::mikuType("NxTask")
                .select{|item| item["global-position"] }
                .map{|item| item["global-position"] }
                .reduce(0){|number, x| [number, x].max }
        t + 1
    end

    # NxTasks::engined()
    def self.engined()
        Catalyst::mikuType("NxTask")
            .select{|item| item["engine-2251"] }
    end

    # NxTasks::orphans()
    def self.orphans()
        Catalyst::mikuType("NxTask")
            .select{|item| item["coreX-2300"].nil? }
            .sort_by{|item| item["unixtime"] }
            .reverse
    end

    # NxTasks::quarksInOrder(item)
    def self.quarksInOrder(item)
        NxQuarks::quarksForTaskInOrder(item["uuid"])
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(task)
    def self.access(task)
        CoreDataRefStrings::accessAndMaybeEdit(task["uuid"], task["field11"])
    end

    # NxTasks::maintenance()
    def self.maintenance()

        Catalyst::mikuType("NxTask").each{|item|
            if item["coreX-2300"] and Catalyst::itemOrNull(item["coreX-2300"]).nil? then
                Events::publishItemAttributeUpdate(item["uuid"], "coreX-2300", nil)
            end
        }

        # Pick up NxFronts-BufferIn
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataHub/NxFronts-BufferIn").each{|location|
            next if File.basename(location)[0, 1] == "."
            NxTasks::bufferInLocationToTask(location)
            LucilleCore::removeFileSystemLocation(location)
        }

        # Feed Infinity using NxIce
        if Catalyst::mikuType("NxTask").size < 100 then
            Catalyst::mikuType("NxIce").take(10).each{|item|

            }
        end
    end

    # NxTasks::fsck()
    def self.fsck()
        Catalyst::mikuType("NxTask").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end

    # NxTasks::pile3(task)
    def self.pile3(task)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text
            .lines
            .map{|line| line.strip }
            .reverse
            .each{|line|
                quark = NxQuarks::descriptionToTask1(task["uuid"], line)
                puts JSON.pretty_generate(quark)
            }
    end

    # NxTasks::program1(task)
    def self.program1(task)
        loop {

            task = Catalyst::itemOrNull(task["uuid"])
            return if task.nil?

            system("clear")

            store = ItemStore.new()

            puts  ""
            store.register(task, false)
            puts  Listing::toString2(store, task)
            puts  ""

            Prefix::prefix(NxTasks::quarksInOrder(task))
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::toString2(store, item)
                }

            puts ""
            puts "quark | pile | sort"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "quark" then
                quark = NxQuarks::interactivelyIssueNewOrNull(task["uuid"])
                next if quark.nil?
                puts JSON.pretty_generate(quark)
                next
            end

            if input == "pile" then
                NxTasks::pile3(task)
                next
            end

            if Interpreting::match("sort", input) then
                quarks = NxTasks::quarksInOrder(task)
                selected, _ = LucilleCore::selectZeroOrMore("quarks", [], quarks, lambda{|quark| PolyFunctions::toString(quark) })
                selected.reverse.each{|quark|
                    Events::publishItemAttributeUpdate(quark["uuid"], "global-position", NxTasks::newGlobalFirstPosition())
                }
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end
end
