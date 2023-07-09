

class Catalyst

    # Catalyst::catalystItems()
    def self.catalystItems()
        [
          "NxAnniversary",
          "NxBackup",
          "NxOndate",
          "NxTask",
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

    # Catalyst::interactivelyMakeDriverOrNull()
    def self.interactivelyMakeDriverOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["TxWeeklyEngine",  "TxDailyEngine", "TxDeadline"])
        return nil if type.nil?
        if type == "TxWeeklyEngine" then
            return TxWeeklyEngines::interactivelyMakeOrNull()
        end
        if type == "TxDailyEngine" then
            return TxDailyEngines::interactivelyMakeOrNull()
        end
        if type == "TxDeadline" then
            return TxDeadline::interactivelyMakeOrNull()
        end
    end

    # Catalyst::interactivelyMakeDrivers()
    def self.interactivelyMakeDrivers()
        drivers = []
        loop {
            driver = Catalyst::interactivelyMakeDriverOrNull()
            return drivers if driver.nil?
            drivers << driver
        }
    end

end
