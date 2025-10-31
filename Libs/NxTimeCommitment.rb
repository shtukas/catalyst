
# encoding: UTF-8

class NxTimeCommitment

    # NxTimeCommitment::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        options = [
            "day",
            "week",
            "presence"
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

        if option == "presence" then
            return {
                 "type" => "presence",
                 "uuid" => SecureRandom.uuid
            }
        end

        raise "(error 49bf8262)"
    end
end
