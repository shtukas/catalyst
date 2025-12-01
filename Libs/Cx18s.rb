
class Cx18s

    # ---------------------------------------
    # Data

    # Cx18s::cx18s()
    def self.cx18s()
        hash1 = {}
        Items::mikuType("NxTask")
            .map{|item| item["cx18"] }
            .compact
            .each{|cx18|
                hash1[cx18["uuid"]] = cx18
            }
        hash1.values
    end

    # Cx18s::cx18Items(uuid)
    def self.cx18Items(uuid)
        Items::mikuType("NxTask")
            .select{|item| item["cx18"] }
            .select{|item| item["cx18"]["uuid"] == uuid }
    end

    # Cx18s::cx18Size(uuid)
    def self.cx18Size(uuid)
        Cx18s::cx18Items(uuid).size
    end

    # Cx18s::firstOrdinal(uuid)
    def self.firstOrdinal(uuid)
        positions = Cx18s::cx18Items(uuid)
            .map{|item| item["px36"] }
        (positions + [1]).min
    end

    # Cx18s::lastOrdinal(uuid)
    def self.lastOrdinal(uuid)
        positions = Cx18s::cx18Items(uuid)
            .map{|item| item["px36"] }
        (positions + [1]).max
    end

    # Cx18s::firstItem(uuid)
    def self.firstItem(uuid)
        Cx18s::cx18Items(uuid).sort_by{|item| item["px36"] }.first
    end

    # Cx18s::interativelyDecidePosition(uuid) # position
    def self.interativelyDecidePosition(uuid)
        elements = Cx18s::cx18Items(uuid).sort_by{|item| item["px36"] }
        if elements.empty? then
            return 1
        end
        elements.first(20).each{|item|
            puts "(position: #{item["px36"]}) #{item["description"]}"
        }
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        if position == "" then
            return Cx18s::lastOrdinal(uuid) + 1
        end
        position.to_f
    end

    # Cx18s::architechCx18OrNull()
    def self.architechCx18OrNull()
        cx18 = Cx18s::interactivelySelectCx18OrNull()
        return nil if cx18.nil?
        cx18
    end

    # ---------------------------------------
    # Ops

    # Cx18s::interactivelySelectCx18OrNull()
    def self.interactivelySelectCx18OrNull()
        cx18s = Cx18s::cx18s()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", cx18s, lambda{|cx18| "#{cx18["name"]} (#{Cx18s::cx18Size(cx18["uuid"])})" })
    end

    # Cx18s::generalDive()
    def self.generalDive()
        cx18 = Cx18s::interactivelySelectCx18OrNull()
        return if cx18.nil?
        Cx18s::diveCx18(cx18)
    end

    # Cx18s::diveCx18(cx18)
    def self.diveCx18(cx18)

        loop {
            elements = Cx18s::cx18Items(cx18["uuid"]).sort_by{|item| item["px36"] }
            store = ItemStore.new()
            puts ""
            elements
                .each{|item|
                    store.register(item, FrontPage::canBeDefault(item))
                    puts FrontPage::toString2(store, item)
                }
            puts ""
            puts "sort (clique)"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""
            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], elements, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|item|
                    Items::setAttribute(item["uuid"], "px36", Cx18s::firstOrdinal(cx18["uuid"]) - 1)
                }
                next
            end
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Sequences::moveToSequence(item)
    def self.moveToSequence(item)
        cx18 = Cx18s::architechCx18OrNull()
        return if cx18.nil?
        Items::setAttribute(item["uuid"], "cx18", cx18)
    end
end
