
class TaskList

    # -------------------------
    # Data

    # TaskList::interactivelySelectTaskListOrNull()
    def self.interactivelySelectTaskListOrNull()
        tasklists = Items::objects().map{|item| item["tlname-11"] }.compact.uniq
        LucilleCore::selectEntityFromListOfEntitiesOrNull("tasklist", tasklists)
    end

    # TaskList::suffix(item)
    def self.suffix(item)
        return "" if item["tlname-11"].nil?
        " (#{item["tlname-11"]})".yellow
    end

    # TaskList::firstPosition()
    def self.firstPosition()
        ([1] + Items::mikuType("NxTask").map{|item| item["tlpos-12"] }).min
    end

    # -------------------------
    # Ops

    # TaskList::attach(item)
    def self.attach(item)
        tasklists = Items::objects().map{|item| item["tlname-11"] }.compact.uniq
        if tasklists.size > 0 then
            tasklist = LucilleCore::selectEntityFromListOfEntitiesOrNull("tasklist", tasklists)
            if tasklist then
                Items::setAttribute(uuid, "tlname-11", tasklist)
                return
            end
        end
        if LucilleCore::askQuestionAnswerAsBoolean("You did not set a task list for '#{PolyFunctions::toString(item)}', create a new one ? : ", true) then
            tasklist = LucilleCore::askQuestionAnswerAsString("tasklist: ")
            if tasklist.size > 0 then
                Items::setAttribute(uuid, "tlname-11", tasklist)
                return
            end
        end
    end

    # TaskList::program(tasklist)
    def self.program(tasklist)
        loop {
            elements = Items::mikuType("NxTask")
                        .select{|item| item["tlname-11"] == tasklist }
            e1, e2 = elements.partition{|item| item["tlpos-12"] }
            elements = e1.sort_by{|item| item["tlpos-12"] } + e2

            store = ItemStore.new()
            puts ""
            elements
                .each{|item|
                    store.register(item, FrontPage::canBeDefault(item))
                    puts FrontPage::toString2(store, item)
                }
            puts "sort"
            input = LucilleCore::askQuestionAnswerAsString("> ")

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], elements, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|item|
                    Items::setAttribute(uuid, "tlpos-12", TaskList::firstPosition() - 1)
                }
                next
            end

            return if input == "exit"
            return if input == ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # TaskList::dive()
    def self.dive()
        loop {
            tasklist = TaskList::interactivelySelectTaskListOrNull()
            return if tasklist.nil?
            TaskList::program(tasklist)
        }
    end
end
