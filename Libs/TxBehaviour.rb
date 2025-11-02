
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
                 "btype" => "NxAwait"
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
        if option == "wave" then
            return Wave::interactivelyMakeNewOrNull()
        end
        if option == "task" then
            return {
                "btype" => "task",
                "unixtime" => Time.new.to_i
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
        if behaviour["btype"] == "listing-position" then
            return ""
        end
        if behaviour["btype"] == "NxAwait" then
            return ""
        end
        if behaviour["btype"] == "do-not-show-until" then
            return ""
        end
        if behaviour["btype"] == "calendar-event" then
            return "(#{behaviour["date"]}) "
        end
        if behaviour["btype"] == "project" then
            return ""
        end
        if behaviour["btype"] == "ondate" then
            return "(#{behaviour["date"]}) "
        end
        if behaviour["btype"] == "wave" then
            return "#{Wave::behaviourToString(behaviour)} "
        end
        if behaviour["btype"] == "task" then
            return ""
        end
        if behaviour["btype"] == "backup" then
            return ""
        end
        if behaviour["btype"] == "anniversary" then
            return "#{Anniversary::toString(behaviour)} "
        end
        ""
    end

    # TxBehaviour::behaviourToDescriptionRight(behaviour, runningTimespan)
    def self.behaviourToDescriptionRight(behaviour, runningTimespan)
        if behaviour["btype"] == "listing-position" then
            return ""
        end
        if behaviour["btype"] == "NxAwait" then
            return ""
        end
        if behaviour["btype"] == "do-not-show-until" then
            return " (do not show until #{Time.at(behaviour["unixtime"]).to_s})".yellow
        end
        if behaviour["btype"] == "calendar-event" then
            return ""
        end
        if behaviour["btype"] == "project" then
            return " #{Project::toDescription(behaviour)} (#{Project::ratio(behaviour, runningTimespan).round(3)})".yellow
        end
        if behaviour["btype"] == "ondate" then
            return ""
        end
        if behaviour["btype"] == "wave" then
            return ""
        end
        if behaviour["btype"] == "task" then
            return ""
        end
        if behaviour["btype"] == "backup" then
            return " (every #{behaviour["period"]} days)"
        end
        if behaviour["btype"] == "anniversary" then
            return ""
        end
        ""
    end

    # TxBehaviour::behaviourToIcon(behaviour)
    def self.behaviourToIcon(behaviour)
        if behaviour["btype"] == "listing-position" then
            return "🖋️ "
        end
        if behaviour["btype"] == "NxAwait" then
            return "😴"
        end
        if behaviour["btype"] == "do-not-show-until" then
            return "🫥"
        end
        if behaviour["btype"] == "calendar-event" then
            return "📆"
        end
        if behaviour["btype"] == "project" then
            return "⛵️"
        end
        if behaviour["btype"] == "ondate" then
            return "🗓️ "
        end
        if behaviour["btype"] == "wave" then
            return "🌊"
        end
        if behaviour["btype"] == "task" then
            return "🔹"
        end
        if behaviour["btype"] == "backup" then
            return "💾"
        end
        if behaviour["btype"] == "anniversary" then
            return "🎂"
        end
        "[icon]"
    end

    # TxBehaviour::bankAccountsNumbers(behaviour)
    def self.bankAccountsNumbers(behaviour)
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

    # TxBehaviour::positionIn(area)
    def self.positionIn(area)
        if area == "zone1" then
            x1 = NxPolymorphs::listingNthPosition(1)
            x2 = NxPolymorphs::listingNthPosition(5)
            return x1 + rand(x2-x1)
        end
        if area == "zone2" then
            x1 = NxPolymorphs::listingNthPosition(5)
            x2 = NxPolymorphs::listingNthPosition(10)
            return x1 + rand(x2-x1)
        end
        if area == "zone3" then
            x1 = NxPolymorphs::listingNthPosition(10)
            x2 = NxPolymorphs::listingNthPosition(20)
            return x1 + rand(x2-x1)
        end
        raise "(error: 2131)"
    end

    # TxBehaviour::decideBehaviourListingPositionOrNull(behaviour, runningTimespan)
    def self.decideBehaviourListingPositionOrNull(behaviour, runningTimespan)
        if behaviour["btype"] == "ondate" then
            return nil if CommonUtils::today() < behaviour["date"]
            return TxBehaviour::positionIn("zone3")
        end
        if behaviour["btype"] == "listing-position" then
            return behaviour["position"]
        end
        if behaviour["btype"] == "NxAwait" then
            return TxBehaviour::positionIn("zone3")
        end
        if behaviour["btype"] == "backup" then
            return TxBehaviour::positionIn("zone3")
        end
        if behaviour["btype"] == "calendar-event" then
            return TxBehaviour::positionIn("zone3")
        end
        if behaviour["btype"] == "project" then
            return nil if Project::ratio(behaviour, runningTimespan) >= 1
            return TxBehaviour::positionIn("zone3")
        end
        if behaviour["btype"] == "do-not-show-until" then
           return nil if Time.new.to_i < behaviour["unixtime"]
            return TxBehaviour::positionIn("zone3")
        end
        if behaviour["btype"] == "wave" then
            if behaviour["interruption"] then
                return TxBehaviour::positionIn("zone1")
            end
            return TxBehaviour::positionIn("zone3")
        end
        if behaviour["btype"] == "task" then
            return nil if BankDerivedData::recoveredAverageHoursPerDay("task-account-8e7fa41a") >= 1
            return TxBehaviour::positionIn("zone3")
        end
        if behaviour["btype"] == "anniversary" then
            return TxBehaviour::positionIn("zone2")
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

    # TxBehaviour::stop(behaviour: TxBehaviour) -> Array[TxBehaviour]
    def self.stop(behaviour)
        if behaviour["btype"] == "listing-position" then
            return []
        end
        [behaviour]
    end

    # TxBehaviour::done(behaviour: TxBehaviour) -> Array[TxBehaviour]
    def self.done(behaviour)
        if behaviour["btype"] == "listing-position" then
            return [] # it's being destroyed
        end
        if behaviour["btype"] == "NxAwait" then
            return [] # it's being destroyed
        end
        if behaviour["btype"] == "task" then
            return [] # it's being destroyed
        end
        if behaviour["btype"] == "do-not-show-until" then
            return [behaviour]
        end
        if behaviour["btype"] == "calendar-event" then
            return []
        end
        if behaviour["btype"] == "project" then
            return TxBehaviour::postponeToTomorrowOrNil(behaviour)
        end
        if behaviour["btype"] == "ondate" then
            return []
        end
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
        if behaviour["btype"] == "backup" then
            unixtime = Time.new.to_i + behaviour["period"]*86400
            b1 = {
                "btype" => "do-not-show-until",
                "unixtime" => unixtime
            }
            puts "do not show until #{Time.at(unixtime)}".yellow
            return [b1, behaviour]
        end
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

        raise "I do not know how to perform done for behaviour: #{behaviour}"
    end
end
