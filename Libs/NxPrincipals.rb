class NxPrincipals

    # ---------------------------------------------------------
    # IO
    # ---------------------------------------------------------

    # NxPrincipals::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        Solingen::getItemOrNull(uuid)
    end

    # NxPrincipals::getItemFailIfMissing(uuid)
    def self.getItemFailIfMissing(uuid)
        board = NxPrincipals::getItemOrNull(uuid)
        return board if board
        raise "looking for a board that should exists. item: #{JSON.pretty_generate(item)}"
    end

    # ---------------------------------------------------------
    # Makers
    # ---------------------------------------------------------

    # This can only be called from nslog
    # NxPrincipals::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        engine = TxEngines::interactivelyMakeEngineOrDefault()
        Solingen::init("NxPrincipal", uuid)
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "engine", engine)
        Solingen::getItemOrNull(uuid)
    end

    # ---------------------------------------------------------
    # Data
    # ---------------------------------------------------------

    # NxPrincipals::gaiauuid()
    def self.gaiauuid()
        "0dbef57d-f1b3-4629-805a-00722a3c172a"
    end

    # NxPrincipals::toString(item)
    def self.toString(item)
        "- #{item["description"]} #{TxEngines::toString(item["engine"])}"
    end

    # NxPrincipals::itemsOrdered()
    def self.itemsOrdered()
        Solingen::mikuTypeItems("NxPrincipal")
            .sort_by{|item| TxEngines::listingCompletionRatio(item["engine"]) }
    end

    # NxPrincipals::threads(principal)
    def self.threads(principal)
        Solingen::mikuTypeItems("NxThread").select{|thread| thread["parentuuid"] == principal["uuid"] }
    end

    # ---------------------------------------------------------
    # Selectors
    # ---------------------------------------------------------

    # NxPrincipals::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = NxPrincipals::itemsOrdered()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("board", items, lambda{|item| NxPrincipals::toString(item) })
    end

    # NxPrincipals::interactivelySelectPrincipalUUIDOrNull()
    def self.interactivelySelectPrincipalUUIDOrNull()
        items = NxPrincipals::itemsOrdered()
        board = LucilleCore::selectEntityFromListOfEntitiesOrNull("board", items, lambda{|item| NxPrincipals::toString(item) })
        return nil if board.nil?
        board["uuid"]
    end

    # NxPrincipals::interactivelySelectOnePrincipal()
    def self.interactivelySelectOnePrincipal()
        loop {
            item = NxPrincipals::interactivelySelectOneOrNull()
            return item if item
        }
    end

    # ---------------------------------------------------------
    # Ops
    # ---------------------------------------------------------

    # NxPrincipals::dataMaintenance()
    def self.dataMaintenance()
        Solingen::mikuTypeItems("NxPrincipal").each{|board|
            engine2 = TxEngines::engineCarrierMaintenance(board)
            if engine2 then
                Solingen::setAttribute2(board["uuid"], "engine", engine2)
            end
        }
    end

    # ---------------------------------------------------------
    # Programs
    # ---------------------------------------------------------

    # NxPrincipals::program1(principal)
    def self.program1(principal)
        loop {
            thread = LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", NxPrincipals::threads(principal), lambda{|item| NxThreads::toString(item) })
            return if thread.nil?
            NxThreads::program(thread)
        }
    end

    # NxPrincipals::program2(principal)
    def self.program2(principal)
        loop {
            principal = NxPrincipals::getItemOrNull(principal["uuid"])
            return if principal.nil?
            puts NxPrincipals::toString(principal)
            actions = ["program(principal)", "start", "add time"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            break if action.nil?
            if action == "start" then
                PolyActions::start(principal)
            end
            if action == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                PolyActions::addTimeToItem(principal, timeInHours*3600)
            end
            if action == "program(principal)" then
                NxPrincipals::program1(principal)
            end
        }
    end

    # NxPrincipals::program3()
    def self.program3()
        loop {
            principal = NxPrincipals::interactivelySelectOneOrNull()
            return if principal.nil?
            NxPrincipals::program2(principal)
        }
    end
end
