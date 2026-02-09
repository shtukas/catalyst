# encoding: UTF-8

class NxEngine

    # NxEngine::set_value(item)
    def self.set_value(item)
        whours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
        Blades::setAttribute(item["uuid"], "whours-45", whours)
        Blades::itemOrNull(item["uuid"])
    end

    # NxEngine::set_value_proposal(item)
    def self.set_value_proposal(item)
        if LucilleCore::askQuestionAnswerAsBoolean("set engine value for #{PolyFunctions::toString(item).green} ? ") then
            whours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
            Blades::setAttribute(item["uuid"], "whours-45", whours)
            return Blades::itemOrNull(item["uuid"])
        end
        item
    end

    # NxEngine::ratio(item)
    def self.ratio(item)
        return 0 if item["whours-45"].nil?
        return 0 if item["whours-45"] == 0

        todayComputedDemandInHours = XCache::getOrNull("today-demain-in-hours-112c8ddfee17:#{CommonUtils::today()}:#{item["uuid"]}")
        if todayComputedDemandInHours then
            todayComputedDemandInHours = todayComputedDemandInHours.to_f
            if todayComputedDemandInHours <= 0 then
                return 1
            end
            return Bank::getValueAtDate(item["uuid"], CommonUtils::today()).to_f/(todayComputedDemandInHours*3600)
        end

        daysSinceMondayNotIncludingToday = (lambda{
            today = Date.today
            monday = today - (today.wday - 1) % 7
            dates = (monday...today).map { |d| d.strftime("%Y-%m-%d") }
            dates
        }).call()

        #puts "daysSinceMondayNotIncludingToday: #{daysSinceMondayNotIncludingToday.join(", ")}"

        daysToCommingSunday = (lambda {
            today = Date.today
            sunday = today + ((7 - today.wday) % 7)
            dates = (today..sunday).map { |d| d.strftime("%Y-%m-%d") }
            dates
        }).call()

        #puts "daysToCommingSunday: #{daysToCommingSunday.join(", ")}"
        #exit

        timeDoneUntilTodayInSeconds = daysSinceMondayNotIncludingToday.map{|date| Bank::getValueAtDate(item["uuid"], date) }.sum
        timeLeftToDoThisWeekInSeconds = item["whours-45"]*3600 - timeDoneUntilTodayInSeconds
        timeLeftToDoThisWeekInHours = timeLeftToDoThisWeekInSeconds.to_f/3600

        todayComputedDemandInHours = timeLeftToDoThisWeekInHours.to_f/daysToCommingSunday.size

        XCache::set("today-demain-in-hours-112c8ddfee17:#{CommonUtils::today()}:#{item["uuid"]}", todayComputedDemandInHours)

        Bank::getValueAtDate(item["uuid"], CommonUtils::today())/(todayComputedDemandInHours*3600)
    end

    # NxEngine::listingItems()
    def self.listingItems()
        Blades::items()
            .select{|item| item["whours-45"] }
            .select{|item| NxEngine::ratio(item) < 1 }
    end

    # NxEngine::suffix(item)
    def self.suffix(item)
        return "" if item["whours-45"].nil?
        " (#{"%6.2f" % (100 * NxEngine::ratio(item)).round(2)} % of daily #{"%4.2f" % (item["whours-45"].to_f/7)})".green
    end
end
