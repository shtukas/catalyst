
class NxBurners

    # NxBurners::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxBurner", uuid)
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::itemOrNull(uuid)
    end

    # ------------------------------------
    # Data
    # ------------------------------------

    # NxBurners::toString(item)
    def self.toString(item)
        "🕯️  #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
    end

    # NxBurners::itemsForOrbital(orbital)
    def self.itemsForOrbital(orbital)
        DarkEnergy::mikuType("NxBurner").select{|item| item["cliqueuuid"] == orbital["uuid"] }
    end

    # NxBurners::itemsWithoutOrbital()
    def self.itemsWithoutOrbital()
        DarkEnergy::mikuType("NxBurner").select{|item| item["cliqueuuid"].nil? }
    end

    # ------------------------------------
    # Ops
    # ------------------------------------

    # NxBurners::maintenance()
    def self.maintenance()
        DarkEnergy::mikuType("NxBurner")
            .each{|item|
                if item["cliqueuuid"] and DarkEnergy::itemOrNull(item["cliqueuuid"]).nil? then
                    DarkEnergy::patch(uuid, "cliqueuuid", nil)
                end
            }
    end

    # NxBurners::access(item)
    def self.access(item)
        CoreData::access(item["uuid"], item["field11"])
    end

    # NxBurners::program1(item)
    def self.program1(item)
        loop {
            puts item["description"].green
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["done"])
            return if action.nil?
            if action == "done" then
                if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of burner: #{item["description"].green} ? ", true) then
                    DarkEnergy::destroy(item["uuid"])
                end
            end
        }
    end

    # NxBurners::program2()
    def self.program2()
        loop {
            items = DarkEnergy::mikuType("NxBurner").sort{|w1, w2| w1["unixtime"] <=> w2["unixtime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("burner", items, lambda{|item| item["description"] })
            return if item.nil?
            NxBurners::program1(item)
        }
    end
end
