
# encoding: UTF-8

class TxBehaviourWave

    # TxBehaviourWave::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        nx46 = Nx46::makeNx46OrNull()
        return nil if core.nil?
        lastDoneUnixtime = 0
        interruption = LucilleCore::askQuestionAnswerAsBoolean("interruption ?: ")
        {
            "btype"            => "wave",
            "nx46"             => nx46,
            "lastDoneUnixtime" => lastDoneUnixtime,
            "interruption"     => interruption
        }
    end

    # TxBehaviourWave::nx46ToNextDisplayUnixtime(nx46: Nx46, cursor: Unixtime)
    def self.nx46ToNextDisplayUnixtime(nx46, cursor)
        if nx46["type"] == 'sticky' then
            while Time.at(cursor).hour != nx46["value"] do
                cursor = cursor + 3600
            end
            return cursor
        end
        if nx46["type"] == 'every-n-hours' then
            return cursor+3600 * nx46["value"].to_f
        end
        if nx46["type"] == 'every-n-days' then
            return cursor+86400 * nx46["value"].to_f
        end
        if nx46["type"] == 'every-this-day-of-the-month' then
            cursor = cursor + 86400
            while Time.at(cursor).strftime("%d") != nx46["value"].rjust(2, "0") do
                cursor = cursor + 3600
            end
           return cursor
        end
        if nx46["type"] == 'every-this-day-of-the-week' then
            cursor = cursor + 86400
            mapping = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
            while mapping[Time.at(cursor).wday] != nx46["value"] do
                cursor = cursor + 3600
            end
            return cursor
        end
        raise "(error: afe44910-57c2-4be5-8e1f-2c2fb80ae61a) nx46: #{JSON.pretty_generate(nx46)}"
    end

    # TxBehaviourWave::nx46ToString(nx46)
    def self.nx46ToString(nx46)
        if nx46["type"] == 'sticky' then
            return "(sticky, from: #{nx46["value"]})"
        end
        "(#{nx46["type"]}: #{nx46["value"]})"
    end

    # TxBehaviourWave::intsWithPrefix(behaviour)
    def self.intsWithPrefix(behaviour)
        behaviour["interruption"] ? " [interruption]".red : ""
    end

    # TxBehaviourWave::behaviourToString(behaviour)
    def self.behaviourToString(behaviour)
        "#{TxBehaviourWave::nx46ToString(behaviour["nx46"]).yellow}#{TxBehaviourWave::intsWithPrefix(behaviour)}"
    end
end
