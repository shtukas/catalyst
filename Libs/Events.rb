
class Events

    # Events::makeDoNotShowUntil(item, unixtime)
    def self.makeDoNotShowUntil(item, unixtime)
        {
            "uuid"      => SecureRandom.uuid,
            "eventType" => "DoNotShowUntil",
            "targetId"  => item["uuid"],
            "unixtime"  => unixtime
        }
    end

    # Events::publishDoNotShowUntil(item, unixtime)
    def self.publishDoNotShowUntil(item, unixtime)
        EventPublisher::publish(Events::makeDoNotShowUntil(item, unixtime))
    end

    # Events::makeItemAttributeUpdate(itemuuid, attname, attvalue)
    def self.makeItemAttributeUpdate(itemuuid, attname, attvalue)
        {
            "uuid"      => SecureRandom.uuid,
            "eventType" => "ItemAttributeUpdate",
            "payload" => {
                "itemuuid" => itemuuid,
                "attname"  => attname,
                "attvalue" => attvalue
            }
        }
    end

    # Events::publishItemAttributeUpdate(itemuuid, attname, attvalue)
    def self.publishItemAttributeUpdate(itemuuid, attname, attvalue)
        EventPublisher::publish(Events::makeItemAttributeUpdate(itemuuid, attname, attvalue))
    end
end
