

class Parenting

    # Parenting::set(parentuuid, childuuid)
    def self.set(parentuuid, childuuid)
        parent = DarkEnergy::itemOrNull(parentuuid)
        child = DarkEnergy::itemOrNull(childuuid)
        return if parent.nil?
        return if child.nil?
        if parent["children"].nil? then
            parent["children"] = []
        end
        parent["children"] << childuuid
        parent["children"] = parent["children"].uniq
        child["parent"] = parentuuid
        DarkEnergy::commit(parent)
        DarkEnergy::commit(child)
    end
end
