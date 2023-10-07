
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

    # Broadcasts::makeItemInit(mikuType, uuid)
    def self.makeItemInit(mikuType, uuid)
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
        #puts "event: #{JSON.generate(event)}".yellow
        timefragment = "#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y-%m")}/#{Time.new.strftime("%Y-%m-%d")}"
        folderpath0 = "#{EventTimelineReader::eventsTimelineLocation()}/#{timefragment}"
        if !File.exist?(folderpath0) then
            FileUtils.mkpath(folderpath0)
        end
        folder1 = LucilleCore::indexsubfolderpath(folderpath0, 100)
        filepath1 = "#{folder1}/#{CommonUtils::timeStringL22()}.json"
        File.open(filepath1, "w"){|f| f.puts(JSON.pretty_generate(event)) }
        EventTimelineReader::issueNewRandomTraceForCaching()
    end

    # Broadcasts::publishDoNotShowUntil(itemuuid, unixtime)
    def self.publishDoNotShowUntil(itemuuid, unixtime)
        Broadcasts::publish(Broadcasts::makeDoNotShowUntil(itemuuid, unixtime))

        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/Lucille23/databases/DoNotShowUntil.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from DoNotShowUntil where _id_=?", [itemuuid]
        db.execute "insert into DoNotShowUntil (_id_, _unixtime_) values (?, ?)", [itemuuid, unixtime]
        db.close
    end

    # Broadcasts::publishItemAttributeUpdate(itemuuid, attname, attvalue)
    def self.publishItemAttributeUpdate(itemuuid, attname, attvalue)
        Broadcasts::publish(Broadcasts::makeItemAttributeUpdate(itemuuid, attname, attvalue))
    end

    # Broadcasts::publishItemDestroy(itemuuid)
    def self.publishItemDestroy(itemuuid)
        Broadcasts::publish(Broadcasts::makeItemDestroy(itemuuid))
    end

    # Broadcasts::publishItemInit(uuid, mikuType)
    def self.publishItemInit(uuid, mikuType)
        Broadcasts::publish(Broadcasts::makeItemInit(uuid, mikuType))
    end

    # Broadcasts::publishBankDeposit(uuid, date, value)
    def self.publishBankDeposit(uuid, date, value)
        Broadcasts::publish(Broadcasts::makeBankDeposit(uuid, date, value))
    end
end
