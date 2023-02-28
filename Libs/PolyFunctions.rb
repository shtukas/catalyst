class PolyFunctions

    # PolyFunctions::itemsToBankingAccounts(item)
    def self.itemsToBankingAccounts(item)
        accounts = []

        accounts << {
            "description" => "self",
            "number"      => item["uuid"]
        }

        if item["mikuType"] == "NxBoard" then
            accounts << {
                "description" => "capsule: #{item["capsule"]}",
                "number"      => item["capsule"]
            }
            return accounts
        end

        if item["mikuType"] == "NxHead" and item["boarduuid"] then
            board = NxBoards::getOrNull(item["boarduuid"])
            accounts << {
                "description" => "board: #{board["description"]}",
                "number"      => item["boarduuid"]
            }
            accounts << {
                "description" => "capsule: #{board["capsule"]}",
                "number"      => board["capsule"]
            }
            return accounts
        end

        if item["mikuType"] == "NxHead" and item["boarduuid"].nil? then
            accounts << {
                "description" => "scheduler1: head",
                "number"      => "cfad053c-bb83-4728-a3c5-4fb357845fd9"
            }
            return accounts
        end

        board = N2KVStore::getOrNull("BoardsAndItems:#{item["uuid"]}")
        if board then
            accounts << {
                "description" => "board: #{board["description"]}",
                "number"      => item["boarduuid"]
            }
            accounts << {
                "description" => "capsule: #{board["capsule"]}",
                "number"      => board["capsule"]
            }
        end

        # scheduler1 "d36d653e-80e0-4141-b9ff-f26197bbce2b" monitors Waves::leisureItems(nil) which are exactly the Wave priority ns:leisure items
        if item["mikuType"] == "Wave" and item["priority"] == "ns:leisure" then
            accounts << {
                "description" => "scheduler1: wave/leisure",
                "number"      => "d36d653e-80e0-4141-b9ff-f26197bbce2b"
            }
        end

        # scheduler1 "5b0347b2-8a97-4578-820e-f21baf7af7eb" monitors NxProjects
        if item["mikuType"] == "NxProject" then
            accounts << {
                "description" => "scheduler1: projects",
                "number"      => "5b0347b2-8a97-4578-820e-f21baf7af7eb"
            }
        end

        accounts
    end

    # PolyFunctions::toString(item)
    def self.toString(item)
        if item["mikuType"] == "LambdX1" then
            return "(lambda) #{item["announce"]}"
        end
        if item["mikuType"] == "NxAnniversary" then
            return Anniversaries::toString(item)
        end
        if item["mikuType"] == "NxBoard" then
            return NxBoards::toString(item)
        end
        if item["mikuType"] == "NxBoardTail" then
            return NxBoardTails::toString(item)
        end
        if item["mikuType"] == "NxFloat" then
            return NxFloats::toString(item)
        end
        if item["mikuType"] == "NxOpenCycles" then
            return item["description"]
        end
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item)
        end
        if item["mikuType"] == "NxProject" then
            return NxProjects::toString(item)
        end
        if item["mikuType"] == "NxTail" then
            return NxTails::toString(item)
        end
        if item["mikuType"] == "NxHead" then
            return NxHeads::toString(item)
        end
        if item["mikuType"] == "NxTop" then
            return NxTops::toString(item)
        end
        if item["mikuType"] == "TxManualCountDown" then
            return "(countdown) #{item["description"]}: #{item["counter"]}"
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        puts "I do not know how to PolyFunctions::toString(#{JSON.pretty_generate(item)})"
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c)"
    end

    # PolyFunctions::toStringForSearchListing(item)
    def self.toStringForSearchListing(item)
        if item["mikuType"] == "Wave" then
            return Waves::toStringForSearch(item)
        end
        PolyFunctions::toString(item)
    end
end
