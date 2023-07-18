# encoding: UTF-8

class NxPromises

    # ---------------------------------------------------
    # Makers

    # NxPromises::issueNew(description, datetimeStart, datetimeEnd, loadInHours)
    def self.issueNew(description, datetimeStart, datetimeEnd, loadInHours)
        uuid = SecureRandom.uuid
        Blades::init("NxPromise", uuid)
        Blades::setAttribute2(uuid, "description", description)
        Blades::setAttribute2(uuid, "datetimeStart", datetimeStart)
        Blades::setAttribute2(uuid, "datetimeEnd", datetimeEnd)
        Blades::setAttribute2(uuid, "loadInHours", loadInHours)
    end

    # NxPromises::interactivelyNewOrNull()
    def self.interactivelyNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        datetimeStart = Time.new.utc.iso8601
        puts "datetime start: #{datetimeStart}"
        puts "datetime end  :"
        datetimeEnd = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
        loadInHours = LucilleCore::askQuestionAnswerAsString("load in hours: ").to_f
        NxPromises::issueNew(description, datetimeStart, datetimeEnd, loadInHours)
    end

    # ---------------------------------------------------
    # Data

    # NxPromises::items()
    def self.items()
        Solingen::mikuTypeUUIDs("NxPromise")
            .map{|uuid|
                description   = Blades::getAttributeOrNull2(uuid, "description")
                datetimeStart = Blades::getAttributeOrNull2(uuid, "datetimeStart")
                datetimeEnd   = Blades::getAttributeOrNull2(uuid, "datetimeEnd")
                loadInHours   = Blades::getAttributeOrNull2(uuid, "loadInHours")
                {
                    "uuid"          => uuid,
                    "mikuType"      => "NxPromise",
                    "description"   => description,
                    "datetimeStart" => datetimeStart,
                    "datetimeEnd"   => datetimeEnd,
                    "loadInHours"   => loadInHours
                }
            }
    end

    # NxPromises::toString(item)
    def self.toString(item)
        cr = NxPromises::completionRatio(item)
        "🔅 (rc: #{"%6.2f" % (100*cr)} %) #{item["description"]}"
    end

    # NxPromises::listingItems()
    def self.listingItems()
        NxPromises::items()
    end

    # NxPromises::completionRatio(item)
    def self.completionRatio(item)
        doneInHours = Bank::getValue(item["uuid"]).to_f/3600
        doneInHours.to_f/item["loadInHours"]
    end

    # ---------------------------------------------------
    # Ops

    # NxPromises::destroy(uuid)
    def self.destroy(uuid)
        Blades::destroy(uuid)
    end
end
