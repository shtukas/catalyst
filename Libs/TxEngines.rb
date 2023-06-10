
class TxEngines

    # -------------------------
    # IO

    # TxEngines::makeEngine(uuid, targetuuid, startTime, durationEstimateInHours, deadlineInDifferentialDays)
    def self.makeEngine(uuid, targetuuid, startTime, durationEstimateInHours, deadlineInDifferentialDays)
        {
            "uuid"                       => uuid,
            "mikuType"                   => "TxEngine",
            "targetuuid"                 => targetuuid,
            "startTime"                  => startTime,
            "durationEstimateInHours"    => durationEstimateInHours,
            "deadlineInDifferentialDays" => deadlineInDifferentialDays,
        }
    end

    # TxEngines::interactivelyEngineSpawnAttempt(item)
    def self.interactivelyEngineSpawnAttempt(item)
        uuid = SecureRandom.uuid
        startTime = Time.new.to_i
        durationEstimateInHours = LucilleCore::askQuestionAnswerAsString("durationEstimateInHours: ").to_f
        if durationEstimateInHours == 0 then
            return TxEngines::interactivelyIssueNewOrNull()
        end
        deadlineInDifferentialDays = LucilleCore::askQuestionAnswerAsString("deadlineInDifferentialDays: ").to_f
        if deadlineInDifferentialDays == 0 then
            return TxEngines::interactivelyIssueNewOrNull()
        end
        engine = TxEngines::makeEngine(uuid, item["uuid"], startTime, durationEstimateInHours, deadlineInDifferentialDays)
        DarkEnergy::commit(engine)
        DarkEnergy::patch(item["uuid"], "engineuuid", engine["uuid"])
        engine
    end

    # -------------------------
    # Data

    # TxEngines::toString(engine)
    def self.toString(engine)
        currentInstant = Time.new.to_f
        deadlineInstant = engine["startTime"] + engine["deadlineInDifferentialDays"]*86400
        timespanLeftToDealine = deadlineInstant - currentInstant
        timespanLeftConsideringEstimationAndDone = engine["durationEstimateInHours"]*3600 - Bank::getValue(engine["uuid"])
        "(engine: #{timespanLeftConsideringEstimationAndDone.to_f/3600} hours left to do, over #{timespanLeftToDealine.to_f/86400} days)"
    end

    # TxEngines::engineSuffix(item)
    def self.engineSuffix(item)
        return "" if item["engineuuid"].nil?
        engine = DarkEnergy::itemOrNull(item["engineuuid"])
        if engine.nil? then
            DarkEnergy::patch(item["uuid"], "engineuuid", nil)
            return ""
        end
        if engine["mikuType"] != "TxEngine" then
            DarkEnergy::patch(item["uuid"], "engineuuid", nil)
            return ""
        end
        TxEngines::toString(engine)
    end
end
