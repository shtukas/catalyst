
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

    # TxEngines::interactivelyEngineSpawnAttempt(item) # boolean status
    def self.interactivelyEngineSpawnAttempt(item)
        uuid = SecureRandom.uuid
        startTime = Time.new.to_i
        durationEstimateInHours = LucilleCore::askQuestionAnswerAsString("durationEstimateInHours: ").to_f
        if durationEstimateInHours == 0 then
            return false
        end
        deadlineInDifferentialDays = LucilleCore::askQuestionAnswerAsString("deadlineInDifferentialDays: ").to_f
        if deadlineInDifferentialDays == 0 then
            return false
        end
        engine = TxEngines::makeEngine(uuid, item["uuid"], startTime, durationEstimateInHours, deadlineInDifferentialDays)
        DarkEnergy::commit(engine)
        DarkEnergy::patch(item["uuid"], "engineuuid", engine["uuid"])
        true
    end

    # -------------------------
    # Data

    # TxEngines::toString(engine)
    def self.toString(engine)
        currentInstant = Time.new.to_f
        deadlineInstant = engine["startTime"] + engine["deadlineInDifferentialDays"]*86400
        timespanLeftToDealine = deadlineInstant - currentInstant
        timespanLeftConsideringEstimationAndDone = engine["durationEstimateInHours"]*3600 - Bank::getValue(engine["uuid"])
        "🚗 (engine: #{timespanLeftConsideringEstimationAndDone.to_f/3600} hours left to do, over #{(timespanLeftToDealine.to_f/86400).round(2)} days, metric: #{TxEngines::listingmetric(engine).round(2)})"
    end

    # TxEngines::engineSuffix(item)
    def self.engineSuffix(item)
        return "" if item["engineuuid"].nil?
        engine = DarkEnergy::itemOrNull(item["engineuuid"])
        if engine.nil? then
            DarkEnergy::patch(item["uuid"], "engineuuid", nil)
            return ""
        end
        TxEngines::toString(engine)
    end

    # TxEngines::listingmetric(engine)
    def self.listingmetric(engine)
        t0 = engine["startTime"]
        t1 = Time.new.to_i
        t2 = t1 + engine["durationEstimateInHours"]*3600
        t3 = engine["startTime"] + engine["deadlineInDifferentialDays"]*86400

        indicator = (t3 - t1).to_f/(t2 - t1)

        # indicator moves to 1 at which point it becomes late

        1.to_f/indicator
    end

    # TxEngines::getItemForEngineOrNull(engine)
    def self.getItemForEngineOrNull(engine)
        DarkEnergy::itemOrNull(engine["targetuuid"])
    end

    # TxEngines::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("TxEngine")
            .select{|engine| TxEngines::listingmetric(engine) >= 0.051 }
    end

    # -------------------------
    # Ops

    # TxEngines::maintenance()
    def self.maintenance()
        DarkEnergy::mikuType("TxEngine").each{|engine|
            if TxEngines::getItemForEngineOrNull(engine).nil? then
                DarkEnergy::destroy(engine["uuid"])
            end
        }
    end

    # TxEngines::program(engine)
    def self.program(engine)
        item = TxEngines::getItemForEngineOrNull(engine)
        if item.nil? then
            puts "Could not determine item for engine: #{item}"
            LucilleCore::pressEnterToContinue()
            return
        end
        PolyActions::program(item)
    end
end
