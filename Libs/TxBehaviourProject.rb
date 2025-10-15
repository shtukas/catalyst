
# encoding: UTF-8

class TxBehaviourProject

    # TxBehaviourProject::ratio(behaviour)
    def self.ratio(behaviour)
        #{
        #    "btype": "project"
        #    "timeCommitment": NxTimeCommitment
        #}
        #NxTimeCommitment
        #{
        #    "type" : "day"
        #    "uuid" : String
        #    "hours": float
        #}
        #{
        #    "type" : "week"
        #    "uuid" : String
        #    "hours": float
        #}
        #{
        #    "type" : "until-date"
        #    "uuid" : String
        #    "hours": float
        #    "date" : "YYYY-MM-DD"
        #}

        if behaviour["btype"] != "project" then
            raise "(error 803ed063) #{behaviour}"
        end

        timeCommitment = behaviour["timeCommitment"]

        if timeCommitment["type"] == "day" then
            return BankVault::getValueAtDate(timeCommitment["uuid"], CommonUtils::today()).to_f/(timeCommitment["hours"]*3600)
        end

        if timeCommitment["type"] == "week" then
            t2 = CommonUtils::datesSinceLastMonday()
                    .map{|date| BankVault::getValueAtDate(behaviour["uuid"], date) }
                    .sum
            b2 = t2.to_f/timeCommitment["hours"]
            b3 = BankData::recoveredAverageHoursPerDay(timeCommitment["uuid"]).to_f/(0.2*timeCommitment["hours"])
            return [b2, b3].max
        end

        if timeCommitment["type"] == "until-date" then
            return BankData::recoveredAverageHoursPerDay(timeCommitment["uuid"]).to_f
        end

        raise "(error 39498e23) #{behaviour}"
    end

    # TxBehaviourProject::toString(behaviour)
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

        if timeCommitment["type"] == "until-date" then
            return "(until-date: #{timeCommitment["hours"]}, #{timeCommitment["hours"]} hours)"
        end
    end
end
