
# encoding: UTF-8

class Parenting

    # ---------------------------------------
    # Data

    # Parenting::itemBelongsToListing(item, listinguuid)
    def self.itemBelongsToListing(item, listinguuid)
        return false if item["clique9"].nil?
        item["clique9"]["uuid"] == listinguuid
    end

    # Parenting::itemPositionInListingOrZero(item, listinguuid)
    def self.itemPositionInListingOrZero(item, listinguuid)
        return 0 if item["clique9"].nil?
        return 0 if item["clique9"]["uuid"] != listinguuid
        item["clique9"]["position"]
    end

    # Parenting::suffix(item)
    def self.suffix(item)
        nx38ToParentNameOrNull = lambda {|nx38|
            parent = Blades::itemOrNull(nx38["uuid"])
            if parent.nil? then
                Parenting::removeMembership(item)
                return nil
            end
            parent["description"]
        }
        return "" if item["clique9"].nil?
        parentName = nx38ToParentNameOrNull.call(item["clique9"])
        return "" if parentName.nil?
        " (p: #{parentName})".yellow
    end

    # ---------------------------------------
    # Ops

    # Parenting::setMembership(item, nx38)
    def self.setMembership(item, nx38)
        Blades::setAttribute(item["uuid"], "clique9", nx38)
    end

    # Parenting::removeMembership(item)
    def self.removeMembership(item)
        Blades::setAttribute(item["uuid"], "clique9", nil)
    end
end
