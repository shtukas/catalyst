
# encoding: UTF-8

class ListingParenting

    # ---------------------------------------
    # Data

    # ListingParenting::itemToNx38s(item)
    def self.itemToNx38s(item)
        return [] if item["clique8"].nil?
        item["clique8"]
    end

    # ListingParenting::itemMembershipClaimInlistingOrNull(item, listinguuid)
    def self.itemMembershipClaimInlistingOrNull(item, listinguuid)
        ListingParenting::itemToNx38s(item).select{|nx38| nx38["uuid"] == listinguuid }.first
    end

    # ListingParenting::itemPositionInListingOrZero(item, listinguuid)
    def self.itemPositionInListingOrZero(item, listinguuid)
        claim = ListingParenting::itemMembershipClaimInlistingOrNull(item, listinguuid)
        return 0 if claim.nil?
        claim["position"]
    end

    # ListingParenting::suffix(item)
    def self.suffix(item)
        resolve = lambda {|listinguuid|
            listing = Blades::itemOrNull(listinguuid)
            if listing.nil? then
                ListingParenting::removeMembership(item, listinguuid)
                return nil
            end
            listing["description"]
        }
        return "" if item["clique8"].nil?
        " (p: #{item["clique8"].map{|nx38| resolve.call(nx38["uuid"]) }.compact.join(", ")})".yellow
    end

    # ---------------------------------------
    # Ops

    # ListingParenting::setMembership(item, nx38)
    def self.setMembership(item, nx38)
        nx38s = ListingParenting::itemToNx38s(item)
        nx38s = nx38s.select{|x| x["uuid"] != nx38["uuid"] }
        nx38s = nx38s + [nx38]
        Blades::setAttribute(item["uuid"], "clique8", nx38s)
    end

    # ListingParenting::removeMembership(item, listinguuid)
    def self.removeMembership(item, listinguuid)
        nx38s = ListingParenting::itemToNx38s(item)
        nx38s = nx38s.select{|x| x["uuid"] != listinguuid }
        Blades::setAttribute(item["uuid"], "clique8", nx38s)
    end
end
