
class NxStacks

    # NxStacks::issueNext(description, previous)
    def self.issueNext(description, previous)
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxStackItem", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "previousuuid", previous["uuid"])
        DarkEnergy::itemOrNull(uuid)
    end

    # NxStacks::interactivelyStackNextOrNothing(item)
    def self.interactivelyStackNextOrNothing(item)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        NxStacks::issueNext(description, item)
    end

    # NxStacks::toString(item)
    def self.toString(item)
        "🥞 (stack item) #{item["description"]}"
    end

    # NxStacks::getNextElementOrNull(element)
    def self.getNextElementOrNull(element)
        DarkEnergy::mikuType("NxStackItem")
            .select{|item| item["previousuuid"] == element["uuid"] }
            .first
    end

    # NxStacks::stack(cursor)
    def self.stack(cursor)
        items = [cursor]
        loop {
            nexti = NxStacks::getNextElementOrNull(cursor)
            break if nexti.nil?
            items =  [nexti] + items
            cursor = nexti
        }
        items
    end

    # NxStacks::pile(cursor)
    def self.pile(cursor)
        if !["NxTask", "NxStackItem"].include?(cursor["mikuType"]) then
            puts "You can only pile a NxTask or a NxStackItem"
            LucilleCore::pressEnterToContinue()
            return
        end
        stack = NxStacks::stack(cursor)
        NxStacks::interactivelyStackNextOrNothing(stack.first)
    end

    # NxStacks::destroyStackItem(item)
    def self.destroyStackItem(item)
        if item["mikuType"] != "NxStackItem" then
            raise "attempting to NxStacks::destroyStackItem a non NxStackItem: item: #{item}"
        end
        if NxStacks::getNextElementOrNull(item) then
            puts "attempting to NxStacks::destroyStackItem a non top element of a stack (found a next)"
            LucilleCore::pressEnterToContinue()
            return
        end
        DarkEnergy::destroy(item["uuid"])
    end

    # NxStacks::stackItemToTask(item)
    def self.stackItemToTask(item)
        if item["mikuType"] != "NxStackItem" then
            raise "attempting to NxStacks::stackItemToTask a non NxStackItem: item: #{item}"
        end
        previous = DarkEnergy::itemOrNull(item["previousuuid"])
        return previous if previous["mikuType"] == "NxTask"
        NxStacks::stackItemToTask(previous)
    end
end