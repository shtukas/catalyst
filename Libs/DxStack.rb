
class DxStack

    # DxStack::issue(item, position)
    def self.issue(item, position)
        Events::publishItemAttributeUpdate(item["uuid"], "stack-0620", position)
    end

    # Data

    # DxStack::toString(item)
    def self.toString(item)
        "#{PolyFunctions::toString(item)}"
    end

    # DxStack::itemsInOrder()
    def self.itemsInOrder()
        Catalyst::catalystItems()
            .select{|item| item["stack-0620"] }
            .sort_by{|item| item["stack-0620"]}
    end

    # DxStack::newFirstPosition()
    def self.newFirstPosition()
        DxStack::itemsInOrder().reduce(0){|x, item| [x, item["stack-0620"]].min } - 1
    end

    # Ops

    # DxStack::pile3()
    def self.pile3()
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text
            .lines
            .map{|line| line.strip }
            .reverse
            .each{|line|
                task = NxTasks::descriptionToTask1(SecureRandom.uuid, line)
                puts JSON.pretty_generate(task)
                DxStack::issue(task, DxStack::newFirstPosition())
            }
    end

    # DxStack::unregister(item)
    def self.unregister(item)
        return if item["stack-0620"].nil?
        Events::publishItemAttributeUpdate(item["uuid"], "stack-0620", nil)
    end

    # DxStack::diversify()
    def self.diversify()
        stack   = DxStack::itemsInOrder()
        engined = Catalyst::enginedInOrder()
        waves   = Waves::listingItems().select{|item| !item["interruption"] }
        tasks   = NxTasks::orphans()
        loop {
            return if stack.size < 2
            p1 = stack[0]["stack-0620"]
            p2 = stack[1]["stack-0620"]
            if something = engined.shift then
                Events::publishItemAttributeUpdate(something["uuid"], "stack-0620", p1 + 0.25*(p2-p1))
            end
            if something = waves.shift then
                Events::publishItemAttributeUpdate(something["uuid"], "stack-0620", p1 + 0.50*(p2-p1))
            end
            if something = tasks.shift then
                Events::publishItemAttributeUpdate(something["uuid"], "stack-0620", p1 + 0.75*(p2-p1))
            end
            stack.shift
        }
    end
end