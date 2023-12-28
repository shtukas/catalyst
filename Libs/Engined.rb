

class Engined

    # Engined::listingItems()
    def self.listingItems()
        items0 = (lambda {
            items = CacheWS::getOrNull("47FDDD68-0655-494E-996C-350BE8654807")
            return items if items
            items = Cubes::mikuType("NxCruiser")
                        .select{|ship| ship["engine-0020"]["type"] == "booster" }
                        .select{|ship| ship["engine-0020"]["endunixtime"] <= Time.new.to_i } # expired boosters

            signals1 = items.map{|item| "item-has-been-modified:#{item["uuid"]}" }
            signals2 = items.map{|item| "bank-account-has-been-updated:#{item["uuid"]}" }
            signals  = signals1 + signals2
            CacheWS::set("47FDDD68-0655-494E-996C-350BE8654807", items, signals)
            items
        }).call()

        items1 = (lambda {
            items = CacheWS::getOrNull("8EF6CD96-72CF-45CB-956C-DF2B510CA8A1")
            return items if items
            items = Cubes::mikuType("NxCruiser")
                        .select{|ship| ship["engine-0020"]["type"] == "booster" }
                        .select{|ship| NxCruisers::dayCompletionRatio(ship) < 1 }
                        .sort_by{|ship| NxCruisers::dayCompletionRatio(ship) }
            signals1 = items.map{|item| "item-has-been-modified:#{item["uuid"]}" }
            signals2 = items.map{|item| "bank-account-has-been-updated:#{item["uuid"]}" }
            signals  = signals1 + signals2
            CacheWS::set("8EF6CD96-72CF-45CB-956C-DF2B510CA8A1", items, signals)
            items
        }).call()

        items2 = (lambda {
            items = CacheWS::getOrNull("55ba76d4-ba8d-445c-a833-5da2b6c73ce9")
            return items if items

            items = Cubes::mikuType("NxTask")
                        .select{|item| item["engine-0020"] }
                        .select{|ship| NxCruisers::dayCompletionRatio(ship) < 1 }
                        .sort_by{|ship| NxCruisers::dayCompletionRatio(ship) }

            signals1 = items.map{|item| "item-has-been-modified:#{item["uuid"]}" }
            signals2 = items.map{|item| "bank-account-has-been-updated:#{item["uuid"]}" }
            signals  = signals1 + signals2
            CacheWS::set("55ba76d4-ba8d-445c-a833-5da2b6c73ce9", items, signals)
            items
        }).call()

        items3 = (lambda {
            items = CacheWS::getOrNull("36E64A0A-D4DD-4AF7-B9ED-303602E57781")
            return items if items

            items = NxCruisers::shipsInRecursiveDescent()
                .select{|ship| NxCruisers::dayCompletionRatio(ship) < 1 }
                .sort_by{|ship| NxCruisers::dayCompletionRatio(ship) }

            signals1 = items.map{|item| "item-has-been-modified:#{item["uuid"]}" }
            signals2 = items.map{|item| "bank-account-has-been-updated:#{item["uuid"]}" }
            signals  = signals1 + signals2
            CacheWS::set("36E64A0A-D4DD-4AF7-B9ED-303602E57781", items, signals)
            items
        }).call()

        items0 + items1 + items2 + items3



    end
end
