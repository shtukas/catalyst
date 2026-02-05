# encoding: UTF-8

class Dispatch

    # Dispatch::get_structure()
    def self.get_structure()
        structure = XCache::getOrNull("1267a50d-6b43-4efe-9ff3-588d4b8cf9d4")
        if structure then
            structure = JSON.parse(structure)
        else
            structure = {
                "tasks"              => [],
                "waves"              => [],
                "last-done-mikuType" => nil
            }
        end
    end

    # Dispatch::commit_structure(structure)
    def self.commit_structure(structure)
        XCache::set("1267a50d-6b43-4efe-9ff3-588d4b8cf9d4", JSON.generate(structure))
    end

    # Dispatch::structure_uuids(structure)
    def self.structure_uuids(structure)
        (structure["tasks"] + structure["tasks"]).map{|item| item["uuid"] }
    end

    # Dispatch::remove(itemuuid)
    def self.remove(itemuuid)
        structure = Dispatch::get_structure()
        if Dispatch::structure_uuids(structure).include?(itemuuid) then
            structure["waves"] = structure["waves"].select{|i| i["uuid"] != itemuuid }
            structure["tasks"] = structure["tasks"].select{|i| i["uuid"] != itemuuid }
            Dispatch::commit_structure(structure)
        end
    end

    # Dispatch::ensure(item)
    def self.ensure(item)
        structure = Dispatch::get_structure()
        if !Dispatch::structure_uuids(structure).include?(item["uuid"]) then
            if item["mikuType"] == "Wave" then
                structure["waves"] = structure["waves"] + [item]
            else
                structure["tasks"] = structure["tasks"] + [item]
            end
            Dispatch::commit_structure(structure)
        end
    end

    # Dispatch::itemsForListing()
    def self.itemsForListing()
        structure = Dispatch::get_structure()
        structure["tasks"] + structure["waves"]
    end
end
