
# encoding: UTF-8

class Project

    # Project::ratio(behaviour, runningTimespan)
    def self.ratio(behaviour, runningTimespan)
        #{
        #    "btype": "project"
        #    "timeCommitment": NxTimeCommitment
        #}

        #NxTimeCommitment
        #{
        #    "type"  : "day"
        #    "uuid"  : String
        #    "hours" : float
        #}
        #{
        #    "type"  : "week"
        #    "uuid"  : String
        #    "hours" : float
        #}

        if behaviour["btype"] != "project" then
            raise "(error 803ed063) #{behaviour}"
        end

        timeCommitment = behaviour["timeCommitment"]

        if timeCommitment["type"] == "day" then
            totalTimespan = Bank::getValueAtDate(timeCommitment["uuid"], CommonUtils::today()) + runningTimespan
            return totalTimespan.to_f/(timeCommitment["hours"]*3600)
        end

        if timeCommitment["type"] == "week" then
            t2 = CommonUtils::datesSinceLastMonday()
                    .map{|date| Bank::getValueAtDate(behaviour["timeCommitment"]["uuid"], date) }
                    .sum
            b2 = (t2+runningTimespan).to_f/(timeCommitment["hours"]*3600)
            b3 = BankDerivedData::recoveredAverageHoursPerDay(timeCommitment["uuid"], runningTimespan).to_f/(0.2*timeCommitment["hours"])
            return [b2, b3].max
        end

        if timeCommitment["type"] == "presence" then
            return (runningTimespan < 3600) ? 0 : 1
        end

        raise "(error: 90c405b2-3bb3)"
    end

    # Project::toDescription(behaviour)
    def self.toDescription(behaviour)
        if behaviour["btype"] != "project" then
            raise "(error 28ad66c3) #{behaviour}"
        end

        timeCommitment = behaviour["timeCommitment"]

        if timeCommitment["type"] == "day" then
            return "(day: #{timeCommitment["hours"]} hours)"
        end

        if timeCommitment["type"] == "week" then
            return "(week: #{timeCommitment["hours"]} hours)"
        end

        if timeCommitment["type"] == "presence" then
            return "(presence)"
        end

        ""
    end
end
