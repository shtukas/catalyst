
class DxStack

    # DxStack::issue(target, position)
    def self.issue(target, position)
        Events::publishItemAttributeUpdate(target["uuid"], "stack-0620", position)
    end

    # Data

    # DxStack::toString(item)
    def self.toString(item)
        "#{"(stack: #{"%6.3f" % item["stack-0620"]})".green} #{PolyFunctions::toString(item)}"
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

    # DxStack::newNextPosition()
    def self.newNextPosition()
        DxStack::itemsInOrder().reduce(0){|x, item| [x, item["stack-0620"]].max } + 1
    end

    # Ops

    # DxStack::maintenance()
    def self.maintenance()
        horizon = DxStack::itemsInOrder().reduce(0){|x, item| [x, item["stack-0620"]].min }
        if horizon < 0 then
            DxStack::itemsInOrder().each{|item|
                Events::publishItemAttributeUpdate(item["uuid"], "stack-0620", item["stack-0620"]+(-horizon))
            }
        end
        horizon = DxStack::itemsInOrder().reduce(0){|x, item| [x, item["stack-0620"]].min }
        if horizon >= 100 then
            DxStack::itemsInOrder().each{|item|
                Events::publishItemAttributeUpdate(item["uuid"], "stack-0620", 0.9*item["stack-0620"])
            }
        end
    end

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
end