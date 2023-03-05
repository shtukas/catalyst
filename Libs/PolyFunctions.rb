class PolyFunctions

    # PolyFunctions::itemsToBankingAccounts(item)
    def self.itemsToBankingAccounts(item)

        accounts = []

        accounts << {
            "description" => "self",
            "number"      => item["uuid"]
        }

        if item["mikuType"] == "NxCherryPick" then
            object = N3Objects::getOrNull(item["targetuuid"])
            if object.nil? then
                return accounts
            end
            return accounts + PolyFunctions::itemsToBankingAccounts(object)
        end

        if item["mikuType"] == "NxBoard" then
            accounts << {
                "description" => "capsule: #{item["capsule"]}",
                "number"      => item["capsule"]
            }
        end

        if item["boarduuid"] then
            board = NxBoards::getOrNull(item["boarduuid"])
            accounts << {
                "description" => "board: #{board["description"]}",
                "number"      => item["boarduuid"]
            }
            accounts << {
                "description" => "capsule: #{board["capsule"]}",
                "number"      => board["capsule"]
            }
        end

        if item["mikuType"] == "NxTail" and item["boarduuid"].nil? then
            accounts << {
                "description" => "scheduler1: boardless NxTail",
                "number"      => "cfad053c-bb83-4728-a3c5-4fb357845fd9"
            }
        end

        if item["mikuType"] == "Wave" and !item["priority"] then
            accounts << {
                "description" => "scheduler1: low priority Wave",
                "number"      => "d36d653e-80e0-4141-b9ff-f26197bbce2b"
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
        if item["mikuType"] == "NxCherryPick" then
            object = N3Objects::getOrNull(item["targetuuid"])
            if object.nil? then
                return "(cherry picked) object not found"
            end
            return "(cherry picked @ #{item["position"]}) #{PolyFunctions::toString(object)}"
        end
        if item["mikuType"] == "NxLine" then
            return "(line) #{item["description"]}"
        end
        if item["mikuType"] == "NxOrbital" then
            return NxOrbitals::toString(item)
        end
        if item["mikuType"] == "NxOpenCycles" then
            return item["description"]
        end
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item)
        end
        if item["mikuType"] == "NxTail" then
            return NxTails::toString(item)
        end
        if item["mikuType"] == "NxToday" then
            return NxTodays::toString(item)
        end
        if item["mikuType"] == "Scheduler1Listing" then
            return item["announce"]
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
end
