

class Catalyst

    # Catalyst::listingCompletionRatio(item)
    def self.listingCompletionRatio(item)
        if item["mikuType"] == "NxTask" then
            return Bank::recoveredAverageHoursPerDay(item["uuid"])
        end
        if item["mikuType"] == "TxCore" then
            hours = item["hours"]
            return Bank::recoveredAverageHoursPerDay(item["uuid"]).to_f/(hours.to_f/6)
        end
        if item["mikuType"] == "NxClique" then
            return TxEngine::ratio(item["engine-2251"])
        end
        raise "(error: 3b1e3b09-1472-48ef-bcbb-d98c8d170056) with item: #{item}"
    end

    # Catalyst::editItem(item)
    def self.editItem(item)
        item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
        item.to_a.each{|key, value|
            Events::publishItemAttributeUpdate(item["uuid"], key, value)
        }
    end

    # Catalyst::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        EventTimelineDatasets::catalystItems()[uuid].clone
    end

    # Catalyst::mikuType(mikuType)
    def self.mikuType(mikuType)
        EventTimelineDatasets::catalystItems().values.select{|item| item["mikuType"] == mikuType }
    end

    # Catalyst::destroy(uuid)
    def self.destroy(uuid)
        Events::publishItemDestroy(uuid)
    end

    # Catalyst::catalystItems()
    def self.catalystItems()
        EventTimelineDatasets::catalystItems().values
    end

    # Catalyst::newGlobalFirstPosition()
    def self.newGlobalFirstPosition()
        t = Catalyst::catalystItems()
                .select{|item| item["global-position"] }
                .map{|item| item["global-position"] }
                .reduce(0){|number, x| [number, x].min}
        t - 1
    end

    # Catalyst::newGlobalLastPosition()
    def self.newGlobalLastPosition()
        t = Catalyst::catalystItems()
                .select{|item| item["global-position"] }
                .map{|item| item["global-position"] }
                .reduce(0){|number, x| [number, x].max }
        t + 1
    end

    # Catalyst::engined()
    def self.engined()
        (Catalyst::mikuType("NxTask") + Catalyst::mikuType("NxClique"))
            .select{|item| item["engine-2251"] }
    end

    # Catalyst::pile3(item)
    def self.pile3(item)
        if item["mikuType"] == "NxCore" then
            TxCores::pile3(core)
            return
        end

        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text
            .lines
            .map{|line| line.strip }
            .reverse
            .each{|line|
                task = NxTasks::descriptionToTask1(SecureRandom.uuid, line)
                puts JSON.pretty_generate(task)
                NxCliques::prepend(item, task)
            }
    end

    # Catalyst::elementsInOrder(clique)
    def self.elementsInOrder(clique)
        Catalyst::catalystItems()
            .select{|item| item["parent-1328"] == clique["uuid"] }
            .sort_by {|item| item["global-position"] }
    end

    # Catalyst::program1(parent)
    def self.program1(parent)
        loop {

            parent = Catalyst::itemOrNull(parent["uuid"])
            return if parent.nil?

            system("clear")

            store = ItemStore.new()

            puts  ""
            store.register(parent, false)
            puts  Listing::toString2(store, parent)
            puts  ""

            Catalyst::elementsInOrder(parent)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::toString2(store, item)
                }

            puts ""
            puts "task | pile | pile * | sort"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Events::publishItemAttributeUpdate(task["uuid"], "parent-1328", parent["uuid"])
                next
            end

            if input == "pile" then
                Catalyst::pile3(parent)
                next
            end

            if input == "sort" then
                items = Catalyst::elementsInOrder(parent)
                selected, _ = LucilleCore::selectZeroOrMore("items", [], items, lambda{|item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    Events::publishItemAttributeUpdate(item["uuid"], "global-position", Catalyst::newGlobalFirstPosition())
                }
                next
            end
            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end
end
