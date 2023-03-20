
class NxProjects

    # --------------------------------------------
    # IO

    # NxProjects::items()
    def self.items()
        N3Objects::getMikuType("NxProject")
    end

    # NxProjects::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        N3Objects::getOrNull(uuid)
    end

    # NxProjects::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # --------------------------------------------
    # Makers

    # NxProjects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
        item = {
            "uuid"          => uuid,
            "mikuType"      => "NxProject",
            "unixtime"      => Time.new.to_i,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "hours"         => hours,
            "lastResetTime" => 0,
            "capsule"       => SecureRandom.hex
        }
        NxProjects::commit(item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # NxProjects::toString(item)
    def self.toString(item)
        # we use the Board's ow bank account to compute the day completion ratio
        dayTheoreticalInHours = item["hours"].to_f/5
        todayDoneInHours = BankCore::getValueAtDate(item["uuid"], CommonUtils::today()).to_f/3600
        completionRatio = NxProjects::completionRatio(item)
        str0 = "(day: #{("%5.2f" % todayDoneInHours).to_s} of #{"%5.2f" % dayTheoreticalInHours}, cr: #{("%4.2f" % completionRatio).to_s})"

        # but we use the capsule value for the target computations
        capsuleValueInHours = BankCore::getValue(item["capsule"]).to_f/3600
        str1 = "(done #{("%5.2f" % capsuleValueInHours).to_s} out of #{item["hours"]})"

        hasReachedObjective = capsuleValueInHours >= item["hours"]
        timeSinceResetInDays = (Time.new.to_i - item["lastResetTime"]).to_f/86400
        itHassBeenAWeek = timeSinceResetInDays >= 7

        if hasReachedObjective and itHassBeenAWeek then
            str2 = "(awaiting data management)"
        end

        if hasReachedObjective and !itHassBeenAWeek then
            str2 = "(objective met, #{(7 - timeSinceResetInDays).round(2)} days before reset)"
        end

        if !hasReachedObjective and !itHassBeenAWeek then
            str2 = "(#{(7 - timeSinceResetInDays).round(2)} days left in period)"
        end

        if !hasReachedObjective and itHassBeenAWeek then
            str2 = "(late by #{(timeSinceResetInDays-7).round(2)} days)"
        end

        "#{"(prjct)".green} #{item["description"].ljust(8)} #{str0} #{str1} #{str2}"
    end

    # NxProjects::rtTarget(item)
    def self.rtTarget(item)
        item["hours"].to_f/5 # Hopefully 5 days
    end

    # NxProjects::completionRatio(item)
    def self.completionRatio(item)
        BankUtils::recoveredAverageHoursPerDay(item["uuid"]).to_f/NxProjects::rtTarget(item)
    end

    # NxProjects::listingItems(item)
    def self.listingItems(item)
        NxProjects::items()
            .select{|item| BoardsAndItems::belongsToThisBoard(item, item) }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| NxProjects::completionRatio(item) < 1 }
    end

    # ---------------------------------------------------------
    # Ops

    # NxProjects::timeManagement()
    def self.timeManagement()
        return if !Config::isPrimaryInstance()
        NxProjects::items().each{|item|

            # If at time of reset the board's capsule is over flowing, meaning
            # its positive value is more than 50% of the time commitment for the board,
            # meaning we did more than 100% of time commitment then we issue NxTimeCapsules
            if BankCore::getValue(item["capsule"]) > 1.5*item["hours"]*3600 and (Time.new.to_i - item["lastResetTime"]) >= 86400*7 then
                overflow = 0.5*item["hours"]*3600
                puts "I am about to smooth board: board: #{NxProjects::toString(item)}, overflow: #{(overflow.to_f/3600).round(2)} hours"
                LucilleCore::pressEnterToContinue()
                NxTimeCapsules::smooth_commit(item["capsule"], -overflow, 20)
                next
                # We need to next because this section would have changed the item
            end

            # We perform a reset, when we have filled the capsule (not to be confused with NxTimeCapsule)
            # and it's been more than a week. This last condition allows enjoying free time if the capsule was filled quickly.
            if BankCore::getValue(item["capsule"]) >= item["hours"]*3600 and (Time.new.to_i - item["lastResetTime"]) >= 86400*7 then
                puts "I am about to reset board: #{item["description"]}"
                puts "resetting board's capsule time commitment: board: #{NxProjects::toString(item)}, decrease by #{item["hours"]} hours"
                LucilleCore::pressEnterToContinue()
                BankCore::put(item["capsule"], -item["hours"]*3600)
                item["lastResetTime"] = Time.new.to_i
                puts JSON.pretty_generate(item)
                NxProjects::commit(item)
            end
        }
    end

    # NxProjects::informationDisplay(store, boarduuid) 
    def self.informationDisplay(store, boarduuid)
        board = NxProjects::getItemOfNull(boarduuid)
        if board.nil? then
            puts "NxProjects::informationDisplay(boarduuid), board not found"
            exit
        end
        store.register(board, false)
        line = "(#{store.prefixString()}) #{NxProjects::toString(board)}#{DoNotShowUntil::suffixString(board)}#{NxBalls::nxballSuffixStatusIfRelevant(board)}"
        if NxBalls::itemIsRunning(board) or NxBalls::itemIsPaused(board) then
            line = line.green
        end
        puts line
    end
end
