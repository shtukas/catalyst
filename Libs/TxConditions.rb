# encoding: UTF-8

class TxConditions

    # TxConditions::toString(txcondition)
    def self.toString(txcondition)
        "#{txcondition["name"]} (#{txcondition["status"]})"
    end

    # TxConditions::access(txcondition)
    def self.access(txcondition)
        l = lambda { 
            Cx11s::getItemsByConditionName(Items::items(), txcondition["name"])
                .select{|item| Listing::listable(item) }
        }
        Catalyst::program3(l)
    end

    # TxConditions::listingItems(items)
    def self.listingItems(items)
        Cx11s::collectDistinctCx11sFromItems(items)
            .select{|cx11| !cx11["status"] } # we only show the conditions that are not true
            .map{|cx11|
                {
                    "uuid"     => "8008772b-496a-4ede-97d6-1eb329f9e283:#{cx11["name"]}",
                    "mikuType" => "TxCondition",
                    "name"     => cx11["name"],
                    "status"   => cx11["status"]
                }
            }
    end
end
