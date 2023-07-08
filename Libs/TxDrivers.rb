
class TxDrivers

    # TxDrivers::shouldShow1(driver)
    def self.shouldShow1(driver)
        if driver["mikuType"] == "TxDailyEngine" then
            return TxDailyEngines::shouldShow(driver)
        end
        if driver["mikuType"] == "TxWeeklyEngine" then
            return TxWeeklyEngines::shouldShow(driver)
        end
        if driver["mikuType"] == "TxDeadline" then
            return true
        end
        raise "unsupported driver: #{driver}"
    end

    # TxDrivers::shouldShow2(item)
    def self.shouldShow2(item)
        return true if item["drivers"].nil?
        item["drivers"].any?{|driver| TxDrivers::shouldShow1(driver) }
    end

    # TxDrivers::toString1(driver)
    def self.toString1(driver)
        if driver["mikuType"] == "TxDailyEngine" then
            return TxDailyEngines::toString(driver)
        end
        if driver["mikuType"] == "TxWeeklyEngine" then
            return TxWeeklyEngines::toString(driver)
        end
        if driver["mikuType"] == "TxDeadline" then
            return TxDeadline::toString(driver)
        end
    end

    # TxDrivers::toString2(drivers)
    def self.toString2(drivers)
        return "" if drivers.nil?
        return "" if drivers.empty?
        drivers.map{|driver| TxDrivers::toString1(driver) }.join(" ")
    end

    # TxDrivers::suffix(item)
    def self.suffix(item)
        " #{TxDrivers::toString2(item["drivers"])}"
    end
end
