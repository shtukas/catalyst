# encoding: UTF-8

class NxPromises

    # ---------------------------------------------------
    # Makers

    # NxPromises::issueNew(description, endCondition, datetimeStart, datetimeEnd, loadInHours)
    def self.issueNew(description, endCondition, datetimeStart, datetimeEnd, loadInHours)
        uuid = SecureRandom.uuid
        Blades::init("NxPromise", uuid)
        Blades::setAttribute2(uuid, "description", description)
        Blades::setAttribute2(uuid, "endCondition", endCondition)
        Blades::setAttribute2(uuid, "datetimeStart", datetimeStart)
        Blades::setAttribute2(uuid, "datetimeEnd", datetimeEnd)
        Blades::setAttribute2(uuid, "loadInHours", loadInHours)
    end

    # NxPromises::interactivelyNewOrNull()
    def self.interactivelyNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        endCondition = LucilleCore::askQuestionAnswerAsString("end condition (empty to abort): ")
        return if endCondition == ""
        datetimeStart = Time.new.utc.iso8601
        puts "datetime start: #{datetimeStart}"
        puts "datetime end  :"
        datetimeEnd = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
        loadInHours = LucilleCore::askQuestionAnswerAsString("load in hours: ").to_f
        NxPromises::issueNew(description, endCondition, datetimeStart, datetimeEnd, loadInHours)
    end

    # ---------------------------------------------------
    # Data

    # NxPromises::uuidToItem(uuid)
    def self.uuidToItem(uuid)
        description   = Blades::getAttributeOrNull2(uuid, "description")
        endCondition   = Blades::getAttributeOrNull2(uuid, "endCondition")
        datetimeStart = Blades::getAttributeOrNull2(uuid, "datetimeStart")
        datetimeEnd   = Blades::getAttributeOrNull2(uuid, "datetimeEnd")
        loadInHours   = Blades::getAttributeOrNull2(uuid, "loadInHours")
        parent        = Blades::getAttributeOrNull2(uuid, "parent")
        {
            "uuid"          => uuid,
            "mikuType"      => "NxPromise",
            "description"   => description,
            "endCondition"  => endCondition,
            "datetimeStart" => datetimeStart,
            "datetimeEnd"   => datetimeEnd,
            "loadInHours"   => loadInHours,
            "parent"        => parent
        }
    end

    # NxPromises::items()
    def self.items()
        Solingen::mikuTypeUUIDs("NxPromise")
            .map{|uuid| NxPromises::uuidToItem(uuid) }
    end

    # NxPromises::toString(item)
    def self.toString(item)
        hoursLeftToDo = item["loadInHours"] - Bank::getValue(item["uuid"]).to_f/3600
        cr = NxPromises::completionRatio(item)
        li = NxPromises::loadIndex(item)
        if li == 1 then
            return "🔅 #{"[late !!]".green} #{item["description"]} (end: #{item["endCondition"]})"
        end
        "🔅 (left: #{hoursLeftToDo.round(2) } hours to #{item["datetimeEnd"]}) (cr: #{"%6.2f" % (100*cr)} %) (li: #{"%5.3f" % li}) #{item["description"]} (end: #{item["endCondition"]})"
    end

    # NxPromises::listingItems1()
    def self.listingItems1()
        NxPromises::items()
            .select{|item| NxPromises::loadIndex(item) >= 0.1 }
            .sort_by{|item| NxPromises::loadIndex(item) }
            .reverse
    end

    # NxPromises::listingItems2()
    def self.listingItems2()
        NxPromises::items()
            .select{|item| NxPromises::loadIndex(item) < 0.1 }
            .sort_by{|item| NxPromises::loadIndex(item) }
            .reverse
    end

    # NxPromises::completionRatio(item)
    def self.completionRatio(item)
        doneInHours = Bank::getValue(item["uuid"]).to_f/3600
        doneInHours.to_f/item["loadInHours"]
    end

    # NxPromises::loadIndex(item)
    def self.loadIndex(item)
        hoursLeftToDo = item["loadInHours"] - Bank::getValue(item["uuid"]).to_f/3600
        hoursToDeadline = (DateTime.parse(item["datetimeEnd"]).to_time.to_i - Time.new.to_i).to_f/3600
        return 1 if hoursToDeadline < 0
        hoursLeftToDo.to_f/hoursToDeadline
    end

    # ---------------------------------------------------
    # Ops

    # NxPromises::destroy(uuid)
    def self.destroy(uuid)
        Blades::destroy(uuid)
    end

    # NxPromises::naturalEvolution(item)
    def self.naturalEvolution(item)
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["destroy", "re-issue"])
        return if option.nil?
        if option == "destroy" then
            NxPromises::destroy(item["uuid"])
        end
        if option == "re-issue" then
            datetimeStart = Time.new.utc.iso8601
            puts "datetime start: #{datetimeStart}"
            puts "datetime end  :"
            datetimeEnd = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
            loadInHours = LucilleCore::askQuestionAnswerAsString("load in hours: ").to_f
            Blades::setAttribute2(item["uuid"], "datetimeStart", datetimeStart)
            Blades::setAttribute2(item["uuid"], "datetimeEnd", datetimeEnd)
            Blades::setAttribute2(item["uuid"], "loadInHours", loadInHours)
        end
    end
end
