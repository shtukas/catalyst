
class TxBehaviour

    # ---------------------------------------------------------------
    # Makers

    # TxBehaviour::interactivelyMakeBehaviourOrNull()
    def self.interactivelyMakeBehaviourOrNull()
        options = [
            "ondate",
            "backup",
            "anniversary"
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("behaviour", options)
        return nil if option.nil?
        if option == "ondate" then
            return {
                "btype" => "ondate",
                "date" => CommonUtils::interactivelyMakeADate()
            }
        end
        if option == "backup" then
            period = LucilleCore::askQuestionAnswerAsString("period (in days): ").to_f
            return {
                "btype" => "backup",
                "period" => period
            }
        end
        if option == "anniversary" then
            return Anniversary::makeNew()
        end

        raise "(error 6b7b3eab)"
    end

    # ---------------------------------------------------------------
    # Data (1)

    # TxBehaviour::behaviourToDescriptionLeft(behaviour)
    def self.behaviourToDescriptionLeft(behaviour)
        if behaviour["btype"] == "ondate" then
            return "(#{behaviour["date"]}) "
        end
        if behaviour["btype"] == "anniversary" then
            return "#{Anniversary::toString(behaviour)} "
        end
        ""
    end

    # TxBehaviour::behaviourToDescriptionRight(behaviour, runningTimespan)
    def self.behaviourToDescriptionRight(behaviour, runningTimespan)
        if behaviour["btype"] == "do-not-show-until" then
            return " (do not show until #{Time.at(behaviour["unixtime"]).to_s})".yellow
        end
        if behaviour["btype"] == "backup" then
            return " (every #{behaviour["period"]} days)"
        end
        ""
    end

    # TxBehaviour::behaviourToIcon(behaviour)
    def self.behaviourToIcon(behaviour)
        if behaviour["btype"] == "NxAwait" then
            return "😴"
        end
        if behaviour["btype"] == "do-not-show-until" then
            return "🫥"
        end
        if behaviour["btype"] == "ondate" then
            return "🗓️ "
        end
        if behaviour["btype"] == "wave" then
            return "🌊"
        end
        if behaviour["btype"] == "backup" then
            return "💾"
        end
        if behaviour["btype"] == "anniversary" then
            return "🎂"
        end
        "[icon]"
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
            return {
                "behaviour" => behaviour,
                "do-not-show-until" => CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone()
            }
        end
        if option == "destroy" then
            return nil
        end
        raise "(error: 0a89fff3)"
    end

    # TxBehaviour::done(behaviour: TxBehaviour) -> null or { "behaviour" => behaviour, "do-not-show-until" => unixtime }
    def self.done(behaviour)
        if behaviour["btype"] == "backup" then
            unixtime = Time.new.to_i + behaviour["period"]*86400
            puts "do not show until #{Time.at(unixtime)}".yellow
            return {
                "behaviour" => behaviour,
                "do-not-show-until" => unixtime
            }
        end
        if behaviour["btype"] == "anniversary" then
            next_celebration = Anniversary::computeNextCelebrationDate(behaviour["startdate"], behaviour["repeatType"])
            puts "next celebration: #{next_celebration}"
            behaviour["next_celebration"] = next_celebration
            puts "do not show until #{DateTime.parse("#{next_celebration}T00:00:00Z")}".yellow
            unixtime = DateTime.parse("#{next_celebration}T00:00:00Z").to_time.to_i
            return {
                "behaviour" => behaviour,
                "do-not-show-until" => unixtime
            }
        end
        nil
    end
end
