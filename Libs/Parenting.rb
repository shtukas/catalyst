# encoding: UTF-8

#Px13 {
#    "parentuuid" : String
#    "position"   : Float
#}

class Parenting

    # Parenting::childrenInOrder(parent)
    def self.childrenInOrder(parent)
        Blades::items_enumerator()
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
                Blades::setAttribute(item["uuid"], "parenting-13", {
                    "parentuuid" => parent["uuid"],
                    "position"   => position
                })
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], elements, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|item|
                    position = Parenting::firstPositionInParent(parent) - 1
                    Blades::setAttribute(item["uuid"], "parenting-13", {
                        "parentuuid" => parent["uuid"],
                        "position"   => position
                    })
                }
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Parenting::determineChildrenSetSizeForce(item)
    def self.determineChildrenSetSizeForce(item)
        #{
        #    "unixtime" Integer
        #    "count"    Integer
        #}
        count = Parenting::childrenInOrder(item).size
        Blades::setAttribute(item["uuid"], "Sx09", {
            "unixtime" => Time.new.to_i,
            "count"    => count
        })
        count
    end

    # Parenting::determineChildrenSetSizeOrNull(item)
    def self.determineChildrenSetSizeOrNull(item)
        #{
        #    "unixtime" Integer
        #    "count"    Integer
        #}

        # We use the information we have if it's less than a day old

        if item["Sx09"] then
            if Time.new.to_i - item["Sx09"]["unixtime"] < 86400 then
                return item["Sx09"]["count"]
            end
        end

        # We perform a from zero determination but we limit those at 100 per hour

        hour_count = XCache::getOrDefaultValue("8da24e62-fe05-4a7c-84a9-106b86eec746:#{Time.new.to_s[0, 13]}", "0").to_i
        return nil if hour_count >= 100
        XCache::set("8da24e62-fe05-4a7c-84a9-106b86eec746:#{Time.new.to_s[0, 13]}", hour_count + 1)
        Parenting::determineChildrenSetSizeForce(item)
    end

    # Parenting::suffix(item)
    def self.suffix(item)
        count = Parenting::determineChildrenSetSizeOrNull(item)
        if count then
            return "" if count == 0
            " (#{count} children)".yellow
        else
            " (unkown children count)".yellow
        end
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
        Blades::setAttribute(item["uuid"], "parenting-13", {
            "parentuuid" => parent["uuid"],
            "position"   => position
        })
    end
end
