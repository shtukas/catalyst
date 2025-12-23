
class Cores

    # -------------------------
    # Data

    # Cores::interactivelySelectTaskListOrNull()
    def self.interactivelySelectTaskListOrNull()
        cores = Items::objects().map{|item| item["tlname-11"] }.compact.uniq
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores)
    end

    # Cores::suffix(item)
    def self.suffix(item)
        return "" if item["tlname-11"].nil?
        " (#{item["tlname-11"]})".yellow
    end

    # Cores::distinctNames()
    def self.distinctNames()
        Items::objects().map{|item| item["tlname-11"] }.compact.uniq
    end

    # -------------------------
    # Ops

    # Cores::attach(item)
    def self.attach(item)
        cores = Cores::distinctNames()
        if cores.size > 0 then
            core = LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores)
            if core then
                Items::setAttribute(item["uuid"], "tlname-11", core)
                return
            end
        end
        if LucilleCore::askQuestionAnswerAsBoolean("You did not set a task list for '#{PolyFunctions::toString(item)}', create a new one ? : ", true) then
            core = LucilleCore::askQuestionAnswerAsString("core: ")
            if core.size > 0 then
                Items::setAttribute(item["uuid"], "tlname-11", core)
                return
            end
        end
    end

    # Cores::program(core)
    def self.program(core)
        loop {
            elements = Items::mikuType("NxTask")
                        .select{|item| item["tlname-11"] == core }
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

    # Cores::dive()
    def self.dive()
        loop {
            core = Cores::interactivelySelectTaskListOrNull()
            return if core.nil?
            Cores::program(core)
        }
    end
end
