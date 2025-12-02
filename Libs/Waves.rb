
# encoding: UTF-8

class Waves

    # Waves::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        nx46 = Nx46::interactivelyMakeNewOrNull()
        return nil if nx46.nil?
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "payload-uuid-1141", UxPayloads::interactivelyIssueNewGetReferenceOrNull())
        Items::setAttribute(uuid, "nx46", nx46)
        Items::setAttribute(uuid, "lastDoneUnixtime", 0)
        Items::setAttribute(uuid, "interruption", LucilleCore::askQuestionAnswerAsBoolean("interruption ?: "))
        Items::setAttribute(uuid, "mikuType", "Wave")
        item = Items::objectOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # Waves::nx46ToNextDisplayUnixtime(nx46: Nx46, cursor: Unixtime)
    def self.nx46ToNextDisplayUnixtime(nx46, cursor)
        if nx46["type"] == 'sticky' then
            cursor = cursor + 3600
            while Time.at(cursor).hour != nx46["value"] do
                cursor = cursor + 3600
            end
            return cursor
        end
        if nx46["type"] == 'every-n-hours' then
            return cursor+3600 * nx46["value"].to_f
        end
        if nx46["type"] == 'every-n-days' then
            return cursor+86400 * nx46["value"].to_f
        end
        if nx46["type"] == 'every-this-day-of-the-month' then
            cursor = cursor + 86400
            while Time.at(cursor).strftime("%d") != nx46["value"].rjust(2, "0") do
                cursor = cursor + 3600
            end
           return cursor
        end
        if nx46["type"] == 'every-this-day-of-the-week' then
            cursor = cursor + 86400
            mapping = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
            while mapping[Time.at(cursor).wday] != nx46["value"] do
                cursor = cursor + 3600
            end
            return cursor
        end
        raise "(error: afe44910-57c2-4be5-8e1f-2c2fb80ae61a) nx46: #{JSON.pretty_generate(nx46)}"
    end

    # Waves::nx46ToString(nx46)
    def self.nx46ToString(nx46)
        if nx46["type"] == 'sticky' then
            return "(sticky, from: #{nx46["value"]})"
        end
        "(#{nx46["type"]}: #{nx46["value"]})"
    end

    # Waves::interruptionToStringSuffix(wave)
    def self.interruptionToStringSuffix(wave)
        wave["interruption"] ? " [interruption]".red : ""
    end

    # Waves::toString(item)
    def self.toString(item)
        "🌊 #{Waves::nx46ToString(item["nx46"]).yellow} #{item["description"]}#{Waves::interruptionToStringSuffix(item)}"
    end

    # Waves::listingItems()
    def self.listingItems()
        Items::mikuType("Wave").select{|item| DoNotShowUntil::isVisible(item) }
    end

    # Waves::listingPosition(item)
    def self.listingPosition(item)
        if item["random"].nil? then
            item["random"] = rand
            Items::setAttribute(item["uuid"], "random", item["random"])
        end
        # (copy of listing position table)
        # interruptions : 0.100
        # waves         : 1.350          (over 1.5 hours), then [1.8 ,  1.9]
        if item["interruption"] then
            return 0.100 + 0.001 * item["random"]
        end
        if BankDerivedData::recoveredAverageHoursPerDay("waves-5f12b835") < 1.5 then
            return 1.350 + 0.05 * Math.sin(Time.new.to_f/86400 + item["random"])
        else
            return 1.850 + 0.05 * Math.sin(Time.new.to_f/86400 + item["random"])
        end
    end

    # Waves::performDone(wave)
    def self.performDone(wave)
        Items::setAttribute(wave["uuid"], "lastDoneUnixtime", Time.new.to_i)
        unixtime = Waves::nx46ToNextDisplayUnixtime(wave["nx46"], Time.new.to_i)
        puts "do not show until #{Time.at(unixtime)}".yellow
        DoNotShowUntil::doNotShowUntil(wave, unixtime)
    end
end
