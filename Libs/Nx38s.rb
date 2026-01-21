
# encoding: UTF-8

class Nx38s

    # ---------------------------------------
    # Data

    # Nx38s::itemToNx38s(item)
    def self.itemToNx38s(item)
        return [] if item["clique8"].nil?
        item["clique8"]
    end

    # Nx38s::itemToNx38OrNull(item, listinguuid)
    def self.itemToNx38OrNull(item, listinguuid)
        Nx38s::itemToNx38s(item).select{|nx38| nx38["uuid"] == listinguuid }.first
    end

    # ---------------------------------------
    # Ops

    # Nx38s::setMembership(item, nx38)
    def self.setMembership(item, nx38)
        nx38s = Nx38s::itemToNx38s(item)
        nx38s = nx38s.select{|x| x["uuid"] != nx38["uuid"] }
        nx38s = nx38s + [nx38]
        Blades::setAttribute(item["uuid"], "clique8", nx38s)
    end
end
