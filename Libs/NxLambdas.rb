class NxLambdas

    # NxLambdas::interactivelyIssueNewOrNull(description, l)
    def self.interactivelyIssueNewOrNull(description, l)
        {
            "uuid"        => SecureRandom.hex,
            "mikuType"    => "NxLambda",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "lambda"      => l
        }
    end

    # ------------------
    # Data

    # NxLambdas::toString(item)
    def self.toString(item)
        "✨ #{item["description"]}"
    end

    # NxLambdas::run(item)
    def self.run(item)
        item["lambda"].call()
    end
end
