

class Catalyst

    # Catalyst::catalystItems()
    def self.catalystItems()
        [
            "NxAnniversary",
            "NxBackup",
            "NxBoard",
            "NxFire",
            "NxBurner",
            "NxLine",
            "NxLong",
            "NxOndate",
            "NxTask",
            "Wave"
        ]
            .map{|mikuType|
                Solingen::mikuTypeItems(mikuType)
            }
            .flatten
    end

    # Catalyst::fsckItem(item)
    def self.fsckItem(item)
        CoreData::fsck(item["uuid"], item["field11"])
    end

    # Catalyst::fsck()
    def self.fsck()
        # We use a .to_a here because otherwise the error is not propagated up (Ruby weirdness)
        Catalyst::catalystItems().each{|item|
            Catalyst::fsckItem(item)
        }
    end
end
