# encoding: UTF-8

# sqlite3 rt-cache.sqlite3
# sqlite> create table rt (uuid text non null primary key, value real non null, valid_on text non null);

class BankData

    # BankData::averageHoursPerDayOverThePastNDays(uuid, n)
    # n = 0 corresponds to today
    def self.averageHoursPerDayOverThePastNDays(uuid, n)
        range = (0..n)
        totalInSeconds = range.map{|indx| BankVault::getValueAtDate(uuid, CommonUtils::nDaysInTheFuture(-indx)) }.inject(0, :+)
        totalInHours = totalInSeconds.to_f/3600
        average = totalInHours.to_f/(n+1)
        average
    end

    # BankData::insertValueInCache(uuid, value)
    def self.insertValueInCache(uuid, value)
        db = SQLite3::Database.new('/Users/pascal_honore/Galaxy/DataHub/Catalyst/data/banking/rt-cache.sqlite3')
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("delete from rt where uuid=?", [uuid])
        db.execute("insert into rt (uuid, value, valid_on) values (?, ?, ?)", [uuid, value, CommonUtils::today()])
        db.close
    end

    # BankData::recoveredAverageHoursPerDayFromCacheOrNull(uuid)
    def self.recoveredAverageHoursPerDayFromCacheOrNull(uuid)
        value = nil
        db = SQLite3::Database.new('/Users/pascal_honore/Galaxy/DataHub/Catalyst/data/banking/rt-cache.sqlite3')
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from rt where uuid=? and valid_on=?", [uuid, CommonUtils::today()]) do |row|
            value = row["value"]
        end
        db.close
        value
    end

    # BankData::decacheValue(uuid)
    def self.decacheValue(uuid)
        db = SQLite3::Database.new('/Users/pascal_honore/Galaxy/DataHub/Catalyst/data/banking/rt-cache.sqlite3')
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("delete from rt where uuid=?", [uuid])
        db.close
    end

    # BankData::recoveredAverageHoursPerDay(uuid)
    def self.recoveredAverageHoursPerDay(uuid)
        value = BankData::recoveredAverageHoursPerDayFromCacheOrNull(uuid)
        return value if value
        puts "BankData::recoveredAverageHoursPerDay: computing uuid #{uuid} from zero".yellow
        value = (0..6).map{|n| BankData::averageHoursPerDayOverThePastNDays(uuid, n) }.max
        BankData::insertValueInCache(uuid, value)
        value
    end
end
