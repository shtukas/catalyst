
class Hierarchy

    # Hierarchy::getParentOrNull(item)
    def self.getParentOrNull(item)
        return nil if item["px14"].nil?
        Blades::itemOrNull(item["px14"])
    end

    # Hierarchy::getChildren(parent)
    def self.getChildren(parent)
        Blades::items().select{|item| item["px14"] == parent["uuid"] }
    end

    # Hierarchy::dive(principal)
    def self.dive(principal)
        loop {
            elements = Hierarchy::getChildren(principal)
            elements = elements.map{|element|
                if element["global-pos-07"].nil? then
                    element["global-pos-07"] = GlobalPositioning::first_position() - 1
                end
                Blades::setAttribute(element["uuid"], "global-pos-07", element["global-pos-07"])
                element
            }
            elements.sort_by{|item| item["global-pos-07"]}
            store = ItemStore.new()
            puts ""
            elements
                .each{|item|
                    store.register(item, FrontPage::canBeDefault(item))
                    puts FrontPage::toString2(store, item)
                }
            puts "new | sort"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            if input == "new" then
                task = NxTasks::interactivelyIssueNewOrNull(principal)
                next if task.nil?
                puts JSON.pretty_generate(task)
                XCache::destroy("87bb9013-7e9e-4d3f-b687-b693e047e134:#{principal["uuid"]}")
                next
            end
            if input == "sort" then
                items = Hierarchy::getChildren(principal)
                selected = CommonUtils::selectZeroOrMore(items, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|item|
                    GlobalPositioning::insert_first(item)
                }
                next
            end
            return if input == "exit"
            return if input == ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Hierarchy::suffix(item)
    def self.suffix(item)
        if Hierarchy::getChildren(item).size > 0 then
            return " [children]".yellow
        end
        ""
    end

    # Hierarchy::roots()
    def self.roots()
        Blades::mikuType("NxTask").select{|item| item["px14"].nil? }
    end

    # Hierarchy::listingItems()
    def self.listingItems()
        Blades::mikuType("NxTask").select{|item| item["px14"].nil? }
    end
end
