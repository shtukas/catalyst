
class Updates

    # Updates::doNotShowUntil(itemuuid, unixtime)
    def self.doNotShowUntil(itemuuid, unixtime)
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

    # Updates::itemAttributeUpdate(itemuuid, attname, attvalue)
    def self.itemAttributeUpdate(itemuuid, attname, attvalue)

        Cubes::setAttribute(itemuuid, attname, attvalue)

        item = Catalyst::itemOrNull(itemuuid)
        if item.nil? then
            raise "(error 1219) Updates::itemAttributeUpdate(#{itemuuid}, #{attname}, #{attvalue})"
        end
        item[attname] = attvalue
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/Items.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from Items where _uuid_=?", [itemuuid]
        db.execute "insert into Items (_uuid_, _mikuType_, _item_) values (?, ?, ?)", [item["uuid"], item["mikuType"], JSON.generate(item)]
        db.close

        $ItemsOperator.itemAttributeUpdate(itemuuid, attname, attvalue)

        Broadcasts::publish(Broadcasts::makeItemAttributeUpdate(itemuuid, attname, attvalue))
    end

    # Updates::itemDestroy(itemuuid)
    def self.itemDestroy(itemuuid)
        Cubes::destroy(itemuuid)

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

    # Updates::itemInit(uuid, mikuType)
    def self.itemInit(uuid, mikuType)
        Cubes::createFile(uuid)

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

    # Updates::bankDeposit(uuid, date, value)
    def self.bankDeposit(uuid, date, value)
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