
# encoding: UTF-8

class Project

    # Project::ratio(behaviour)
    def self.ratio(behaviour)
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
        #{
        #    "type"  : "unt1l-date-1958"
        #    "uuid"  : String
        #    "hours" : float
        #    "start" : Unixtime
        #    "end"   : Unixtime
        #}

        if behaviour["btype"] != "project" then
            raise "(error 803ed063) #{behaviour}"
        end

        timeCommitment = behaviour["timeCommitment"]

        if timeCommitment["type"] == "day" then
            return Bank::getValueAtDate(timeCommitment["uuid"], CommonUtils::today()).to_f/(timeCommitment["hours"]*3600)
        end

        if timeCommitment["type"] == "week" then
            t2 = CommonUtils::datesSinceLastMonday()
                    .map{|date| Bank::getValueAtDate(behaviour["uuid"], date) }
                    .sum
            b2 = t2.to_f/timeCommitment["hours"]
            b3 = BankDerivedData::recoveredAverageHoursPerDay(timeCommitment["uuid"]).to_f/(0.2*timeCommitment["hours"])
            return [b2, b3].max
        end

        if timeCommitment["type"] == "unt1l-date-1958" then
            totalTimespan = timeCommitment["end"] - timeCommitment["start"]
            currentTimespan = Time.new.to_i - timeCommitment["start"]
            return 0 if currentTimespan > totalTimespan
            timeRatio = currentTimespan.to_f/totalTimespan
            idealDoneInHours = timeRatio * timeCommitment["hours"]
            actualDoneInHours = Bank::getValue(timeCommitment["uuid"]).to_f/3600
            return actualDoneInHours.to_f/idealDoneInHours
        end

        if timeCommitment["type"] == "presence" then
            return 0
        end

        raise "(error 39498e23) #{behaviour}"
    end

    # Project::toString(behaviour)
    def self.toString(behaviour)
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

        if timeCommitment["type"] == "unt1l-date-1958" then
            return "(until-date: #{Time.at(timeCommitment["end"]).to_s[0, 10]}, #{timeCommitment["hours"]} hours)"
        end

        if timeCommitment["type"] == "presence" then
            return "(presence)"
        end
    end
end
