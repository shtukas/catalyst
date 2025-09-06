
# encoding: UTF-8

class PriorityLevels

    # PriorityLevels::interactivelySelectOne()
    def self.interactivelySelectOne()
        level = LucilleCore::selectEntityFromListOfEntitiesOrNull("level", ["low", "regular", "high", "today"])
        if level then
            return level
        else
            PriorityLevels::interactivelySelectOne()
        end
    end

    # PriorityLevels::priorityLevelTobankAccount(level)
    def self.priorityLevelTobankAccount(level)
        mapping = {
            "low"     => "646cea41-0d35-4ef0-ba58-9c0258cdadba",
            "regular" => "db34db99-0b65-43e0-af74-156da7883521",
            "high"    => "bc1c8cc5-d7df-4d2a-b355-566759a8dc7e",
            "today"   => "170ef0a0-14a2-4286-8e29-25e7fddddf7a"
        }
        account = mapping[level]
        if account.nil? then
            raise "could not determine account number for level: #{level}"
        end
        account
    end

    # PriorityLevels::levelToRatio(level)
    def self.levelToRatio(level)
        if level == "today" then
            raise "You cannot compute level ratio for priority level #{today}"
        end
        account = PriorityLevels::priorityLevelTobankAccount(level)
        rt = BankData::recoveredAverageHoursPerDay(account)
        mapping = {
            "low"     => 1,
            "regular" => 2,
            "high"    => 4,
            "today"   => nil
        }
        rt.to_f/mapping[level]
    end

    # PriorityLevels::itemToListingPosition(itemuuid, level, p1, p2)
    def self.itemToListingPosition(itemuuid, level, p1, p2)
        ratio = PriorityLevels::levelToRatio(level)
        itemRT = BankData::recoveredAverageHoursPerDay(itemuuid)
        p1 + ratio * (p2 - p1).to_f * 1.99 + itemRT * (p2 - p1).to_f/100
    end
end
