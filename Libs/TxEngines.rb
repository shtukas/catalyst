# encoding: UTF-8

class TxEngines

    # TxEngines::interactivelyMakeEngine()
    def self.interactivelyMakeEngine()
        uuid = SecureRandom.uuid
        estimatedDurationInHours = LucilleCore::askQuestionAnswerAsString("estimated duration in hours: ").to_f
        deadlineInRelativeDays = LucilleCore::askQuestionAnswerAsString("deadline in relative days: ").to_f
        {
            "uuid"                        => uuid,
            "mikuType"                    => "TxEngine",
            "start-unixtime"              => Time.new.to_i,
            "estimated-duration-in-hours" => estimatedDurationInHours,
            "deadline-in-relative-days"   => deadlineInRelativeDays
        }
    end

end
