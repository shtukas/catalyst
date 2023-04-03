
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
        hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        item = {
            "uuid"          => uuid,
            "mikuType"      => "NxProject",
            "unixtime"      => Time.new.to_i,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "field11"       => coredataref,
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

    # NxProjects::listingItems(board)
    def self.listingItems(board)
        NxProjects::items()
            .select{|item| BoardsAndItems::belongsToThisBoard2ForListingManagement(item, board) }
            .select{|item| DoNotShowUntil::isVisible(item) }
            .select{|item| NxProjects::completionRatio(item) < 1 }
    end

    # ---------------------------------------------------------
    # Ops

    # NxProjects::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = NxProjects::items()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", items, lambda{|item| NxProjects::toString(item) })
    end

    # NxProjects::timeManagement()
    def self.timeManagement()
        return if !Config::isPrimaryInstance()
        NxProjects::items().each{|project|

            if BankCore::getValue(project["capsule"]) > 1.5*project["hours"]*3600 and (Time.new.to_i - project["lastResetTime"]) >= 86400*7 then
                overflow = 0.5*project["hours"]*3600
                puts "I am about to smooth project: project: #{NxProjects::toString(project)}, overflow: #{(overflow.to_f/3600).round(2)} hours"
                LucilleCore::pressEnterToContinue()
                NxTimePromises::smooth_commit(project["capsule"], [project["uuid"], project["capsule"]], -overflow, 20)
                next
                # We need to next because this section would have changed the project
            end

            if BankCore::getValue(project["capsule"]) >= project["hours"]*3600 and (Time.new.to_i - project["lastResetTime"]) >= 86400*7 then
                puts "I am about to reset project: #{project["description"]}"
                puts "resetting project's capsule time commitment: project: #{NxProjects::toString(project)}, decrease by #{project["hours"]} hours"
                LucilleCore::pressEnterToContinue()
                BankCore::put(project["capsule"], -project["hours"]*3600)
                project["lastResetTime"] = Time.new.to_i
                puts JSON.pretty_generate(project)
                NxProjects::commit(project)
            end
        }
    end

    # NxProjects::program()
    def self.program()
        item = NxProjects::interactivelySelectOneOrNull()
        return if item.nil?
        if LucilleCore::askQuestionAnswerAsBoolean("start '#{PolyFunctions::toString(item).green}' ? ", true) then
            PolyActions::start(item)
        end
    end
end
