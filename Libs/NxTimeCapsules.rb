
class NxTimeCapsules

    # NxTimeCapsules::issue(description, value, flightdata, targetuuid or null)
    def self.issue(description, value, flightdata, targetuuid)
        uuid = SecureRandom.uuid
        Items::itemInit(uuid, "NxTimeCapsule")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "value", value)
        Items::setAttribute(uuid, "flight-data-27", flightdata)
        Items::setAttribute(uuid, "targetuuid", targetuuid)
        Items::itemOrNull(uuid)
    end

    # NxTimeCapsules::liveValue(capsule)
    def self.liveValue(capsule)
        capsule["value"] + Bank1::getValue(capsule["uuid"])
    end

    # NxTimeCapsules::toString(item)
    def self.toString(item)
        "⏱️  (#{NxTimeCapsules::liveValue(item)}) #{item["description"]}"
    end

    # NxTimeCapsules::listingItems()
    def self.listingItems()
        Items::mikuType("NxTimeCapsule")
            .select{|item| item["value"] + Bank1::getValue(item["uuid"]) < 0 }
    end

    # NxTimeCapsules::maintenance()
    def self.maintenance()
        targetuuids = Items::mikuType("NxTimeCapsule").map{|item| item["targetuuid"] }.compact.uniq
        targetuuids.each{|targetuuid|
            capsules = Items::mikuType("NxTimeCapsule")
                        .select{|item| item["targetuuid"] == targetuuid }
                        .sort_by{|item| item["flight-data-27"]["calculated-start"] }
            firstPositive = capsules.select{|item| NxTimeCapsules::liveValue(item) >= 0 }.first
            firstNegative = capsules.select{|item| NxTimeCapsules::liveValue(item) < 0 }.first
            next if firstPositive.nil?
            next if firstNegative.nil?
            next if NxBalls::itemIsActive(firstPositive)
            next if NxBalls::itemIsActive(firstNegative)
            puts "capsule merging for targetuuid: #{targetuuid}"
            puts "positive: #{JSON.pretty_generate(firstPositive)}"
            puts "negative: #{JSON.pretty_generate(firstNegative)}"
            newValue = firstNegative["value"] + NxTimeCapsules::liveValue(firstPositive)
            puts "updating negative with new value: #{newValue}"
            Items::setAttribute(firstNegative["uuid"], "value", newValue)
            Items::destroy(firstPositive["uuid"])
        }
    end

    # NxTimeCapsules::getCapsulesForTarget(targetuuid)
    def self.getCapsulesForTarget(targetuuid)
        Items::mikuType("NxTimeCapsule")
            .select{|item| item["targetuuid"] == targetuuid }
    end

    # NxTimeCapsules::getFirstCapsuleForTargetOrNull(targetuuid)
    def self.getFirstCapsuleForTargetOrNull(targetuuid)
        NxTimeCapsules::getCapsulesForTarget(targetuuid)
            .sort_by{|item| item["flight-data-27"]["calculated-start"] }
            .first
    end

    # NxTimeCapsules::program1(capsule)
    def self.program1(capsule)
        loop {

            capsule = Items::itemOrNull(capsule["uuid"])
            return if capsule.nil?

            system("clear")

            store = ItemStore.new()

            puts ""

            store.register(capsule, false)
            puts Listing::toString2(store, capsule)

            puts ""

            children = Operations::childrenInGlobalPositioningOrder(capsule)

            if capsule["targetuuid"] == NxCores::infinityuuid() then
                children = children.take(20)
            end

            children
                .each{|element|
                    store.register(element, Listing::canBeDefault(element))
                    puts Listing::toString2(store, element)
                }

            puts ""

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
