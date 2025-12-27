
class Orphans

    # Orphans::orphansInOrder()
    def self.orphansInOrder()
        Blades::mikuType("NxTask")
            .select{|item| item["parenting-13"]["parentuuid"].nil? }
            .sort_by{|item| item["parenting-13"]["position"] }
    end

    # Orphans::firstPositionAmongOrphans()
    def self.firstPositionAmongOrphans()
        (
            [0] + 
            Orphans::orphansInOrder()
                .map{|item| item["parenting-13"]["position"] }
        ).min
    end

    # Orphans::lastPositionAmongOrphans()
    def self.lastPositionAmongOrphans()
        (
            [0] + 
            Orphans::orphansInOrder()
                .map{|item| item["parenting-13"]["position"] }
        ).max
    end

    # Orphans::dive()
    def self.dive()
        loop {
            elements = Orphans::orphansInOrder()
            store = ItemStore.new()
            puts ""
            elements
                .each{|item|
                    store.register(item, FrontPage::canBeDefault(item))
                    puts FrontPage::toString2(store, item)
                }
            puts "new | sort"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "new" then
                item = NxTasks::interactivelyIssueNewOrNull()
                Blades::setAttribute(item["uuid"], "parenting-13", {
                    "parentuuid" => nil,
                    "position"   => Orphans::lastPositionAmongOrphans() + 1
                })
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], elements, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|item|
                    Blades::setAttribute(item["uuid"], "parenting-13", {
                        "parentuuid" => nil,
                        "position"   => Orphans::firstPositionAmongOrphans() - 1
                    })
                }
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

end
