
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
            return TxBehaviourWave::interactivelyMakeNewOrNull()
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
            return TxBehaviourAnniversary::makeNew()
        end

        raise "(error 6b7b3eab)"
    end

    # ---------------------------------------------------------------
    # Data

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
            return "#{TxBehaviourProject::toString(behaviour)} "
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
            return "#{TxBehaviourWave::behaviourToString(behaviour)} "
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
            return "#{TxBehaviourAnniversary::toString(behaviour)} "
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
            return ""
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

        raise "(error c073968d) #{behaviour}"
    end

    # TxBehaviour::isVisibleOnFrontPage(behaviour)
    def self.isVisibleOnFrontPage(behaviour)
        # {
        #     "btype": "listing-position"
        #     "position": Float
        # }
        if behaviour["btype"] == "listing-position" then
            return true
        end

        # {
        #     "btype": "NxAwait"
        #     "creationUnixtime": Float
        # }
        if behaviour["btype"] == "NxAwait" then
            return true
        end

        # {
        #    "btype": "do-not-show-until"
        #    "unixtime": Float
        # }
        if behaviour["btype"] == "do-not-show-until" then
            return Time.new.to_i >= behaviour["unixtime"]
        end

        #{
        #     "btype" => "calendar-event",
        #     "date" => 
        #}
        if behaviour["btype"] == "calendar-event" then
            return CommonUtils::today() >= behaviour["date"]
        end

        # {
        #     "btype": "NxAwait"
        #     "creationUnixtime": Float
        # }
        if behaviour["btype"] == "NxAwait" then
            return true
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
            return true
        end

        #{
        #     "btype" => "ondate",
        #     "date" => 
        #}
        if behaviour["btype"] == "ondate" then
            return CommonUtils::today() >= behaviour["date"]
        end

        #{
        #    "btype": "wave"
        #    "nx46": Nx46
        #    "lastDoneUnixtime" : Integer
        #    "interruption" : null or boolean, indicates if the item is interruption
        #}
        if behaviour["btype"] == "wave" then
            return true
        end

        #{
        #    "btype": "task"
        #    "unixtime": Float
        #}
        if behaviour["btype"] == "task" then
            return true
        end

        #{
        #    "btype": "backup"
        #    "period": Float # period in Days
        #}
        if behaviour["btype"] == "backup" then
            return true
        end

        #{
        #    "btype": "anniversary"
        #    "startdate"        : YYYY-MM-DD
        #    "repeatType"       : "weekly" | "monthly" | "yearly"
        #    "next_celebration" : YYYY-MM-DD , used for difference calculation when we display after the natural celebration time.
        #}
        if behaviour["btype"] == "anniversary" then
            return true
        end

        raise "(error 288f4204) #{behaviour}"
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

        raise "(error 865c0eea) #{behaviour}"
    end

    # TxBehaviour::realLineTo01Increasing(x)
    def self.realLineTo01Increasing(x)
        (2 + Math.atan(x)).to_f/10
    end

    # TxBehaviour::behaviourToListingPosition(behaviour)
    def self.behaviourToListingPosition(behaviour)
        # There should not be negative positions

        # 0.010 -> 0.020 wave, interruption
        # 0.100 -> 0.150 calendar-event
        # 0.160 -> 0.160 NxAwait
        # 0.260 -> 0.280 anniversary
        # 0.300 -> 0.320 wave, sticky
        # 0.400 -> 0.450 backup
        # 0.500 -> 0.600 ondate
        # 0.600 -> 0.800 wave, overlay
        # 0.800 -> 0.880 task

        # 0.350 -> 0.700 polymorph: project

        #{
        #     "btype" => "ondate",
        #     "date" => 
        #}
        if behaviour["btype"] == "ondate" then
            dayNumber = (DateTime.parse("#{behaviour["date"]}T00:00:00Z").to_time.to_f/86400).to_i - 20336
            creationUnixtime = behaviour["creationUnixtime"] || 1760531105
            epsilon = TxBehaviour::realLineTo01Increasing(creationUnixtime - 1760531105).to_f/10
            return 0.51 + TxBehaviour::realLineTo01Increasing(dayNumber + epsilon).to_f/100
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
            dx = TxBehaviour::realLineTo01Increasing(behaviour["creationUnixtime"] - 1759082216)
            return 0.160 + dx.to_f/1000
        end

        #{
        #    "btype": "backup"
        #    "period": Float # period in Days
        #}
        if behaviour["btype"] == "backup" then
            return 0.410
        end

        #{
        #     "btype" => "calendar-event",
        #     "date" => 
        #}
        if behaviour["btype"] == "calendar-event" then
            dayNumber = (DateTime.parse("#{behaviour["date"]}T00:00:00Z").to_time.to_f/86400).to_i - 20336
            creationUnixtime = behaviour["creationUnixtime"] || 1760531105
            epsilon = TxBehaviour::realLineTo01Increasing(creationUnixtime - 1760531105).to_f/10
            return 0.100 + TxBehaviour::realLineTo01Increasing(dayNumber + epsilon).to_f/100
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
            return 0.350 + TxBehaviourProject::ratio(behaviour)*(0.700 - 0.350)
        end

        if behaviour["btype"] == "do-not-show-until" then
            return 1
        end

        #{
        #    "btype": "wave"
        #    "nx46": Nx46
        #    "lastDoneUnixtime" : Integer
        #    "interruption" : null or boolean, indicates if the item is interruption
        #}
        if behaviour["btype"] == "wave" then
            epsilon = TxBehaviour::realLineTo01Increasing(behaviour["lastDoneUnixtime"] - 1760531105).to_f/1000
            if behaviour["interruption"] then
                return 0.015 + epsilon
            end
            if behaviour["nx46"]["type"]["sticky"] then
                return 0.310 + epsilon
            end
            return 0.700 + epsilon
        end

        #{
        #    "btype": "task"
        #    "unixtime": Float
        #}
        if behaviour["btype"] == "task" then
            dx = TxBehaviour::realLineTo01Increasing(behaviour["unixtime"] - 1759082216)
            return 0.800 + dx.to_f/1000
        end

        #{
        #    "btype": "anniversary"
        #    "startdate"        : YYYY-MM-DD
        #    "repeatType"       : "weekly" | "monthly" | "yearly"
        #    "next_celebration" : YYYY-MM-DD , used for difference calculation when we display after the natural celebration time.
        #}
        if behaviour["btype"] == "anniversary" then
            unixtime = DateTime.parse("#{behaviour["next_celebration"]}T00:00:00Z").to_time.to_i
            dx = TxBehaviour::realLineTo01Increasing(unixtime - 1760687343)
            return 0.270 + dx.to_f/1000
        end

        raise "(error d8e9d7a7) I do not know how to compute listing position for behaviour: #{behaviour}"
    end

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
        return []
    end

    # ---------------------------------------------------------------
    # Ops

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
            unixtime = TxBehaviourWave::nx46ToNextDisplayUnixtime(behaviour["nx46"], Time.new.to_i)
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
            next_celebration = TxBehaviourAnniversary::computeNextCelebrationDate(behaviour["startdate"], behaviour["repeatType"])
            puts "next celebration: #{next_celebration}"
            behaviour["next_celebration"] = next_celebration
            b1 = {
                "btype" => "do-not-show-until",
                "unixtime" => DateTime.parse("#{next_celebration}T00:00:00Z").to_time.to_i
            }
            puts "do not show until #{Time.at(b1["unixtime"])}".yellow
            return [b1, behaviour]
        end

        raise "I do not know how to perform done for behaviour: #{behaviour}"
    end

    # TxBehaviour::doneArrayOfBehaviours(behaviours: Array[TxBehaviour]) -> Array[TxBehaviour]
    def self.doneArrayOfBehaviours(behaviours)
        behaviours
            .map{|behaviour| TxBehaviour::done(behaviour) }
            .flatten
            .compact
    end
end
