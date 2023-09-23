# encoding: UTF-8

class NxLambdas

    # NxLambdas::make(uuid, description, l)
    def self.make(uuid, description, l)
        {
            "uuid"        => uuid,
            "mikuType"    => "NxLambda",
            "description" => description,
            "lambda"      => l
        }
    end
end
