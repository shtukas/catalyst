j# encoding: UTF-8

class TxFyres

    # TxFyres::items()
    def self.items()
        Librarian6ObjectsLocal::getObjectsByMikuType("TxFyre")
    end

    # TxFyres::itemsForUniverse(universe)
    def self.itemsForUniverse(universe)
        TxFyres::items()
            .select{|item| 
                objuniverse = ObjectUniverseMapping::getObjectUniverseMappingOrNull(item["uuid"])
                universe.nil? or objuniverse.nil? or (objuniverse == universe)
            }
    end

    # TxFyres::destroy(uuid)
    def self.destroy(uuid)
        Librarian6ObjectsLocal::destroy(uuid)
    end

    # --------------------------------------------------
    # TxFy36

    # TxFyres::getTxFy36ForTodayOrNull(uuid)
    def self.getTxFy36ForTodayOrNull(uuid)
        obj = XCache::getOrNull("c57f60cd-7d03-4d8f-a7e3-a420a7c136ce:#{uuid}:#{Utils::today()}")
        return nil if obj.nil?
        return JSON.parse(obj)
    end

    # TxFyres::setTxFy36ForToday(uuid, tx)
    def self.setTxFy36ForToday(uuid, tx)
        XCache::set("c57f60cd-7d03-4d8f-a7e3-a420a7c136ce:#{uuid}:#{Utils::today()}", JSON.generate(tx))
    end

    # TxFyres::interactivelyMakeTxFy36()
    def self.interactivelyMakeTxFy36()
        modes = [
            "time commitment for today (default)",
            "done for today"
        ]
        mode = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", modes)
        if mode.nil? or mode == "time commitment for today (default)" then
            hours = LucilleCore::askQuestionAnswerAsString("hours (default to 1) : ")
            if hours == "" then
                hours = "1"
            end
            hours = hours.to_f
            return {
                "status" => "time-commitment",
                "hours"  => hours
            }
        end
        if mode == "done for today" then
            return {
                "status" => "done"
            }
        end

        raise "()"
    end

    # TxFyres::ensureTxFy36sForUniverseForToday(universe)
    def self.ensureTxFy36sForUniverseForToday(universe)
        return if TxFyres::itemsForUniverse(universe).all?{|item| TxFyres::getTxFy36ForTodayOrNull(item["uuid"]) }
        puts "--------------------------------------"
        items = TxFyres::itemsForUniverse(universe)
        item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| "#{item["description"]} : #{TxFyres::getTxFy36ForTodayOrNull(item["uuid"]).to_s.green}" })
        if item.nil? then
            return TxFyres::ensureTxFy36sForUniverseForToday(universe)
        end
        puts "#{item["description"]}"
        tx = TxFyres::interactivelyMakeTxFy36()
        TxFyres::setTxFy36ForToday(item["uuid"], tx)
        TxFyres::ensureTxFy36sForUniverseForToday(universe)
    end

    # --------------------------------------------------
    # Makers

    # TxFyres::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems())
        return nil if nx111.nil?

        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        universe   = Multiverse::interactivelySelectUniverse()

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxFyre",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "iam2"        => nx111
        }
        Librarian6ObjectsLocal::commit(item)
        ObjectUniverseMapping::setObjectUniverseMapping(uuid, universe)
        item
    end

    # TxFyres::interactivelyIssueItemUsingInboxLocation(location)
    def self.interactivelyIssueItemUsingInboxLocation(location)
        uuid        = SecureRandom.uuid
        description = Inbox::interactivelyDecideBestDescriptionForLocation(location)
        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601

        rootnhash   = AionCore::commitLocationReturnHash(InfinityElizabeth_DriveWithLocalXCache.new(), location)
        nx111 = {
            "uuid"      => SecureRandom.uuid,
            "type"      => "aion-point",
            "rootnhash" => rootnhash
        }

        universe    = Multiverse::interactivelySelectUniverse()

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxFyre",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "iam2"        => nx111
        }
        Librarian6ObjectsLocal::commit(item)
        ObjectUniverseMapping::setObjectUniverseMapping(uuid, universe)
        item
    end

    # --------------------------------------------------
    # toString

    # TxFyres::toString(item)
    def self.toString(item)
        "(fyre) #{item["description"]} (#{item["iam2"]["type"]})"
    end

    # TxFyres::toStringForSection2(item)
    def self.toStringForSection2(item)
        "(fyre) #{item["description"]} (#{item["iam2"]["type"]}) #{TxFyres::getTxFy36ForTodayOrNull(item["uuid"])}"
    end

    # TxFyres::toStringForNS16(item, rt)
    def self.toStringForNS16(item, rt)
        txFy36 = TxFyres::getTxFy36ForTodayOrNull(item["uuid"])
        if txFy36 then
            "(fyre) #{item["description"]} (#{item["iam2"]["type"]}) (#{"%4.2f" % rt} of #{txFy36["hours"]} hours)"
        else
            "(fyre) #{item["description"]} (#{item["iam2"]["type"]})"
        end
    end

    # TxFyres::toStringForNS19(item)
    def self.toStringForNS19(item)
        "(fyre) #{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxFyres::complete(item)
    def self.complete(item)
        TxFyres::destroy(item["uuid"])
    end

    # TxFyres::landing(item)
    def self.landing(item)

        loop {

            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            puts TxFyres::toString(item).green
            puts "uuid: #{uuid}".yellow
            puts "iam2: #{item["iam2"]}".yellow
            puts "rt: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow
            puts "TxFy36: #{TxFyres::getTxFy36ForTodayOrNull(uuid)}".yellow

            TxAttachments::itemsForOwner(uuid).each{|attachment|
                indx = store.register(attachment, false)
                puts "[#{indx.to_s.ljust(3)}] #{TxAttachments::toString(attachment)}" 
            }

            puts "access | start | <datecode> | description | iam | attachment | show json | universe | transmute | >nyx | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                Nx111::accessIamData_PossibleMutationInStorage_ExportsAreTx46Compatible(item)
                next
            end

            if Interpreting::match("start", command) then
                if !NxBallsService::isRunning(item["uuid"]) then
                    NxBallsService::issue(item["uuid"], item["description"], [item["uuid"]])
                end
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(item["description"]).strip
                next if description == ""
                item["description"] = description
                Librarian6ObjectsLocal::commit(item)
                next
            end

            if Interpreting::match("iam2", command) then
                nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems())
                next if nx111.nil?
                puts JSON.pretty_generate(nx111)
                if LucilleCore::askQuestionAnswerAsBoolean("confirm change ? ") then
                    item["iam2"] = nx111
                    Librarian6ObjectsLocal::commit(item)
                end
            end

            if Interpreting::match("attachment", command) then
                TxAttachments::interactivelyCreateNewOrNullForOwner(item["uuid"])
                next
            end

            if Interpreting::match("transmute", command) then
                Transmutation::transmutation2(item, "TxFyre")
                break
            end

            if Interpreting::match("universe", command) then
                ObjectUniverseMapping::interactivelySetObjectUniverseMapping(item["uuid"])
                next
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                break
            end

            if Interpreting::match(">nyx", command) then
                ix = {
                    "uuid"        => SecureRandom.uuid,
                    "mikuType"    => "Nx100",
                    "unixtime"    => item["unixtime"],
                    "datetime"    => item["datetime"],
                    "description" => item["description"],
                    "iam2"        => item["iam2"],
                    "flavour"     => Nx102Flavor::interactivelyCreateNewFlavour()
                }
                Librarian6ObjectsLocal::commit(ix)
                LxAction::action("landing", ix)

                TxFyres::complete(item)
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxFyres::toString(item)}' ? ", true) then
                    TxFyres::complete(item)
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxFyres::toString(item)}' ? ", true) then
                    TxFyres::complete(item)
                    break
                end
                next
            end
        }
    end

    # TxFyres::dive()
    def self.dive()
        loop {
            system("clear")
            items = TxFyres::items().sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("fyre", items, lambda{|item| TxFyres::toString(item) })
            break if item.nil?
            TxFyres::landing(item)
        }
    end

    # --------------------------------------------------
    # nx16s

    # TxFyres::section2(universe)
    def self.section2(universe)
        TxFyres::itemsForUniverse(universe)
            .map{|item|
                uuid = item["uuid"]
                announce = toStringForSection2(item)
                rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
                {
                    "uuid"     => uuid,
                    "mikuType" => "NS16:TxFyre",
                    "announce" => announce,
                    "height"   => 1,
                    "TxFyre"   => item,
                    "rt"       => rt,
                    "unixtime" => item["unixtime"]
                }
            }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # TxFyres::section3(universe)
    def self.section3(universe)
        TxFyres::ensureTxFy36sForUniverseForToday(universe)

        txFy36Filter = lambda {|item|
            tx = TxFyres::getTxFy36ForTodayOrNull(item["uuid"])
            (tx["status"] == "time-commitment") and (BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]) < tx["hours"])
        }

        ns16s = TxFyres::itemsForUniverse(universe)
            .select{|item| txFy36Filter.call(item) }
            .map{|item| 
                uuid = item["uuid"]
                rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
                announce = TxFyres::toStringForNS16(item, rt).gsub("(0.00)", "      ")
                {
                    "uuid"     => uuid,
                    "mikuType" => "NS16:TxFyre",
                    "announce" => announce,
                    "height"   => nil,
                    "TxFyre"   => item,
                    "rt"       => rt
                }
            }
            .sort{|i1, i2| i1["rt"] <=> i2["rt"] }

        Heights::markSequenceOfNS16sWithDecreasingHeights("f0047af0", ns16s)
    end

    # --------------------------------------------------

    # TxFyres::nx20s()
    def self.nx20s()
        TxFyres::items().map{|item|
            {
                "announce" => TxFyres::toStringForNS19(item),
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
