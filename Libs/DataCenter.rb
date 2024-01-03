# encoding: UTF-8

=begin

------------------------------------------------------

We maintain the entire state of all item and banking and do not show until in a single structure

NxDataRoot {
    "items"          : Map[uuid, CatalystItem]
    "doNotShowUntil" : NxDaTaDoNotShowUntil
    "bank"           : Array[NxDataBankRecord]
}

NxDataDoNotShowUntil: Map[uuid, unixtime]

NxDataBankRecord {
    "id"    : String
    "date"  : Integer
    "value" : Float
}

-------------------------------------------------------

We emit updates that are kept in memory and written to disk asynchronously.

{
    "type"     : "item-init"
    "uuid"     : String
    "mikuType" : Value
}

{
    "type"            : "item-attribute-update"
    "iuuid"           : String
    "attribute-name"  : String
    "attribute-value" : Value
}

{
    "type" : "item-destroy"
    "uuid" : String
}

{
    "type"     : "do-not-show-until"
    "id  "     : String
    "unixtime" : Integer
}

{
    "type"  : "bank-put"
    "id"    : String
    "date"  : Integer
    "value" : Float
}

=end

$DATA_CENTER_DATA = nil
$DATA_CENTER_UPDATE_QUEUE = []

class CoreData

    # CoreData::version()
    def self.version()
        "Mercury"
    end

    # CoreData::getDataFromCacheOrNull()
    def self.getDataFromCacheOrNull()
        data = XCache::getOrNull("872b3c2e-8a04-4df0-999d-d1a1ae9e537a:#{CoreData::version()}")
        return nil if data.nil?
        JSON.parse(data)
    end

    # CoreData::rebuildDataFromScratch()
    def self.rebuildDataFromScratch()
        itemsmap = {}
        Find.find("#{Config::pathToCatalystDataRepository()}/Cubes") do |path|
            next if !path.include?(".catalyst-cube")
            next if File.basename(path).start_with?('.') # avoiding: .syncthing.82aafe48c87c22c703b32e35e614f4d7.catalyst-cube.tmp 
            item = Cubes1::filepathToItem(path)
            itemsmap[item["uuid"]] = item
        end

        doNotShowUntil = {}
        DoNotShowUntil1::filepaths()
            .map{|filepath|
                unixtime = 0
                db = SQLite3::Database.new(filepath)
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute("select * from DoNotShowUntil", []) do |row|
                    doNotShowUntil[row["_id_"]] =  [(doNotShowUntil[row["_id_"]] || 0), row["_unixtime_"]].max
                end
                db.close
            }

        bank = []
        Bank1::filepaths()
            .map{|filepath|
                value = 0
                db = SQLite3::Database.new(filepath)
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute("select * from Bank", []) do |row|
                    bank << {
                        "id"    => row["_id_"],
                        "date"  => row["_date_"],
                        "value" => row["_value_"],
                    }
                end
                db.close
            }

        {
            "items"          => itemsmap,
            "doNotShowUntil" => doNotShowUntil,
            "bank"           => bank
        }
    end

    # CoreData::getData()
    def self.getData()
        if $DATA_CENTER_DATA then
            return $DATA_CENTER_DATA
        end
        data = CoreData::getDataFromCacheOrNull()
        if data then
            $DATA_CENTER_DATA = data
            return data
        end
        data = CoreData::rebuildDataFromScratch()
        XCache::set("872b3c2e-8a04-4df0-999d-d1a1ae9e537a:#{CoreData::version()}", JSON.generate(data))
        $DATA_CENTER_DATA = data
        data
    end

    # CoreData::reloadDataFromScratch()
    def self.reloadDataFromScratch()
        data = CoreData::rebuildDataFromScratch()
        XCache::set("872b3c2e-8a04-4df0-999d-d1a1ae9e537a:#{CoreData::version()}", JSON.generate(data))
        $DATA_CENTER_DATA = data
    end

    # CoreData::waitUntilQueueIsEmpty()
    def self.waitUntilQueueIsEmpty()
        loop {
            break if $DATA_CENTER_UPDATE_QUEUE.empty?
            sleep 1
        }
    end
end

class Cubes2

    # Cubes2::itemInit(uuid, mikuType)
    def self.itemInit(uuid, mikuType)
        $DATA_CENTER_DATA["items"][uuid] = {
            "uuid"     => uuid,
            "mikuType" => mikuType
        }
        $DATA_CENTER_UPDATE_QUEUE << {
            "type"     => "item-init",
            "uuid"     => uuid,
            "mikuType" => mikuType
        }
        DataProcessor::processQueue()
    end

    # Cubes2::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        $DATA_CENTER_DATA["items"][uuid]
    end

    # Cubes2::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        if $DATA_CENTER_DATA["items"][uuid].nil? then
            raise "(error: 417a064c-d89b-4d20-ac96-529db96d2c23); uuid: #{uuid}, attrname: #{attrname}, attrvalue: #{attrvalue}"
        end
        $DATA_CENTER_DATA["items"][uuid][attrname] = attrvalue
        $DATA_CENTER_UPDATE_QUEUE << {
            "type"            => "item-attribute-update",
            "iuuid"           => uuid,
            "attribute-name"  => attrname,
            "attribute-value" => attrvalue
        }
        DataProcessor::processQueue()
        nil
    end

    # Cubes2::destroy(uuid)
    def self.destroy(uuid)
        $DATA_CENTER_DATA["items"].delete(uuid)
        $DATA_CENTER_UPDATE_QUEUE << {
            "type" => "item-destroy",
            "uuid" => uuid,
        }
        DataProcessor::processQueue()
    end

    # Cubes2::items()
    def self.items()
        $DATA_CENTER_DATA["items"].values
    end

   # Cubes2::mikuType(mikuType)
    def self.mikuType(mikuType)
        $DATA_CENTER_DATA["items"].values.select{|item| item["mikuType"] == mikuType }
    end
end

class DoNotShowUntil2

    # DoNotShowUntil2::getUnixtimeOrNull(id)
    def self.getUnixtimeOrNull(id)
        $DATA_CENTER_DATA["doNotShowUntil"][id]
    end

    # DoNotShowUntil2::setUnixtime(id, unixtime)
    def self.setUnixtime(id, unixtime)
        item = $DATA_CENTER_DATA["items"][id] # new

        if item then
            Ox1::detach(item)
        end

        $DATA_CENTER_DATA["doNotShowUntil"][id] = unixtime
        $DATA_CENTER_UPDATE_QUEUE << {
            "type"     => "do-not-show-until",
            "id"       => id,
            "unixtime" => unixtime
        }
        DataProcessor::processQueue()
    end

    # DoNotShowUntil2::isVisible(item)
    def self.isVisible(item)
        Time.new.to_i >= (DoNotShowUntil2::getUnixtimeOrNull(item["uuid"]) || 0)
    end

    # DoNotShowUntil2::suffixString(item)
    def self.suffixString(item)
        unixtime = (DoNotShowUntil2::getUnixtimeOrNull(item["uuid"]) || 0)
        return "" if unixtime.nil?
        return "" if Time.new.to_i > unixtime
        " (not shown until: #{Time.at(unixtime).to_s})"
    end
end

class Bank2

    # Bank2::put(uuid, value)
    def self.put(uuid, value)
        $DATA_CENTER_DATA["bank"] << {
            "id"    => uuid,
            "date"  => CommonUtils::today(),
            "value" => value
        }
        $DATA_CENTER_UPDATE_QUEUE << {
            "type"  => "bank-put",
            "id"    => uuid,
            "date"  => CommonUtils::today(),
            "value" => value
        }
        DataProcessor::processQueue()
    end

    # Bank2::getValueAtDate(uuid, date)
    def self.getValueAtDate(uuid, date)
        $DATA_CENTER_DATA["bank"]
            .select{|record| record["id"] == uuid }
            .select{|record| record["date"] == date }
            .map{|record| record["value"] }
            .inject(0, :+)
    end

    # Bank2::getValue(uuid)
    def self.getValue(uuid)
        $DATA_CENTER_DATA["bank"]
            .select{|record| record["id"] == uuid }
            .map{|record| record["value"] }
            .inject(0, :+)
    end

    # Bank2::averageHoursPerDayOverThePastNDays(uuid, n)
    def self.averageHoursPerDayOverThePastNDays(uuid, n)
        range = (0..n)
        totalInSeconds = range.map{|indx| Bank2::getValueAtDate(uuid, CommonUtils::nDaysInTheFuture(-indx)) }.inject(0, :+)
        totalInHours = totalInSeconds.to_f/3600
        average = totalInHours.to_f/(n+1)
        average
    end

    # Bank2::recoveredAverageHoursPerDay(uuid)
    def self.recoveredAverageHoursPerDay(uuid)
        (0..6).map{|n| Bank2::averageHoursPerDayOverThePastNDays(uuid, n) }.max
    end
end

class DataProcessor

    # DataProcessor::processUpdate(update)
    def self.processUpdate(update)
        puts JSON.pretty_generate(update).yellow
        if update["type"] == "item-init" then
            uuid      = update["uuid"]
            mikuType  = update["mikuType"]
            Cubes1::itemInit(uuid, mikuType)
        end
        if update["type"] == "item-attribute-update" then
            uuid      = update["iuuid"]
            attrname  = update["attribute-name"]
            attrvalue = update["attribute-value"]
            Cubes1::setAttribute(uuid, attrname, attrvalue)
        end
        if update["type"] == "item-destroy" then
            uuid = update["uuid"]
            Cubes1::destroy(uuid)
        end
        if update["type"] == "do-not-show-until" then
            id = update["id"]
            unixtime = update["unixtime"]
            DoNotShowUntil1::setUnixtime(id, unixtime)
        end
        if update["type"] == "bank-put" then
            id = update["id"]
            date = update["date"]
            value = update["value"]
            Bank1::put(id, date, value)
        end
    end

    # DataProcessor::processQueue()
    def self.processQueue()
        while update = $DATA_CENTER_UPDATE_QUEUE.shift do
            DataProcessor::processUpdate(update)
        end
        XCache::set("872b3c2e-8a04-4df0-999d-d1a1ae9e537a:#{CoreData::version()}", JSON.generate($DATA_CENTER_DATA))
    end
end

#Thread.new {
#    loop {
#        DataProcessor::processQueue()
#        sleep 1
#    }
#}

Thread.new {
    sleep 60
    loop {
        CoreData::reloadDataFromScratch()
        sleep 1200
    }
}
