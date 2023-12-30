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
    "type"            : "item-attribute-update"
    "itemuuid"        : String
    "attribute-name"  : String
    "attribute-value" : Value
}

{
    "type"     : "item-destroy"
    "itemuuid" : String
}

{
    "type"     : "do-not-show-until"
    "id  "     : String
    "unixtime" : Integer
}

{
    "type"  : "bank-record"
    "id"    : String
    "date"  : Integer
    "value" : Float
}

=end

$DATA_CENTER_DATA = nil
$DATA_CENTER_UPDATE_QUEUE = []

class DataCenter

    # DataCenter::version()
    def self.version()
        "Mercury"
    end

    # DataCenter::getDataFromCacheOrNull()
    def self.getDataFromCacheOrNull()
        data = XCache::getOrNull("872b3c2e-8a04-4df0-999d-d1a1ae9e537a:#{DataCenter::version()}")
        return nil if data.nil?
        JSON.parse(data)
    end

    # DataCenter::rebuildDataFromScratch()
    def self.rebuildDataFromScratch()
        itemsmap = {}
        Find.find("#{Config::pathToCatalystDataRepository()}/Cubes") do |path|
            next if !path.include?(".catalyst-cube")
            next if File.basename(path).start_with?('.') # avoiding: .syncthing.82aafe48c87c22c703b32e35e614f4d7.catalyst-cube.tmp 
            item = Cubes::filepathToItem(path)
            itemsmap[item["uuid"]] = item
        end

        doNotShowUntil = {}
        DoNotShowUntil::filepaths()
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
        Bank::filepaths()
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

    # DataCenter::loadData()
    def self.loadData()
        if $DATA_CENTER_DATA then
            return $DATA_CENTER_DATA
        end
        data = DataCenter::getDataFromCacheOrNull()
        if data then
            $DATA_CENTER_DATA = data
            return data
        end
        data = DataCenter::rebuildDataFromScratch()
        XCache::set("872b3c2e-8a04-4df0-999d-d1a1ae9e537a:#{DataCenter::version()}", JSON.generate(data))
        $DATA_CENTER_DATA = data
        data
    end

    # DataCenter::waitUntilQueueIsEmpty()
    def self.waitUntilQueueIsEmpty()
        loop {
            break if $DATA_CENTER_UPDATE_QUEUE.empty?
            sleep 1
        }
    end
end

Thread.new {
    loop {
        update = $DATA_CENTER_UPDATE_QUEUE.shift
        if update.nil? then
            sleep 1
            next
        end
        #puts JSON.pretty_generate(update).yellow
        if update["type"] == "item-attribute-update" then
            uuid      = update["itemuuid"]
            attrname  = update["attribute-name"]
            attrvalue = update["attribute-value"]

            filepath = Cubes::existingFilepathOrNull(uuid)
            if filepath.nil? then
                raise "(error: b2a27beb-7b23-4077-af2f-ba408ed37748); uuid: #{uuid}, attrname: #{attrname}, attrvalue: #{attrvalue}"
            end
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "insert into _cube_ (_recorduuid_, _recordTime_, _recordType_, _name_, _value_) values (?, ?, ?, ?, ?)", [SecureRandom.hex(10), Time.new.to_f, "attribute", attrname, JSON.generate(attrvalue)]
            db.close

            Cubes::relocate(filepath)
        end
        if update["type"] == "item-destroy" then
            uuid = update["itemuuid"]

            filepath = Cubes::existingFilepathOrNull(uuid)
            next if filepath.nil?
            FileUtils.rm(filepath)
        end
        if update["type"] == "do-not-show-until" then
            id = update["id"]
            unixtime = update["unixtime"]

            filepath = DoNotShowUntil::instanceFilepath()
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "delete from DoNotShowUntil where _id_=?", [id]
            db.execute "insert into DoNotShowUntil (_id_, _unixtime_) values (?, ?)", [id, unixtime]
            db.close

            XCache::set("747a75ad-05e7-4209-a876-9fe8a86c40dd:#{id}", unixtime)
        end
        if update["type"] == "bank-record" then
            id = update["id"]
            date = update["date"]
            value = update["value"]

            filepath = Bank::instanceFilepath()
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "insert into Bank (_recorduuid_, _id_, _date_, _value_) values (?, ?, ?, ?)", [SecureRandom.uuid, id, date, value]
            db.close
        end
        XCache::set("872b3c2e-8a04-4df0-999d-d1a1ae9e537a:#{DataCenter::version()}", JSON.generate($DATA_CENTER_DATA))
    }
}

Thread.new {
    sleep 60
    loop {
        data = DataCenter::rebuildDataFromScratch()
        XCache::set("872b3c2e-8a04-4df0-999d-d1a1ae9e537a:#{DataCenter::version()}", JSON.generate(data))
        $DATA_CENTER_DATA = data
        sleep 1200
    }
}
