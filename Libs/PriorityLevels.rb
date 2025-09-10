
# encoding: UTF-8

class PriorityLevels

    # PriorityLevels::levels()
    def self.levels()
        ["low", "regular", "high"]
    end

    # PriorityLevels::interactivelySelectOne()
    def self.interactivelySelectOne()
        level = LucilleCore::selectEntityFromListOfEntitiesOrNull("level", PriorityLevels::levels())
        if level then
            return level
        else
            PriorityLevels::interactivelySelectOne()
        end
    end

    # PriorityLevels::levelToBankAccount(level)
    def self.levelToBankAccount(level)
        mapping = {
            "low"     => "646cea41-0d35-4ef0-ba58-9c0258cdadba",
            "regular" => "db34db99-0b65-43e0-af74-156da7883521",
            "high"    => "bc1c8cc5-d7df-4d2a-b355-566759a8dc7e"
        }
        mapping[level]
    end

    # PriorityLevels::priorityLevelTobankAccount(level)
    def self.priorityLevelTobankAccount(level)
        account = PriorityLevels::levelToBankAccount(level)
        if account.nil? then
            raise "could not determine account number for level: #{level}"
        end
        account
    end

    # PriorityLevels::rtToRatio(rt, level)
    def self.rtToRatio(rt, level)
        mapping = {
            "low"     => 1,
            "regular" => 2,
            "high"    => 4
        }
        rt.to_f/mapping[level]
    end

    # PriorityLevels::levelToRatio(level)
    def self.levelToRatio(level)
        account = PriorityLevels::priorityLevelTobankAccount(level)
        rt = BankData::recoveredAverageHoursPerDay(account)
        PriorityLevels::rtToRatio(rt, level)
    end

    # PriorityLevels::itemToListingPosition(itemuuid, level, p1, p2)
    def self.itemToListingPosition(itemuuid, level, p1, p2)
        ratio = PriorityLevels::levelToRatio(level)
        itemRT = BankData::recoveredAverageHoursPerDay(itemuuid)
        p1 + ratio * (p2 - p1).to_f * 1.99 + itemRT * (p2 - p1).to_f/100
    end

    # PriorityLevels::print_numbers()
    def self.print_numbers()
        PriorityLevels::levels()
            .map{|level|
                account = PriorityLevels::levelToBankAccount(level)
                rt = BankData::recoveredAverageHoursPerDay(account)
                ratio = PriorityLevels::rtToRatio(rt, level)
                line = "#{level.ljust(8)}, bank account: #{account}, rt: #{"%2.3f" % rt}, ratio: #{"%2.3f" % ratio}"
                {
                    "ratio" => ratio,
                    "line" => line
                }
            }
            .sort_by{|s| s["ratio"] }
            .each{|s|
                puts s["line"]
            }
        LucilleCore::pressEnterToContinue()
    end

    # PriorityLevels::levelToThread(level)
    def self.levelToThread(level)
        if level == "low" then
            return Items::itemOrNull("04f2e85f-7157-435f-bf37-d91c8ae36976")
        end
        if level == "regular" then
            return Items::itemOrNull("4392a2a7-04b6-4e35-be41-cf57c43b088e")
        end
        if level == "high" then
            return Items::itemOrNull("fccf059f-2ba0-41de-963e-34834ded1b74")
        end
    end
end
