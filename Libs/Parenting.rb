# encoding: UTF-8

#Px13 {
#    "parentuuid" : String
#    "position"   : Float
#}

class Parenting

    # Parenting::childrenInOrder(parent)
    def self.childrenInOrder(parent)
        Blades::items()
            .select{|item| item["mikuType"] != "NxDeleted" }
            .select{|item|
                item["parenting-13"] and item["parenting-13"]["parentuuid"] == parent["uuid"]
            }
            .sort_by{|item| item["parenting-13"]["position"] }
    end

    # Parenting::firstPositionInParent(parent)
    def self.firstPositionInParent(parent)
        ([0] + Parenting::childrenInOrder(parent).map{|item| item["parenting-13"]["position"] }).min
    end

    # Parenting::firstPositionAmongOrphans()
    def self.firstPositionAmongOrphans()
        (
            [0] + 
            Parenting::childrenInOrder(parent)
                .select{|item| item["parenting-13"]["parentuuid"].nil? }
                .map{|item| item["parenting-13"]["position"] }
        ).min
    end

    # Parenting::interactivelyDeterminePositionInParent(parent)
    def self.interactivelyDeterminePositionInParent(parent)
        puts "children:"
        Parenting::childrenInOrder(parent).each{|item|
            puts PolyFunctions::toString(item)
        }
        LucilleCore::askQuestionAnswerAsString("position (empty for next): ").to_f
    end

    # Parenting::dive(parent)
    def self.dive(parent)
        loop {
            elements = Parenting::childrenInOrder(parent)
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
                position = Parenting::interactivelyDeterminePositionInParent(parent)
                BladesFront::setAttribute(item["uuid"], "parenting-13", {
                    "parentuuid" => parent["uuid"],
                    "position"   => position
                })
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], elements, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|item|
                    position = Parenting::firstPositionInParent(parent) - 1
                    BladesFront::setAttribute(item["uuid"], "parenting-13", {
                        "parentuuid" => parent["uuid"],
                        "position"   => position
                    })
                }
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Parenting::determineAndUpdateChildrenSetSize(item)
    def self.determineAndUpdateChildrenSetSize(item)
        count = Parenting::childrenInOrder(item).size
        BladesFront::setAttribute(item["uuid"], "sx10", count)
        count
    end

    # Parenting::suffix(item)
    def self.suffix(item)
        if item["sx10"] and item["sx10"] > 10 then
            return " (#{item["sx10"]} children)".yellow
        end
        " (unkown children count)".yellow
    end

    # Parenting::selectParentForMove(reference = nil)
    def self.selectParentForMove(reference = nil)
        # return an reference (which can be made a parent) or null
        if reference.nil? then
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("selection", Orphans::orphansInOrder(), lambda{|item| PolyFunctions::toString(item) })
            return nil if item.nil?
            return Parenting::selectParentForMove(item)
        end
        puts "reference: #{PolyFunctions::toString(reference)}"
        children = Parenting::childrenInOrder(reference)
        if children.empty? then
            return reference
        end
        item = LucilleCore::selectEntityFromListOfEntitiesOrNull("selection", children, lambda{|item| PolyFunctions::toString(item) })
        return reference if item.nil?
        return Parenting::selectParentForMove(item)
    end

    # Parenting::move(item)
    def self.move(item)
        # We select a parent or null
        # We determine a position
        # We mark
        parent = Parenting::selectParentForMove(nil)
        return if parent.nil?
        position = Parenting::interactivelyDeterminePositionInParent(parent)
        BladesFront::setAttribute(item["uuid"], "parenting-13", {
            "parentuuid" => parent["uuid"],
            "position"   => position
        })
    end
end
