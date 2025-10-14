
# encoding: UTF-8

class NxTimeCommitment

    # NxTimeCommitment::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        options = [
            "day",
            "week",
            "until-date"
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        return nil if option.nil?

        if option == "day" then
            hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
            return {
                 "type" => "day",
                 "uuid" => SecureRandom.uuid,
                 "hours" => hours
            }
        end

        if option == "week" then
            hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
            return {
                 "type" => "week",
                 "uuid" => SecureRandom.uuid,
                 "hours" => hours
            }
        end

        if option == "until date" then
            hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
            return {
                 "type" => "until-date",
                 "uuid" => SecureRandom.uuid,
                 "hours" => hours,
                 "date" => CommonUtils::interactivelyMakeADate()
            }
        end

        raise "(error 49bf8262)"
    end
end
