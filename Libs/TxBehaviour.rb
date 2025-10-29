
class TxBehaviour

    # ---------------------------------------------------------------
    # Makers

    # TxBehaviour::interactivelyMakeBehaviourOrNull()
    def self.interactivelyMakeBehaviourOrNull()
        options = [
            "listing position",
            "await",
            "calendar event",
            "project",
            "ondate",
            "wave",
            "task",
            "backup",
            "anniversary"
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("behaviour", options)
        return nil if option.nil?

        if option == "listing position" then
            position = LucilleCore::askQuestionAnswerAsString("position (>0): ").to_f
            return nil if position <= 0
            return {
                 "btype" => "listing-position",
                 "position" => position
            }
        end

        if option == "await" then
            return {
                 "btype" => "NxAwait",
                 "creationUnixtime" => Time.new.to_i
            }
        end

        if option == "calendar event" then
            return {
                 "btype" => "calendar-event",
                 "date" => CommonUtils::interactivelyMakeADate()
            }
        end

        if option == "project" then
            timeCommitment = NxTimeCommitment::interactivelyMakeNewOrNull()
            return nil if timeCommitment.nil?
            return {
                "btype" => "project",
                "timeCommitment" => timeCommitment
            }
        end

        if option == "ondate" then
            timeCommitment = NxTimeCommitment::interactivelyMakeNewOrNull()
            return nil if timeCommitment.nil?
            return {
                "btype" => "ondate",
                "creationUnixtime" => Time.new.to_f,
                "date" => CommonUtils::interactivelyMakeADate()
            }
        end

        #{
        #    "btype": "wave"
        #    "nx46": Nx46
        #    "lastDoneUnixtime" : Integer
        #    "interruption" : null or boolean, indicates if the item is interruption
        #}
        if option == "wave" then
            return Wave::interactivelyMakeNewOrNull()
        end

        #{
        #    "btype": "task"
        #    "unixtime": Float
        #}
        if option == "task" then
            return {
                "btype" => "task",
                "unixtime" => Time.new.to_i
            }
        end

        #{
        #    "btype": "backup"
        #    "period": Float # period in Days
        #}
        if option == "backup" then
            period = LucilleCore::askQuestionAnswerAsString("period (in days): ").to_f
            return {
                "btype" => "backup",
                "period" => period
            }
        end

        #{
        #    "btype": "anniversary"
        #    "startdate"        : YYYY-MM-DD
        #    "repeatType"       : "weekly" | "monthly" | "yearly"
        #    "next_celebration" : YYYY-MM-DD , used for difference calculation when we display after the natural celebration time.
        #}
        if option == "anniversary" then
            return Anniversary::makeNew()
        end

        raise "(error 6b7b3eab)"
    end

    # ---------------------------------------------------------------
    # Data (1)

    # TxBehaviour::behaviourToDescriptionLeft(behaviour)
    def self.behaviourToDescriptionLeft(behaviour)
        # {
        #     "btype": "listing-position"
        #     "position": Float
        # }
        if behaviour["btype"] == "listing-position" then
            return ""
        end

        # {
        #     "btype": "NxAwait"
        #     "creationUnixtime": Float
        # }
        if behaviour["btype"] == "NxAwait" then
            return ""
        end

        # {
        #    "btype": "do-not-show-until"
        #    "unixtime": Float
        # }
        if behaviour["btype"] == "do-not-show-until" then
            return ""
        end

        #{
        #     "btype" => "calendar-event",
        #     "date" => 
        #}
        if behaviour["btype"] == "calendar-event" then
            return "(#{behaviour["date"]}) "
        end

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
        #    "type"  : "unt1l-date-1958"
        #    "uuid"  : String
        #    "hours" : float
        #    "start" : Integer
        #    "end"   : Integer
        #}
        if behaviour["btype"] == "project" then
            return "#{Project::toString(behaviour)} "
        end

        #{
        #     "btype" => "ondate",
        #     "date" => 
        #}
        if behaviour["btype"] == "ondate" then
            return "(#{behaviour["date"]}) "
        end

        #{
        #    "btype": "wave"
        #    "nx46": Nx46
        #    "lastDoneUnixtime" : Integer
        #    "interruption" : null or boolean, indicates if the item is interruption
        #}
        if behaviour["btype"] == "wave" then
            return "#{Wave::behaviourToString(behaviour)} "
        end

        #{
        #    "btype": "task"
        #    "unixtime": Float
        #}
        if behaviour["btype"] == "task" then
            return ""
        end

        #{
        #    "btype": "backup"
        #    "period": Float # period in Days
        #}
        if behaviour["btype"] == "backup" then
            return ""
        end

        #{
        #    "btype": "anniversary"
        #    "startdate"        : YYYY-MM-DD
        #    "repeatType"       : "weekly" | "monthly" | "yearly"
        #    "next_celebration" : YYYY-MM-DD , used for difference calculation when we display after the natural celebration time.
        #}
        if behaviour["btype"] == "anniversary" then
            return "#{Anniversary::toString(behaviour)} "
        end

        #{
        #    "btype": "DayCalendarItem"
        #    "start-unixtime": Int
        #    "start-datetime": Int
        #    "durationInMinutes": Int
        #}
        if behaviour["btype"] == "DayCalendarItem" then
            return "[#{behaviour["start-datetime"][11, 5]} -> #{Time.at(behaviour["start-unixtime"] + behaviour["durationInMinutes"]*60).to_s[11, 5]}] (#{behaviour["durationInMinutes"].to_i.to_s.rjust(3)}) ".red
        end

        #{
        #    "btype": "ExecutionTimer"
        #    "start-unixtime": Int
        #    "start-datetime": Int
        #    "durationInMinutes": Int
        #}
        if behaviour["btype"] == "ExecutionTimer" then
            return "(execution timer: completes at #{Time.at(behaviour["start-unixtime"] + behaviour["durationInMinutes"]*60).to_s}) ".yellow
        end

        raise "(error 4fba7460) #{behaviour}"
    end

    # TxBehaviour::behaviourToDescriptionRight(behaviour)
    def self.behaviourToDescriptionRight(behaviour)
        # {
        #     "btype": "listing-position"
        #     "position": Float
        # }
        if behaviour["btype"] == "listing-position" then
            return ""
        end

        # {
        #     "btype": "NxAwait"
        #     "creationUnixtime": Float
        # }
        if behaviour["btype"] == "NxAwait" then
            return ""
        end

        # {
        #    "btype": "do-not-show-until"
        #    "unixtime": Float
        # }
        if behaviour["btype"] == "do-not-show-until" then
            return " (do not show until #{Time.at(behaviour["unixtime"]).to_s})".yellow
        end

        #{
        #     "btype" => "calendar-event",
        #     "date" => 
        #}
        if behaviour["btype"] == "calendar-event" then
            return ""
        end

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
        #    "type"  : "unt1l-date-1958"
        #    "uuid"  : String
        #    "hours" : float
        #    "start" : Integer
        #    "end"   : Integer
        #}
        if behaviour["btype"] == "project" then
            return " (#{Project::ratio(behaviour).round(3)})".yellow
        end

        #{
        #     "btype" => "ondate",
        #     "date" => 
        #}
        if behaviour["btype"] == "ondate" then
            return ""
        end

        #{
        #    "btype": "wave"
        #    "nx46": Nx46
        #    "lastDoneUnixtime" : Integer
        #    "interruption" : null or boolean, indicates if the item is interruption
        #}
        if behaviour["btype"] == "wave" then
            return ""
        end

        #{
        #    "btype": "task"
        #    "unixtime": Float
        #}
        if behaviour["btype"] == "task" then
            return ""
        end

        #{
        #    "btype": "backup"
        #    "period": Float # period in Days
        #}
        if behaviour["btype"] == "backup" then
            return " (every #{behaviour["period"]} days)"
        end

        #{
        #    "btype": "anniversary"
        #    "startdate"        : YYYY-MM-DD
        #    "repeatType"       : "weekly" | "monthly" | "yearly"
        #    "next_celebration" : YYYY-MM-DD , used for difference calculation when we display after the natural celebration time.
        #}
        if behaviour["btype"] == "anniversary" then
            return ""
        end

        #{
        #    "btype": "DayCalendarItem"
        #    "start-unixtime": Int
        #    "start-datetime": Int
        #    "durationInMinutes": Int
        #}
        if behaviour["btype"] == "DayCalendarItem" then
            return ""
        end

        #{
        #    "btype": "ExecutionTimer"
        #    "start-unixtime": Int
        #    "start-datetime": Int
        #    "durationInMinutes": Int
        #}
        if behaviour["btype"] == "ExecutionTimer" then
            return ""
        end

        raise "(error c073968d) #{behaviour}"
    end

    # TxBehaviour::behaviourToIcon(behaviour)
    def self.behaviourToIcon(behaviour)
        # {
        #     "btype": "listing-position"
        #     "position": Float
        # }
        if behaviour["btype"] == "listing-position" then
            return "🖋️ "
        end

        #{
        #    "btype": "NxAwait"
        #    "creationUnixtime": Float
        #}
        if behaviour["btype"] == "NxAwait" then
            return "😴"
        end

        # {
        #    "btype": "do-not-show-until"
        #    "unixtime": Float
        # }
        if behaviour["btype"] == "do-not-show-until" then
            return "🫥"
        end

        #{
        #     "btype" => "calendar-event",
        #     "date" => 
        #}
        if behaviour["btype"] == "calendar-event" then
            return "📆"
        end

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
        #    "type"  : "unt1l-date-1958"
        #    "uuid"  : String
        #    "hours" : float
        #    "start" : Integer
        #    "end"   : Integer
        #}
        if behaviour["btype"] == "project" then
            return "⛵️"
        end

        #{
        #     "btype" => "ondate",
        #     "date" => 
        #}
        if behaviour["btype"] == "ondate" then
            return "🗓️ "
        end

        #{
        #    "btype": "wave"
        #    "nx46": Nx46
        #    "lastDoneUnixtime" : Integer
        #    "interruption" : null or boolean, indicates if the item is interruption
        #}
        if behaviour["btype"] == "wave" then
            return "🌊"
        end

        #{
        #    "btype": "task"
        #    "unixtime": Float
        #}
        if behaviour["btype"] == "task" then
            return "🔹"
        end

        #{
        #    "btype": "backup"
        #    "period": Float # period in Days
        #}
        if behaviour["btype"] == "backup" then
            return "💾"
        end

        #{
        #    "btype": "anniversary"
        #    "startdate"        : YYYY-MM-DD
        #    "repeatType"       : "weekly" | "monthly" | "yearly"
        #    "next_celebration" : YYYY-MM-DD , used for difference calculation when we display after the natural celebration time.
        #}
        if behaviour["btype"] == "anniversary" then
            return "🎂"
        end

        #{
        #    "btype": "DayCalendarItem"
        #    "start-unixtime": Int
        #    "start-datetime": Int
        #    "durationInMinutes": Int
        #}
        if behaviour["btype"] == "DayCalendarItem" then
            return "⏱️ "
        end

        #{
        #    "btype": "ExecutionTimer"
        #    "start-unixtime": Int
        #    "start-datetime": Int
        #    "durationInMinutes": Int
        #}
        if behaviour["btype"] == "ExecutionTimer" then
            return "⏱️ "
        end

        raise "(error 865c0eea) #{behaviour}"
    end

    # TxBehaviour::bankAccountsNumbers(behaviour)
    def self.bankAccountsNumbers(behaviour)
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
        #    "type"  : "unt1l-date-1958"
        #    "uuid"  : String
        #    "hours" : float
        #    "start" : Integer
        #    "end"   : Integer
        #}
        if behaviour["btype"] == "project" then
            return [behaviour["timeCommitment"]["uuid"]]
        end
        if behaviour["btype"] == "task" then
            return ["task-account-8e7fa41a"]
        end
        return []
    end

    # ---------------------------------------------------------------
    # Data (2) Listing

    # TxBehaviour::realLineTo01Increasing(x)
    def self.realLineTo01Increasing(x)
        (2 + Math.atan(x)).to_f/10
    end

    # TxBehaviour::positionIn(x1, x2)
    def self.positionIn(x1, x2)
        x1 + rand(x2-x1)
    end

    # TxBehaviour::decideBehaviourListingPositionOrNull(behaviour)
    def self.decideBehaviourListingPositionOrNull(behaviour)

        #{
        #    "btype": "DayCalendarItem"
        #    "start-unixtime": Int
        #    "start-datetime": Int
        #    "durationInMinutes": Int
        #}
        if behaviour["btype"] == "DayCalendarItem" then
            return TxBehaviour::positionIn(NxPolymorphs::listingFirstPosition(), NxPolymorphs::listingNthPosition(10))
        end

        #{
        #     "btype" => "ondate",
        #     "date" => 
        #}
        if behaviour["btype"] == "ondate" then
            return nil if CommonUtils::today() < behaviour["date"]
            return TxBehaviour::positionIn(NxPolymorphs::listingNthPosition(10), NxPolymorphs::listingNthPosition(20))
        end

        # {
        #     "btype": "listing-position"
        #     "position": Float
        # }
        if behaviour["btype"] == "listing-position" then
            return behaviour["position"]
        end

        #{
        #    "btype": "NxAwait"
        #    "creationUnixtime": Float
        #}
        if behaviour["btype"] == "NxAwait" then
            return TxBehaviour::positionIn(NxPolymorphs::listingNthPosition(10), NxPolymorphs::listingNthPosition(20))
        end

        #{
        #    "btype": "backup"
        #    "period": Float # period in Days
        #}
        if behaviour["btype"] == "backup" then
            return TxBehaviour::positionIn(NxPolymorphs::listingNthPosition(10), NxPolymorphs::listingNthPosition(20))
        end

        #{
        #     "btype" => "calendar-event",
        #     "date" => 
        #}
        if behaviour["btype"] == "calendar-event" then
            return TxBehaviour::positionIn(NxPolymorphs::listingNthPosition(10), NxPolymorphs::listingNthPosition(20))
        end

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
        #    "type"  : "unt1l-date-1958"
        #    "uuid"  : String
        #    "hours" : float
        #    "start" : Integer
        #    "end"   : Integer
        #}
        if behaviour["btype"] == "project" then
            return nil if Project::ratio(behaviour) >= 1
            return TxBehaviour::positionIn(NxPolymorphs::listingNthPosition(10), NxPolymorphs::listingNthPosition(20))
        end

        if behaviour["btype"] == "do-not-show-until" then
           return nil if Time.new.to_i < behaviour["unixtime"]
            return TxBehaviour::positionIn(NxPolymorphs::listingNthPosition(10), NxPolymorphs::listingNthPosition(20))
        end

        #{
        #    "btype": "wave"
        #    "nx46": Nx46
        #    "lastDoneUnixtime" : Integer
        #    "interruption" : null or boolean, indicates if the item is interruption
        #}
        if behaviour["btype"] == "wave" then
            if behaviour["interruption"] then
                return TxBehaviour::positionIn(NxPolymorphs::listingFirstPosition(), NxPolymorphs::listingNthPosition(10))
            end
            return TxBehaviour::positionIn(NxPolymorphs::listingNthPosition(10), NxPolymorphs::listingNthPosition(20))
        end

        #{
        #    "btype": "task"
        #    "unixtime": Float
        #}
        if behaviour["btype"] == "task" then
            return nil if BankDerivedData::recoveredAverageHoursPerDay("task-account-8e7fa41a") >= 1
            return TxBehaviour::positionIn(NxPolymorphs::listingNthPosition(10), NxPolymorphs::listingNthPosition(20))
        end

        #{
        #    "btype": "anniversary"
        #    "startdate"        : YYYY-MM-DD
        #    "repeatType"       : "weekly" | "monthly" | "yearly"
        #    "next_celebration" : YYYY-MM-DD , used for difference calculation when we display after the natural celebration time.
        #}
        if behaviour["btype"] == "anniversary" then
            return TxBehaviour::positionIn(NxPolymorphs::listingFirstPosition(), NxPolymorphs::listingNthPosition(10))
        end

        #{
        #    "btype": "ExecutionTimer"
        #    "start-unixtime": Int
        #    "start-datetime": Int
        #    "durationInMinutes": Int
        #    "position": Float
        #}
        if behaviour["btype"] == "ExecutionTimer" then
            return TxBehaviour::positionIn(NxPolymorphs::listingFirstPosition(), NxPolymorphs::listingNthPosition(10))
        end

        raise "(error d8e9d7a7) I do not know how to compute listing position for behaviour: #{behaviour}"
    end

    # ---------------------------------------------------------------
    # Ops

    # TxBehaviour::preDisplayProcessing(behaviour)
    def self.preDisplayProcessing(behaviour) # Array[TxBehaviour]
        if behaviour["btype"] == "do-not-show-until" then
            if Time.new.to_i > behaviour["unixtime"] then
                return []
            else
                return [behaviour]
            end
        end
        [behaviour]
    end

    # TxBehaviour::postponeToTomorrowOrNil(behaviour) # TxBehaviour -> null or Array[TxBehaviour]
    def self.postponeToTomorrowOrNil(behaviour)
        options = ["postpone to tomorrow (default)", "destroy"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        if option.nil? or option == "postpone to tomorrow (default)" then
            b1 = {
                "btype" => "do-not-show-until",
                "unixtime" => CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone()
            }
            return [b1, behaviour]
        end
        if option == "destroy" then
            return nil
        end
        raise "(error: 0a89fff3)"
    end

    # TxBehaviour::done(behaviour: TxBehaviour) -> Array[TxBehaviour]
    def self.done(behaviour)
        # {
        #     "btype": "listing-position"
        #     "position": Float
        # }
        if behaviour["btype"] == "listing-position" then
            return [] # it's being destroyed
        end

        #{
        #    "btype": "NxAwait"
        #    "creationUnixtime": Float
        #}
        if behaviour["btype"] == "NxAwait" then
            return [] # it's being destroyed
        end

        #{
        #    "btype": "task"
        #    "unixtime": Float
        #}
        if behaviour["btype"] == "task" then
            return [] # it's being destroyed
        end

        # {
        #    "btype": "do-not-show-until"
        #    "unixtime": Float
        # }
        if behaviour["btype"] == "do-not-show-until" then
            return [behaviour]
        end

        #{
        #     "btype" => "calendar-event",
        #     "date" => 
        #}
        if behaviour["btype"] == "calendar-event" then
            return []
        end

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
        #    "type"  : "unt1l-date-1958"
        #    "uuid"  : String
        #    "hours" : float
        #    "start" : Integer
        #    "end"   : Integer
        #}
        if behaviour["btype"] == "project" then
            return TxBehaviour::postponeToTomorrowOrNil(behaviour)
        end

        #{
        #     "btype" => "ondate",
        #     "date" => 
        #}
        if behaviour["btype"] == "ondate" then
            return []
        end

        #{
        #    "btype": "wave"
        #    "nx46": Nx46
        #    "lastDoneUnixtime" : Integer
        #    "interruption" : null or boolean, indicates if the item is interruption
        #}
        if behaviour["btype"] == "wave" then
            behaviour["lastDoneUnixtime"] = Time.new.to_i
            unixtime = Wave::nx46ToNextDisplayUnixtime(behaviour["nx46"], Time.new.to_i)
            b1 = {
                "btype" => "do-not-show-until",
                "unixtime" => unixtime
            }
            puts "do not show until #{Time.at(unixtime)}".yellow
            return [b1, behaviour]
        end

        #{
        #    "btype": "backup"
        #    "period": Float # period in Days
        #}
        if behaviour["btype"] == "backup" then
            unixtime = Time.new.to_i + behaviour["period"]*86400
            b1 = {
                "btype" => "do-not-show-until",
                "unixtime" => unixtime
            }
            puts "do not show until #{Time.at(unixtime)}".yellow
            return [b1, behaviour]
        end

        #{
        #    "btype": "anniversary"
        #    "startdate"        : YYYY-MM-DD
        #    "repeatType"       : "weekly" | "monthly" | "yearly"
        #    "next_celebration" : YYYY-MM-DD , used for difference calculation when we display after the natural celebration time.
        #}
        if behaviour["btype"] == "anniversary" then
            next_celebration = Anniversary::computeNextCelebrationDate(behaviour["startdate"], behaviour["repeatType"])
            puts "next celebration: #{next_celebration}"
            behaviour["next_celebration"] = next_celebration
            b1 = {
                "btype" => "do-not-show-until",
                "unixtime" => DateTime.parse("#{next_celebration}T00:00:00Z").to_time.to_i
            }
            puts "do not show until #{Time.at(b1["unixtime"])}".yellow
            return [b1, behaviour]
        end

        #{
        #    "btype": "DayCalendarItem"
        #    "start-unixtime": Int
        #    "start-datetime": Int
        #    "durationInMinutes": Int
        #}
        if behaviour["btype"] == "DayCalendarItem" then
            return []
        end

        #{
        #    "btype": "ExecutionTimer"
        #    "start-unixtime": Int
        #    "start-datetime": Int
        #    "durationInMinutes": Int
        #    "position": Float
        #}
        if behaviour["btype"] == "ExecutionTimer" then
            return []
        end

        raise "I do not know how to perform done for behaviour: #{behaviour}"
    end
end
