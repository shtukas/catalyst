
# encoding: UTF-8

class ListingParenting

    # ---------------------------------------
    # Data

    # ListingParenting::itemToListingParenting(item)
    def self.itemToListingParenting(item)
        return [] if item["clique8"].nil?
        item["clique8"]
    end

    # ListingParenting::itemToNx38OrNull(item, listinguuid)
    def self.itemToNx38OrNull(item, listinguuid)
        ListingParenting::itemToListingParenting(item).select{|nx38| nx38["uuid"] == listinguuid }.first
    end

    # ListingParenting::suffix(item)
    def self.suffix(item)
        resolve = lambda {|uuid|
            item = Blades::itemOrNull(uuid)
            return nil if item.nil?
            item["description"]
        }
        return "" if item["clique8"].nil?
        " (p: #{item["clique8"].map{|nx38| resolve.call(nx38["uuid"]) }.compact.join(", ")})".yellow
    end

    # ---------------------------------------
    # Ops

    # ListingParenting::setMembership(item, nx38)
    def self.setMembership(item, nx38)
        nx38s = ListingParenting::itemToListingParenting(item)
        nx38s = nx38s.select{|x| x["uuid"] != nx38["uuid"] }
        nx38s = nx38s + [nx38]
        Blades::setAttribute(item["uuid"], "clique8", nx38s)
    end
end
