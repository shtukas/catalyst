
class Broadcasts

    # Events Makers

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

    # Broadcasts::makeItem(item)
    def self.makeItem(item)
        {
            "uuid"      => SecureRandom.uuid,
            "unixtime"  => Time.new.to_i,
            "eventType" => "Item",
            "payload"   => item
        }
    end

    # Publisher

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
            filepath1 = "#{folder2}/#{CommonUtils::timeStringL22()}-#{Config::thisInstanceId()}.json"
            File.open(filepath1, "w"){|f| f.puts(JSON.pretty_generate(event)) }
        }
    end

    # Utils

    # Broadcasts::publishItem(uuid)
    def self.publishItem(uuid)
        item = Catalyst::itemOrNull(uuid)
        return if item.nil?
        Broadcasts::publish(Broadcasts::makeItem(item))
    end
end