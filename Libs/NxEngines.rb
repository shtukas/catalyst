
# encoding: UTF-8

class NxEngines

    # NxEngines::interactivelyIssueNew()
    def self.interactivelyIssueNew()
        lambda1 = lambda {|version|
            return "hours commitment + donation" if version == 1
            return "automatically managed + donation" if version == 2
            raise "(error: 43599c66)"
        }
        version = LucilleCore::selectEntityFromListOfEntitiesOrNull("version", [1, 2], lambda1)
        return nil if version.nil?

        if version == 1 then
            hours = LucilleCore::askQuestionAnswerAsString("hours (per week) : ").to_f
            stack = NxStacks::interactivelySelectOrNull()
            return {
                "version" => 1,
                "hours"   => hours,
                "targetuuid" => stack["uuid"]
            }
        end

        if version == 2 then
            stack = NxStacks::interactivelySelectOrNull()
            return nil if stack.nil?
            return {
                "version"    => 2,
                "targetuuid" => stack["uuid"]
            }
        end

        nil
    end

    # ------------------
    # Data

    # NxEngines::ratio(itemuuid, engine)
    def self.ratio(itemuuid, engine)
        hours = engine["hours"].to_f
        [Bank1::recoveredAverageHoursPerDay(itemuuid), 0].max.to_f/(hours/7)
    end

    # NxEngines::toStringSuffix(itemuuid, engine)
    def self.toStringSuffix(itemuuid, engine)
        return "" if engine.nil?
        if engine["version"] == 1 then
            return " (#{"%6.2f" % (100 * NxEngines::ratio(itemuuid, engine))} %; #{"%5.2f" % engine["hours"]} h/w)".yellow
        end
        if engine["version"] == 2 then
            return " (rt: #{Bank1::recoveredAverageHoursPerDay(itemuuid)})".yellow
        end
        raise "(error: 84be9938)"
    end
end
