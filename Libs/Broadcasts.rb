
class Broadcasts

    # Makers

    # Broadcasts::makeDoNotShowUntil(itemuuid, unixtime)
    def self.makeDoNotShowUntil(itemuuid, unixtime)
        {
            "uuid"      => SecureRandom.uuid,
            "unixtime"  => Time.new.to_i,
            "eventType" => "DoNotShowUntil2",
            "payload"   => {
                "targetId"  => itemuuid,
                "unixtime"  => unixtime
            }
        }
    end

    # Broadcasts::makeItemAttributeUpdate(itemuuid, attname, attvalue)
    def self.makeItemAttributeUpdate(itemuuid, attname, attvalue)
        {
            "uuid"      => SecureRandom.uuid,
            "unixtime"  => Time.new.to_i,
            "eventType" => "ItemAttributeUpdate",
            "payload" => {
                "itemuuid" => itemuuid,
                "attname"  => attname,
                "attvalue" => attvalue
            }
        }
    end

    # Broadcasts::makeItemDestroy(itemuuid)
    def self.makeItemDestroy(itemuuid)
        {
            "uuid"      => SecureRandom.uuid,
            "unixtime"  => Time.new.to_i,
            "eventType" => "ItemDestroy2",
            "payload" => {
                "uuid" => itemuuid,
            }
        }
    end

    # Broadcasts::makeItemInit(uuid, mikuType)
    def self.makeItemInit(uuid, mikuType)
        {
            "uuid"      => SecureRandom.uuid,
            "unixtime"  => Time.new.to_i,
            "eventType" => "ItemInit",
            "payload" => {
                "uuid"     => uuid,
                "mikuType" => mikuType
            }
        }
    end

    # Broadcasts::makeBankDeposit(uuid, date, value)
    def self.makeBankDeposit(uuid, date, value)
        {
            "uuid"      => SecureRandom.uuid,
            "unixtime"  => Time.new.to_i,
            "eventType" => "BankDeposit",
            "payload" => {
                "uuid"  => uuid,
                "date"  => date,
                "value" => value
            }
        }
    end

    # Publishers

    # Broadcasts::publish(event)
    def self.publish(event)
        Config::instanceIds().each{|instanceId|
            next if instanceId == Config::thisInstanceId()
            fragment1 = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{instanceId}/events-timeline"
            fragment2 = "#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y-%m")}/#{Time.new.strftime("%Y-%m-%d")}"
            folder1 = "#{fragment1}/#{fragment2}"
            if !File.exist?(folder1) then
                FileUtils.mkpath(folder1)
            end
            folder2 = LucilleCore::indexsubfolderpath(folder1, 100)
            filepath1 = "#{folder2}/#{CommonUtils::timeStringL22()}.json"
            File.open(filepath1, "w"){|f| f.puts(JSON.pretty_generate(event)) }
        }
    end

    # Broadcasts::publishDoNotShowUntil(itemuuid, unixtime)
    def self.publishDoNotShowUntil(itemuuid, unixtime)
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/DoNotShowUntil.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from DoNotShowUntil where _id_=?", [itemuuid]
        db.execute "insert into DoNotShowUntil (_id_, _unixtime_) values (?, ?)", [itemuuid, unixtime]
        db.close

        $DoNotShowUntilOperator.set(itemuuid, unixtime)

        Broadcasts::publish(Broadcasts::makeDoNotShowUntil(itemuuid, unixtime))
    end

    # Broadcasts::publishItemAttributeUpdate(itemuuid, attname, attvalue)
    def self.publishItemAttributeUpdate(itemuuid, attname, attvalue)
        item = Catalyst::itemOrNull(itemuuid)
        if item then
            item[attname] = attvalue
            filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/Items.sqlite3"
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "delete from Items where _uuid_=?", [itemuuid]
            db.execute "insert into Items (_uuid_, _mikuType_, _item_) values (?, ?, ?)", [item["uuid"], item["mikuType"], JSON.generate(item)]
            db.close
        end

        $ItemsOperator.itemAttributeUpdate(itemuuid, attname, attvalue)

        Broadcasts::publish(Broadcasts::makeItemAttributeUpdate(itemuuid, attname, attvalue))
    end

    # Broadcasts::publishItemDestroy(itemuuid)
    def self.publishItemDestroy(itemuuid)
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/Items.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from Items where _uuid_=?", [itemuuid]
        db.close

        $ItemsOperator.destroy(itemuuid)

        Broadcasts::publish(Broadcasts::makeItemDestroy(itemuuid))
    end

    # Broadcasts::publishItemInit(uuid, mikuType)
    def self.publishItemInit(uuid, mikuType)
        item = {
            "uuid"     => uuid,
            "mikuType" => mikuType
        }

        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/Items.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into Items (_uuid_, _mikuType_, _item_) values (?, ?, ?)", [item["uuid"], item["mikuType"], JSON.generate(item)]
        db.close

        $ItemsOperator.init(uuid, mikuType)

        Broadcasts::publish(Broadcasts::makeItemInit(uuid, mikuType))
    end

    # Broadcasts::publishBankDeposit(uuid, date, value)
    def self.publishBankDeposit(uuid, date, value)
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/Bank.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into Bank (_recorduuid_, _id_, _date_, _value_) values (?, ?, ?, ?)", [SecureRandom.uuid, uuid, date, value]
        db.close

        $BankOperator.deposit(uuid, date, value)

        Broadcasts::publish(Broadcasts::makeBankDeposit(uuid, date, value))
    end
end