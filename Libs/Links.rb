
# encoding: UTF-8

class Links

    # Links::link(sourceuuid: String, targetuuid: String, isBidirectional: Boolean)
    def self.link(sourceuuid, targetuuid, isBidirectional)
        return if (sourceuuid == targetuuid)

        Links::unlink(sourceuuid, targetuuid)

        item = {
            "uuid"          => SecureRandom.uuid,
            "mikuType"      => "Lx21",
            "sourceuuid"    => sourceuuid,
            "targetuuid"    => targetuuid,
            "bidirectional" => isBidirectional
        }
        #puts JSON.pretty_generate(item)
        Librarian6ObjectsLocal::commit(item)
    end

    # Links::unlink(sourceuuid, targetuuid)
    def self.unlink(sourceuuid, targetuuid)
        Librarian6ObjectsLocal::getObjectsByMikuType("Lx21")
            .select{|item|
                b1 = (item["sourceuuid"] == sourceuuid and item["targetuuid"] == targetuuid)
                b2 = (item["sourceuuid"] == targetuuid and item["targetuuid"] == sourceuuid)
                b1 or b2
            }
            .each{|item| Librarian6ObjectsLocal::destroy(item["uuid"]) }
    end

    # ------------------------------------------------
    # Relations UUIDs

    # Links::relatedUUIDs(uuid)
    def self.relatedUUIDs(uuid)
        uuids1 = Librarian6ObjectsLocal::getObjectsByMikuType("Lx21")
                    .select{|item| item["sourceuuid"] == uuid and item["bidirectional"] }
                    .map{|item| item["targetuuid"] }

        uuids2 = Librarian6ObjectsLocal::getObjectsByMikuType("Lx21")
                    .select{|item| item["targetuuid"] == uuid and item["bidirectional"] }
                    .map{|item| item["sourceuuid"] }
        uuids1 + uuids2
    end

    # Links::parentUUIDs(uuid)
    def self.parentUUIDs(uuid)
        Librarian6ObjectsLocal::getObjectsByMikuType("Lx21")
            .select{|item| item["targetuuid"] == uuid and !item["bidirectional"] }
            .map{|item| item["sourceuuid"] }
    end

    # Links::childrenUUIDs(uuid)
    def self.childrenUUIDs(uuid)
        Librarian6ObjectsLocal::getObjectsByMikuType("Lx21")
            .select{|item| item["sourceuuid"] == uuid and !item["bidirectional"] }
            .map{|item| item["targetuuid"] }
    end

    # ------------------------------------------------
    # Relations Objects

    # Links::related(uuid)
    def self.related(uuid)
        Links::relatedUUIDs(uuid)
            .map{|uuid| Librarian6ObjectsLocal::getObjectByUUIDOrNull(uuid) }
            .compact
    end

    # Links::parents(uuid)
    def self.parents(uuid)
        Links::parentUUIDs(uuid)
            .map{|uuid| Librarian6ObjectsLocal::getObjectByUUIDOrNull(uuid) }
            .compact
    end

    # Links::children(uuid)
    def self.children(uuid)
        Links::childrenUUIDs(uuid)
            .map{|uuid| Librarian6ObjectsLocal::getObjectByUUIDOrNull(uuid) }
            .compact
    end

    # Links::linked(uuid)
    def self.linked(uuid)
         Links::parents(uuid) + Links::related(uuid) + Links::children(uuid)
    end

    # ------------------------------------------------
    # Data

    # Links::linkTypeOrNull(itemuuid, otheruuid)
    def self.linkTypeOrNull(itemuuid, otheruuid)
        if Links::relatedUUIDs(itemuuid).include?(otheruuid) then
            return "related"
        end
        if Links::parentUUIDs(itemuuid).include?(otheruuid) then
            return "parent"
        end
        if Links::childrenUUIDs(itemuuid).include?(otheruuid) then
            return "child"
        end
        nil
    end
end
