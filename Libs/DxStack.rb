
class DxStack

    # Data

    # DxStack::itemsInOrder()
    def self.itemsInOrder()
        Catalyst::catalystItems()
            .select{|item| item["stack-0012"] and (item["stack-0012"][0] == CommonUtils::today()) }
            .sort_by{|item| item["stack-0012"][1]}
    end

    # DxStack::newFirstPosition()
    def self.newFirstPosition()
        DxStack::itemsInOrder().reduce(0){|x, item| [x, item["stack-0012"][1]].min } - 1
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
                Events::publishItemAttributeUpdate(task["uuid"], "active-1634", true)
                Events::publishItemAttributeUpdate(task["uuid"], "stack-0012", [CommonUtils::today(), DxStack::newFirstPosition()])
            }
    end

    # DxStack::unregister(item)
    def self.unregister(item)
        return if item["stack-0012"].nil?
        Events::publishItemAttributeUpdate(item["uuid"], "stack-0012", nil)
    end
end