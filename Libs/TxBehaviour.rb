
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
            "task"
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
                "date" => CommonUtils::interactivelyMakeADate()
            }
        end

        #{
        #    "btype": "wave"
        #    "nx46": Nx46
        #    "lastDoneUnixtime" : Integer
        #    "interruption" : null or boolean, indicates if the item is interruption
        #}
        if behaviour["btype"] == "wave" then
            return TxBehaviourWave::interactivelyMakeNewOrNull()
        end

        #{
        #    "btype": "task"
        #    "unixtime": Float
        #}
        if behaviour["btype"] == "task" then
            return TxBehaviourWave::interactivelyMakeNewOrNull()
        end

        raise "(error 6b7b3eab)"
    end

    # ---------------------------------------------------------------
    # Data

    # TxBehaviour::behaviourToDescriptionLeft(before, behaviour, after)
    def self.behaviourToDescriptionLeft(before, behaviour, after)
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
            return "#{before}(#{behaviour["date"]})#{after}"
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
        #    "type" : "until-date"
        #    "uuid" : String
        #    "hours": float
        #    "date" : "YYYY-MM-DD"
        #}
        if behaviour["btype"] == "project" then
            return "#{before}(#{JSON.generate(behaviour)})#{after}"
        end

        #{
        #     "btype" => "ondate",
        #     "date" => 
        #}
        if behaviour["btype"] == "ondate" then
            return "#{before}(#{behaviour["date"]})#{after}"
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

        raise "(error 4fba7460) #{behaviour}"
    end

    # TxBehaviour::behaviourToDescriptionRight(before, behaviour, after)
    def self.behaviourToDescriptionRight(before, behaviour, after)
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
            s = "(do not show until #{Time.at(behaviour["unixtime"]).to_s})".yellow
            return "#{before}#{s}#{after}"
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
        #    "type" : "until-date"
        #    "uuid" : String
        #    "hours": float
        #    "date" : "YYYY-MM-DD"
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
        #    "type" : "until-date"
        #    "uuid" : String
        #    "hours": float
        #    "date" : "YYYY-MM-DD"
        #}
        if behaviour["btype"] == "project" then
            return true
        end

        #{
        #     "btype" => "ondate",
        #     "date" => 
        #}
        if behaviour["btype"] == "ondate" then
            return true
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
        #    "type" : "until-date"
        #    "uuid" : String
        #    "hours": float
        #    "date" : "YYYY-MM-DD"
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

        raise "(error 865c0eea) #{behaviour}"
    end

    # TxBehaviour::realLineTo01Increasing(x)
    def self.realLineTo01Increasing(x)
        (2 + Math.atan(x)).to_f/10
    end

    # TxBehaviour::ratio(behaviour)
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
        if behaviour["btype"] == "project" then
            return 0.45
        end

        raise "(error 39498e23) #{behaviour}"
    end

    # TxBehaviour::behaviourToListingPosition(behaviour)
    def self.behaviourToListingPosition(behaviour)
        # There should not be negative positions

        # 0.010 -> 0.020 wave, interruption
        # 0.100 -> 0.150 calendar-event
        # 0.160 -> 0.160 NxAwait
        # 0.260 -> 0.280 NxAnniversary
        # 0.280 -> 0.300 NxLambda
        # 0.300 -> 0.320 wave, sticky
        # 0.400 -> 0.450 NxBackup
        # 0.500 -> 0.600 ondate
        # 0.600 -> 0.800 wave, overlay
        # 0.800 -> 0.880 task

        # 0.350 -> 0.800 polymorph: project

        #{
        #     "btype" => "ondate",
        #     "date" => 
        #}
        if behaviour["btype"] == "ondate" then
            dayNumber = (DateTime.parse("#{behaviour["date"]}T00:00:00Z").to_time.to_f/86400).to_i - 20336
            return 0.51 + TxBehaviour::realLineTo01Increasing(dayNumber).to_f/1000
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
        #     "btype" => "calendar-event",
        #     "date" => 
        #}
        if behaviour["btype"] == "calendar-event" then
            d1 = DateTime.parse("#{behaviour["date"]}T17:28:01Z").to_time.to_i - 1757661467
            d2 = TxBehaviour::realLineTo01Increasing(d1)
            return 0.100 + d2.to_f/100
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
        #    "type" : "until-date"
        #    "uuid" : String
        #    "hours": float
        #    "date" : "YYYY-MM-DD"
        #}
        if behaviour["btype"] == "project" then
            return 0.350 + TxBehaviour::ratio(behaviour)*(0.800 - 0.350)
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
            if behaviour["interruption"] then
                return 0.015
            end
            if behaviour["nx46"]["type"]["sticky"] then
                return 0.310
            end
            return 0.700
        end

        #{
        #    "btype": "task"
        #    "unixtime": Float
        #}
        if behaviour["btype"] == "task" then
            dx = TxBehaviour::realLineTo01Increasing(behaviour["unixtime"] - 1759082216)
            return 0.800 + dx.to_f/1000
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
            return TxBehaviour::postponeToTomorrowOrNil(behaviour)
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
        #    "type" : "until-date"
        #    "uuid" : String
        #    "hours": float
        #    "date" : "YYYY-MM-DD"
        #}
        if behaviour["btype"] == "project" then
            return TxBehaviour::postponeToTomorrowOrNil(behaviour)
        end

        #{
        #     "btype" => "ondate",
        #     "date" => 
        #}
        if behaviour["btype"] == "ondate" then
            return TxBehaviour::postponeToTomorrowOrNil(behaviour)
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
