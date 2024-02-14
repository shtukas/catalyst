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

    # CoreData::getDataFromCacheOrNull()
    def self.getDataFromCacheOrNull()
        data = XCache::getOrNull("872b3c2e-8a04-4df0-999d-d1a1ae9e537b")
        return nil if data.nil?
        data = JSON.parse(data)
        return nil if data["unixtime"].nil?
        return nil if (Time.new.to_i - data["unixtime"]) > 3600
        data
    end

    # CoreData::rebuildDataFromScratch()
    def self.rebuildDataFromScratch()
        itemsmap = {}
        Find.find(Cubes1::pathToCubes()) do |path|
            next if !path.include?(".catalyst-cube")
            next if File.basename(path).start_with?('.') # avoiding: .syncthing.82aafe48c87c22c703b32e35e614f4d7.catalyst-cube.tmp 
            next if !File.exist?(path) # propection against a file renaming during this operation
            item = Cubes1::filepathToItem(path)
            itemsmap[item["uuid"]] = item
        end

        doNotShowUntil = {}
        DoNotShowUntil1::record_filepaths().each{|filepath|
            record = JSON.parse(IO.read(filepath))
            doNotShowUntil[record["id"]] =  [(doNotShowUntil[record["id"]] || 0), record["unixtime"]].max
        }

        bank = []
        Bank1::record_filepaths().each{|filepath|
            record = JSON.parse(IO.read(filepath))
            bank << record # The stored records have exactly the shape of data center bank items
        }

        {
            "unixtime"       => Time.new.to_i, # time of generation
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
        XCache::set("872b3c2e-8a04-4df0-999d-d1a1ae9e537b", JSON.generate(data))
        $DATA_CENTER_DATA = data
        data
    end

    # CoreData::reloadDataFromScratch()
    def self.reloadDataFromScratch()
        data = CoreData::rebuildDataFromScratch()
        XCache::set("872b3c2e-8a04-4df0-999d-d1a1ae9e537b", JSON.generate(data))
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
        XCache::set("872b3c2e-8a04-4df0-999d-d1a1ae9e537b", JSON.generate($DATA_CENTER_DATA))
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
