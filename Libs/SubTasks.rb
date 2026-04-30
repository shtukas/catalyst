
# encoding: UTF-8

class SubTasks
    # SubTasks::link(parent, child)
    def self.link(parent, child)
        r1 = parent["subtasks-24"] || []
        r1 << child["uuid"]
        r1 = r1.uniq
        r1 = r1.select{|uuid| Items::itemOrNull(uuid) } # taking the opportunity to do some data quality
        Items::setAttribute(parent["uuid"], "subtasks-24", r1)
        Items::setAttribute(child["uuid"], "parent-task-25", parent["uuid"])
    end

    # SubTasks::getSubtasks(parent)
    def self.getSubtasks(parent)
        return [] if parent["subtasks-24"].nil?
        parent["subtasks-24"].map{|uuid| Items::itemOrNull(uuid) }.compact
    end

    # SubTasks::normaliseChildrenArray(item)
    def self.normaliseChildrenArray(item)
        return item if item["subtasks-24"].nil?
        uuids = item["subtasks-24"].select{|uuid| Items::itemOrNull(uuid) }
        if uuids.size < item["subtasks-24"].size then
            item["subtasks-24"] = uuids
            Items::setAttribute(item["uuid"], "subtasks-24", uuids)
        end
        item
    end
end
