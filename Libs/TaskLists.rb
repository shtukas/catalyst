
class TaskLists

    # -------------------------
    # Data

    # TaskLists::interactivelySelectTaskListOrNull()
    def self.interactivelySelectTaskListOrNull()
        tasklists = Items::objects().map{|item| item["tlname-11"] }.compact.uniq
        LucilleCore::selectEntityFromListOfEntitiesOrNull("tasklist", tasklists)
    end

    # TaskLists::suffix(item)
    def self.suffix(item)
        return "" if item["tlname-11"].nil?
        " (#{item["tlname-11"]})".yellow
    end

    # TaskLists::distinctNames()
    def self.distinctNames()
        Items::objects().map{|item| item["tlname-11"] }.compact.uniq
    end

    # -------------------------
    # Ops

    # TaskLists::attach(item)
    def self.attach(item)
        tasklists = TaskLists::distinctNames()
        if tasklists.size > 0 then
            tasklist = LucilleCore::selectEntityFromListOfEntitiesOrNull("tasklist", tasklists)
            if tasklist then
                Items::setAttribute(item["uuid"], "tlname-11", tasklist)
                return
            end
        end
        if LucilleCore::askQuestionAnswerAsBoolean("You did not set a task list for '#{PolyFunctions::toString(item)}', create a new one ? : ", true) then
            tasklist = LucilleCore::askQuestionAnswerAsString("tasklist: ")
            if tasklist.size > 0 then
                Items::setAttribute(item["uuid"], "tlname-11", tasklist)
                return
            end
        end
    end

    # TaskLists::program(tasklist)
    def self.program(tasklist)
        loop {
            elements = Items::mikuType("NxTask")
                        .select{|item| item["tlname-11"] == tasklist }
            store = ItemStore.new()
            puts ""
            elements
                .each{|item|
                    store.register(item, FrontPage::canBeDefault(item))
                    puts FrontPage::toString2(store, item)
                }
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # TaskLists::dive()
    def self.dive()
        loop {
            tasklist = TaskLists::interactivelySelectTaskListOrNull()
            return if tasklist.nil?
            TaskLists::program(tasklist)
        }
    end
end
