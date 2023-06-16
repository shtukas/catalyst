
# encoding: UTF-8

class Mechanics

    # Mechanics::engine_maintenance(engine)
    def self.engine_maintenance(engine)
        # This serves engine and cores.

        return nil if Bank::getValue(engine["capsule"]).to_f/3600 < engine["hours"]
        return nil if (Time.new.to_i - engine["lastResetTime"]) < 86400*7
        puts "> I am about to reset engine: #{PolyFunctions::toString(engine)}"
        LucilleCore::pressEnterToContinue()
        Bank::reset(engine["capsule"])
        if !LucilleCore::askQuestionAnswerAsBoolean("> continue with #{engine["hours"]} hours ? ") then
            hours = LucilleCore::askQuestionAnswerAsString("specify period load in hours (empty for the current value): ")
            if hours.size > 0 then
                engine["hours"] = hours.to_f
            end
        end
        engine["lastResetTime"] = Time.new.to_i
        DarkEnergy::commit(engine)
    end
end
