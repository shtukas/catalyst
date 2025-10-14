
class TxBehaviour

    # ---------------------------------------------------------------
    # Makers

    # TxBehaviour::interactivelyMakeBehaviourOrNull()
    def self.interactivelyMakeBehaviourOrNull()
        options = [
            "listing position",
            "await",
            "calendar event"
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

        raise "(error 6b7b3eab)"
    end

    # ---------------------------------------------------------------
    # Data

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
    end

    # TxBehaviour::realLineTo01Increasing(x)
    def self.realLineTo01Increasing(x)
        (2 + Math.atan(x)).to_f/10
    end

    # TxBehaviour::behaviourToListingPosition(behaviour)
    def self.behaviourToListingPosition(behaviour)
        # There should not be negative positions

        # 0.010 -> 0.020 Wave interruption
        # 0.100 -> 0.150 polymorph: calendar-event
        # 0.160 -> 0.160 NxAwait
        # 0.260 -> 0.280 NxAnniversary
        # 0.280 -> 0.300 NxLambda
        # 0.300 -> 0.320 Wave sticky
        # 0.400 -> 0.450 NxBackup
        # 0.500 -> 0.600 NxOnDate
        # 0.750 -> 0.780 NxProject
        # 0.800 -> 0.880 NxTask
        # 0.390 -> 1.000 Wave (overlay)

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

        raise "I do not know how to compute listing position for behaviour: #{behaviour}"
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

    # TxBehaviour::doneBehaviour(behaviour: TxBehaviour) -> Array[TxBehaviour]
    def self.doneBehaviour(behaviour)
        # {
        #     "btype": "listing-position"
        #     "position": Float
        # }
        if behaviour["btype"] == "listing-position" then
            return nil # it's being destroyed
        end

        #{
        #    "btype": "NxAwait"
        #    "creationUnixtime": Float
        #}
        if behaviour["btype"] == "NxAwait" then
            return nil # it's being destroyed
        end

        # {
        #    "btype": "do-not-show-until"
        #    "unixtime": Float
        # }
        if behaviour["btype"] == "do-not-show-until" then
            return behaviour
        end

        #{
        #     "btype" => "calendar-event",
        #     "date" => 
        #}
        if behaviour["btype"] == "calendar-event" then
            return TxBehaviour::postponeToTomorrowOrNil(behaviour)
        end

        raise "I do not know how to perform done for behaviour: #{behaviour}"
    end

    # TxBehaviour::doneArrayOfBehaviours(behaviours: Array[TxBehaviour]) -> Array[TxBehaviour]
    def self.doneArrayOfBehaviours(behaviours)
        behaviours
            .map{|behaviour| TxBehaviour::doneBehaviour(behaviour) }
            .flatten
            .compact
    end

    # TxBehaviour::doNotShowUntilSuffix(behaviour)
    def self.doNotShowUntilSuffix(behaviour)
        return "" if behaviour["btype"] != "do-not-show-until"
        unixtime = behaviour["unixtime"]
        return "" if unixtime < Time.new.to_i
        " (dot not show until: #{Time.at(unixtime).to_s})".yellow
    end

end
