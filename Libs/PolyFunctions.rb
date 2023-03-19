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

        if item["mikuType"] == "NxCherryPick" then
            object = N3Objects::getOrNull(item["targetuuid"])
            PolyFunctions::itemsToBankingAccounts(object).each{|account|
                accounts << account
            }
        end

        if item["mikuType"] == "NxUltraPick" then
            object = N3Objects::getOrNull(item["targetuuid"])
            PolyFunctions::itemsToBankingAccounts(object).each{|account|
                accounts << account
            }
        end

        # We now need to remove redundancies because we could have a board coming from
        # both the NxCherryPick or UltraPick and coming from the pinked item

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
        if item["mikuType"] == "NxCherryPick" then
            object = N3Objects::getOrNull(item["targetuuid"])
            if object.nil? then
                return "(cherry picked) object not found"
            end
            return "(cherry picked @ #{item["position"]}) #{PolyFunctions::toString(object)}#{BoardsAndItems::toStringSuffix(object)}"
        end
        if item["mikuType"] == "NxUltraPick" then
            object = N3Objects::getOrNull(item["targetuuid"])
            if object.nil? then
                return "(ultra picked) object not found"
            end
            return "(ultra picked @ #{item["position"]}) #{PolyFunctions::toString(object)}#{BoardsAndItems::toStringSuffix(object)}"
        end
        if item["mikuType"] == "NxFire" then
            return NxFires::toString(item)
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
        if item["mikuType"] == "NxTask" then
            return NxTasks::toString(item)
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
