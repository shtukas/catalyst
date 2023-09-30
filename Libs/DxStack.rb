
class DxStack

    # DxStack::issue(target, position)
    def self.issue(target, position)
        uuid = SecureRandom.uuid
        Events::publishItemInit("DxStackItem", uuid)
        Events::publishItemAttributeUpdate(uuid, "targetuuid", target["uuid"])
        Events::publishItemAttributeUpdate(uuid, "position", position)
        Catalyst::itemOrNull(uuid)
    end

    # Data

    # DxStack::toString(item)
    def self.toString(item)
        target = Catalyst::itemOrNull(item["targetuuid"])
        if target then
            s = "(stack: #{"%6.3f" % item["position"]})".green
            "#{s} #{PolyFunctions::toString(target)}"
        else
            Catalyst::destroy(item["uuid"])
            "(stack) garbage collected"
        end
    end

    # DxStack::itemsInOrder()
    def self.itemsInOrder()
        Catalyst::mikuType("DxStackItem")
            .map{|item|
                target = Catalyst::itemOrNull(item["targetuuid"])
                if target then
                    if Listing::listable(target) then
                        item
                    else
                        Catalyst::destroy(item["uuid"])
                        nil
                    end
                else
                    Catalyst::destroy(item["uuid"])
                    nil
                end
            }
            .compact
            .sort_by{|item| item["position"]}
    end

    # DxStack::newFirstPosition()
    def self.newFirstPosition()
        Catalyst::mikuType("DxStackItem").reduce(0){|x, item| [x, item["position"]].min } - 1
    end

    # DxStack::newNextPosition()
    def self.newNextPosition()
        Catalyst::mikuType("DxStackItem").reduce(0){|x, item| [x, item["position"]].max } + 1
    end

    # Ops

    # DxStack::onTarget(item, l = lambda {|target| })
    def self.onTarget(item, l)
        target = Catalyst::itemOrNull(item["targetuuid"])
        return if target.nil?
        l.call(target)
    end

    # DxStack::maintenance()
    def self.maintenance()
        horizon = Catalyst::mikuType("DxStackItem").reduce(0){|x, item| [x, item["position"]].min }
        if horizon < 0 then
            Catalyst::mikuType("DxStackItem").each{|item|
                Events::publishItemAttributeUpdate(item["uuid"], "position", item["position"]+(-horizon))
            }
        end
        horizon = Catalyst::mikuType("DxStackItem").reduce(0){|x, item| [x, item["position"]].max }
        if horizon >= 100 then
            Catalyst::mikuType("DxStackItem").each{|item|
                Events::publishItemAttributeUpdate(item["uuid"], "position", 0.9*item["position"])
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

    # DxStack::destroyByTargetUUID(targetuuid)
    def self.destroyByTargetUUID(targetuuid)
        Catalyst::mikuType("DxStackItem")
            .select{|item| item["targetuuid"] == targetuuid }
            .each{|item|
                Catalyst::destroy(item["uuid"])
            }
    end
end