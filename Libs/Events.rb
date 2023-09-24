
class Events

    # Makers

    # Events::makeDoNotShowUntil(itemuuid, unixtime)
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

    # Events::makeItemAttributeUpdate(itemuuid, attname, attvalue)
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

    # Events::makeItemDestroy(itemuuid)
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

    # Events::makeItemInit(mikuType, uuid)
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

    # Events::makeBankDeposit(uuid, date, value)
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

    # Events::publish(event)
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

    # Events::publishDoNotShowUntil(itemuuid, unixtime)
    def self.publishDoNotShowUntil(itemuuid, unixtime)
        Events::publish(Events::makeDoNotShowUntil(itemuuid, unixtime))
    end

    # Events::publishItemAttributeUpdate(itemuuid, attname, attvalue)
    def self.publishItemAttributeUpdate(itemuuid, attname, attvalue)
        Events::publish(Events::makeItemAttributeUpdate(itemuuid, attname, attvalue))
    end

    # Events::publishItemDestroy(itemuuid)
    def self.publishItemDestroy(itemuuid)
        Events::publish(Events::makeItemDestroy(itemuuid))
    end

    # Events::publishItemInit(uuid, mikuType)
    def self.publishItemInit(uuid, mikuType)
        Events::publish(Events::makeItemInit(uuid, mikuType))
    end

    # Events::publishBankDeposit(uuid, date, value)
    def self.publishBankDeposit(uuid, date, value)
        Events::publish(Events::makeBankDeposit(uuid, date, value))
    end
end
