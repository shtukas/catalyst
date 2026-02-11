
# encoding: UTF-8

class ListingMembership

    # ---------------------------------------
    # Data

    # ListingMembership::itemToNx38s(item)
    def self.itemToNx38s(item)
        return [] if item["clique8"].nil?
        item["clique8"]
    end

    # ListingMembership::itemMembershipClaimInlistingOrNull(item, listinguuid)
    def self.itemMembershipClaimInlistingOrNull(item, listinguuid)
        ListingMembership::itemToNx38s(item).select{|nx38| nx38["uuid"] == listinguuid }.first
    end

    # ListingMembership::itemPositionInListingOrZero(item, listinguuid)
    def self.itemPositionInListingOrZero(item, listinguuid)
        claim = ListingMembership::itemMembershipClaimInlistingOrNull(item, listinguuid)
        return 0 if claim.nil?
        claim["position"]
    end

    # ListingMembership::suffix(item)
    def self.suffix(item)
        resolve = lambda {|listinguuid|
            listing = Blades::itemOrNull(listinguuid)
            if listing.nil? then
                ListingMembership::removeMembership(item, listinguuid)
                return nil
            end
            listing["description"]
        }
        return "" if item["clique8"].nil?
        " (p: #{item["clique8"].map{|nx38| resolve.call(nx38["uuid"]) }.compact.join(", ")})".yellow
    end

    # ---------------------------------------
    # Ops

    # ListingMembership::setMembership(item, nx38)
    def self.setMembership(item, nx38)
        nx38s = ListingMembership::itemToNx38s(item)
        nx38s = nx38s.select{|x| x["uuid"] != nx38["uuid"] }
        nx38s = nx38s + [nx38]
        Blades::setAttribute(item["uuid"], "clique8", nx38s)
    end

    # ListingMembership::removeMembership(item, listinguuid)
    def self.removeMembership(item, listinguuid)
        nx38s = ListingMembership::itemToNx38s(item)
        nx38s = nx38s.select{|x| x["uuid"] != listinguuid }
        Blades::setAttribute(item["uuid"], "clique8", nx38s)
    end
end
