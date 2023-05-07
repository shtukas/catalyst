

class Catalyst

    # Catalyst::catalystItems()
    def self.catalystItems()
        Solingen::mikuTypeItems("Wave")
    end

    # Catalyst::fsckItem(item)
    def self.fsckItem(item)
        CoreData::fsck(item["uuid"], item["field11"])
    end

    # Catalyst::fsck()
    def self.fsck()
        # We use a .to_a here because otherwise the error is not propagated up (Ruby weirdness)
        BladeAdaptation::getAllCatalystItemsEnumerator().to_a.each{|item|
            Catalyst::fsckItem(item)
        }
    end
end
