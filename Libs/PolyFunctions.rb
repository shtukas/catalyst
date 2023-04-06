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
        end

        if item["boarduuid"] then
            board = NxBoards::getItemOfNull(item["boarduuid"])
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
        end

        if item["mikuType"] == "NxTask" then
            accounts << {
                "description" => nil,
                "number"      => "34c37c3e-d9b8-41c7-a122-ddd1cb85ddbc" # NxTask General
            }
        end

        accounts.reduce([]){|as, account|
            if as.map{|a| a["number"] }.include?(account["number"]) then
                as
            else
                as + [account]
            end

        }
    end

    # PolyFunctions::toString(item)
    def self.toString(item)
        if item["mikuType"] == "DesktopTx1" then
            return item["announce"]
        end
        if item["mikuType"] == "DeviceBackup" then
            return item["announce"]
        end
        if item["mikuType"] == "NxOpenCycle" then
            return "(open cycle) #{item["name"]}"
        end
        if item["mikuType"] == "LambdX1" then
            return "(lambda) #{item["announce"]}"
        end
        if item["mikuType"] == "NxAnniversary" then
            return Anniversaries::toString(item)
        end
        if item["mikuType"] == "NxBoard" then
            return NxBoards::toString(item)
        end
        if item["mikuType"] == "NxFire" then
            return NxFires::toString(item)
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
        if item["mikuType"] == "NxTask" then
            return NxTasks::toString(item)
        end
        if item["mikuType"] == "NxProject" then
            return NxProjects::toString(item)
        end
        if item["mikuType"] == "Scheduler1Listing" then
            return item["announce"]
        end
        if item["mikuType"] == "PhysicalTarget" then
            return PhysicalTargets::toString(item)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        puts "I do not know how to PolyFunctions::toString(#{JSON.pretty_generate(item)})"
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c)"
    end

    # PolyFunctions::interactivelySelectBoardAndPositionForTask()
    def self.interactivelySelectBoardAndPositionForTask() # [boarduuid, position]
        board = NxBoards::interactivelySelectOneOrNull()
        if board then
            [board["uuid"], NxBoards::interactivelyDecideNewBoardPosition(board)]
        else
            [nil, NxTasks::thatPosition()]
        end
    end
end
