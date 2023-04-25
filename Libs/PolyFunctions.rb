class PolyFunctions

    # PolyFunctions::itemsToBankingAccounts(item)
    def self.itemsToBankingAccounts(item)

        accounts = []

        accounts << {
            "description" => "self: #{item["mikuType"]}",
            "number"      => item["uuid"]
        }

        if item["engine"] then
            accounts << {
                "description" => "self's engine",
                "number"      => item["engine"]["uuid"]
            }
            accounts << {
                "description" => "self's engine capsule",
                "number"      => item["engine"]["capsule"]
            }
        end

        if item["cliqueuuid"] then
            clique = N3Objects::getOrNull(item["cliqueuuid"])
            if clique then
                accounts = accounts + PolyFunctions::itemsToBankingAccounts(clique)
            end
        end

        if item["boarduuid"] then
            board = NxBoards::getItemOfNull(item["boarduuid"])
            if board then
                accounts = accounts + PolyFunctions::itemsToBankingAccounts(board)
            end
        end

        if item["mikuType"] == "NxTask" then
            accounts << {
                "description" => nil,
                "number"      => "34c37c3e-d9b8-41c7-a122-ddd1cb85ddbc" # NxTask Performance
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
        if item["mikuType"] == "LambdX1" then
            return "(lambda) #{item["announce"]}"
        end
        if item["mikuType"] == "NxAnniversary" then
            return Anniversaries::toString(item)
        end
        if item["mikuType"] == "NxBoard" then
            return NxBoards::toString(item)
        end
        if item["mikuType"] == "NxDrop" then
            return NxDrops::toString(item)
        end
        if item["mikuType"] == "NxFloat" then
            return NxFloats::toString(item)
        end
        if item["mikuType"] == "NxFire" then
            return NxFires::toString(item)
        end
        if item["mikuType"] == "NxClique" then
            return NxCliques::toString(item)
        end
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item)
        end
        if item["mikuType"] == "NxTask" then
            return NxTasks::toString(item)
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

    # PolyFunctions::isEssentiallyActive(item)
    def self.isEssentiallyActive(item)
        if item["mikuType"] == "NxBoard" then
            return NxBoards::isEssentiallyActive(item)
        end
        if item["mikuType"] == "NxClique" then
            return NxCliques::isEssentiallyActive(item)
        end
        NxBalls::itemIsRunning(item)
    end
end
