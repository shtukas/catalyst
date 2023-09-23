# encoding: UTF-8

$BankVault = {}

class Bank

    # ----------------------------------
    # Interface

    # Bank::getValueAtDate(uuid, date)
    def self.getValueAtDate(uuid, date)
        dataset = EventTimelineDatasets::banking() # Map[uuid:string, Map[date:"YYYY-MM-DD", value:float]]
        return 0 if dataset[uuid].nil?
        return 0 if dataset[uuid][date].nil?
        dataset[uuid][date]
    end

    # Bank::getValue(uuid)
    def self.getValue(uuid)
        dataset = EventTimelineDatasets::banking() # Map[uuid:string, Map[date:"YYYY-MM-DD", value:float]]
        return 0 if dataset[uuid].nil?
        dataset[uuid].values.inject(0, :+)
    end

    # Bank::put(uuid, value)
    def self.put(uuid, value)
        Events::publishBankDeposit(uuid, CommonUtils::today(), value)
    end

    # ----------------------------------

    # Bank::averageHoursPerDayOverThePastNDays(uuid, n)
    # n = 0 corresponds to today
    def self.averageHoursPerDayOverThePastNDays(uuid, n)
        range = (0..n)
        totalInSeconds = range.map{|indx| Bank::getValueAtDate(uuid, CommonUtils::nDaysInTheFuture(-indx)) }.inject(0, :+)
        totalInHours = totalInSeconds.to_f/3600
        average = totalInHours.to_f/(n+1)
        average
    end

    # Bank::recoveredAverageHoursPerDay(uuid)
    def self.recoveredAverageHoursPerDay(uuid)
        (0..6).map{|n| Bank::averageHoursPerDayOverThePastNDays(uuid, n) }.max
    end

    # Bank::recoveredAverageHoursPerDayCached(uuid)
    def self.recoveredAverageHoursPerDayCached(uuid)
        trace = EventTimelineReader::liveTraceForCaching()
        rt = InMemoryCache::getOrNull("6e88325f-c710-4285-b720-dfb14df0def8:#{trace}")
        if rt then
            return rt
        end

        rt = Bank::recoveredAverageHoursPerDay(uuid)

        InMemoryCache::set("6e88325f-c710-4285-b720-dfb14df0def8:#{trace}", rt)
        rt
    end
end
