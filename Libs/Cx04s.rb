# encoding: UTF-8

class Cx04

    # Cx04::cx04s(items)
    def self.cx04s(items)
        items
            .map{|item| item["cx04"] }
            .compact
            .reduce([]){|collection, item|
                if collection.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    collection
                else
                    collection + [item]
                end
            }
    end

    # Cx04::architectOrNull()
    def self.architectOrNull()
        items = Listing::items()
        cx04s = Cx04::cx04s(items)
        if !cx04s.empty? then
            cx04 = LucilleCore::selectEntityFromListOfEntitiesOrNull("Cx04", cx04s, lambda{|item| PolyFunctions::toString(item) })
            return cx04 if cx04
        end
        description = LucilleCore::askQuestionAnswerAsString("You are creating a new one, description (empty to abort): ")
        return nil if description == ""
        # In this case we are not issuing a new item to storage because they are pure data
        {
            "uuid"        => SecureRandom.hex,
            "mikuType"    => "Cx04",
            "description" => description,
            "unixtime"    => Time.new.to_f
        }
    end

    # Cx04::items(cx04)
    def self.items(cx04)
        Listing::items()
            .select{|item| item["cx04"] and item["cx04"]["uuid"] == cx04["uuid"] }
    end

end
