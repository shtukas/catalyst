
class PoolBanking

    # PoolBanking::dayRatioOrNull(pool)
    def self.dayRatioOrNull(pool)
        return nil if pool["dailyHours"].nil?
        todos = pool["uuids"]
                    .map{|uuid| Cubes::itemOrNull(uuid) }
                    .compact
        return 1 if todos.empty?
        hoursDone = todos
                        .map{|todo| Bank::getValueAtDate(todo["uuid"], CommonUtils::today()) }
                        .map{|value| value.to_f/3066 }
                        .inject(0, :+)
        hoursDone.to_f/pool["dailyHours"]
    end

    # PoolBanking::weekRatioOrNull(pool)
    def self.weekRatioOrNull(pool)
        return nil if pool["weeklyHours"].nil?
        todos = pool["uuids"]
                    .map{|uuid| Cubes::itemOrNull(uuid) }
                    .compact
        return 1 if todos.empty?
        hoursDone = (0..6)
                        .map{|ind|
                            todos
                                .map{|todo| Bank::getValueAtDate(todo["uuid"], CommonUtils::nDaysInTheFuture(-ind)) }
                                .map{|value| value.to_f/3066 }
                                .inject(0, :+)
                        }
                        .inject(0, :+)
        hoursDone.to_f/pool["weeklyHours"]
    end

    # PoolBanking::ratio(pool)
    def self.ratio(pool)
        [PoolBanking::dayRatioOrNull(pool), PoolBanking::weekRatioOrNull(pool)].compact.max
    end
end

class NxPools

    # NxPools::issue(uuids, dailyHours, weeklyHours)
    def self.issue(uuids, dailyHours, weeklyHours)
        uuid = SecureRandom.uuid
        Cubes::init(nil, "NxPool", uuid)
        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute2(uuid, "uuids", uuids)
        Cubes::setAttribute2(uuid, "dailyHours", dailyHours)
        Cubes::setAttribute2(uuid, "weeklyHours", weeklyHours)
        Cubes::itemOrNull(uuid)
    end

    # NxPools::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        todos = Todos::topItemsForPoolBuilding().sort_by{|item| item["coordinate-nx129"] || 0  }
        todos, _ = LucilleCore::selectZeroOrMore("todos", [], todos, lambda{|item| "#{PolyFunctions::toString(item)}#{PolyFunctions::lineageSuffix(item).yellow}" })
        return nil if todos.empty?
        dailyHours = LucilleCore::askQuestionAnswerAsString("daily hours: ")
        dailyHours = dailyHours.size > 0 ? dailyHours.to_f : nil
        weeklyHours = LucilleCore::askQuestionAnswerAsString("weekly hours: ")
        weeklyHours = weeklyHours.size > 0 ? weeklyHours.to_f : nil
        return nil if dailyHours.nil? and weeklyHours.nil?
        NxPools::issue(todos.map{|todo| todo["uuid"] }, dailyHours, weeklyHours)
    end

    # NxPools::poolToElementsInOrder(pool)
    def self.poolToElementsInOrder(pool)
        elements = pool["uuids"]
                    .map{|uuid| Cubes::itemOrNull(uuid) }
                    .compact
        if elements.size < pool["uuids"].size then
            Cubes::setAttribute2(pool["uuid"], "uuids", elements.map{|item| item["uuid"] })
        end
        if elements.size == 0 then
            Cubes::destroy(pool["uuid"])
        end
        elements
            .sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
    end

    # NxPools::poolToCompletionRatio(pool)
    def self.poolToCompletionRatio(pool)
        PoolBanking::ratio(pool)
    end

    # NxPools::listingItems()
    def self.listingItems()
        Cubes::mikuType("NxPool")
            .select{|pool| NxPools::poolToCompletionRatio(pool) < 1 }
            .sort_by{|pool| NxPools::poolToCompletionRatio(pool) }
            .map{|pool|
                elements = NxPools::poolToElementsInOrder(pool)
                            .map{|item|
                                item["prefix-override"] = "(#{"%5.3f" % Bank::recoveredAverageHoursPerDay(item["uuid"])})"
                                item
                            }
                [pool] + elements
            }
            .flatten
    end

    # NxPools::toString(pool)
    def self.toString(pool)
        "pool: #{NxPools::poolToCompletionRatio(pool)}"
    end
end
