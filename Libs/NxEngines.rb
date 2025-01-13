
# encoding: UTF-8

class NxEngines

    # NxEngines::interactivelyIssueNew()
    def self.interactivelyIssueNew()
        hours = LucilleCore::askQuestionAnswerAsString("hours (per week) : ").to_f
        {
            "version" => 1,
            "hours"   => hours
        }
    end

    # ------------------
    # Data

    # NxEngines::ratio(itemuuid, engine)
    def self.ratio(itemuuid, engine)
        hours = engine["hours"].to_f
        [Bank1::recoveredAverageHoursPerDay(itemuuid), 0].max.to_f/(hours/7)
    end

    # NxEngines::toString(itemuuid, engine)
    def self.toString(itemuuid, engine)
        "(#{"%6.2f" % (100 * NxEngines::ratio(itemuuid, engine))} %; #{"%5.2f" % engine["hours"]} h/w)".yellow
    end
end
