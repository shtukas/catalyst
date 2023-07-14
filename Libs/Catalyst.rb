

class Catalyst

    # Catalyst::catalystItems()
    def self.catalystItems()
        [
          "NxAnniversary",
          "NxBackup",
          "NxOndate",
          "NxCase",
          "PhysicalTarget",
          "Wave",
        ]
            .map{|mikuType|
                DarkEnergy::mikuType(mikuType)
            }
            .flatten
    end

    # Catalyst::fsckItem(item)
    def self.fsckItem(item)
        CoreData::fsck(item)
    end

    # Catalyst::fsck()
    def self.fsck()
        # We use a .to_a here because otherwise the error is not propagated up (Ruby weirdness)
        Catalyst::catalystItems().each{|item|
            Catalyst::fsckItem(item)
        }
    end

    # Catalyst::driversUpdate(drivers)
    def self.driversUpdate(drivers)
        drivers
    end

    # Catalyst::updateItemDriversWithDriver(item, driver)
    def self.updateItemDriversWithDriver(item, driver)
        if item["drivers"].nil? then
            item["drivers"] = []
        end
        item["drivers"] = item["drivers"].select{|d| d["mikuType"] != driver["mikuType"] }
        item["drivers"] << driver
        DarkEnergy::commit(item)
    end
end
