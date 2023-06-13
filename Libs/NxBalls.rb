
class NxBalls

    # NxBalls::repository()
    def self.repository()
        "#{Config::pathToGalaxy()}/DataHub/catalyst/NxBalls"
    end

    # ---------------------------------
    # IO

    # NxBalls::all()
    def self.all()
        LucilleCore::locationsAtFolder(NxBalls::repository())
            .select{|filepath| filepath[-5, 5] == ".ball" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxBalls::commitBall(item, nxball)
    def self.commitBall(item, nxball)
        filepath = "#{NxBalls::repository()}/#{item["uuid"]}.ball"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(nxball)) }
    end

    # NxBalls::issueNxBall(item, accounts)
    def self.issueNxBall(item, accounts)
        nxball = {
            "itemuuid"       => item["uuid"],
            "instance"       => Config::thisInstanceId(),
            "type"           => "running",
            "startunixtime"  => Time.new.to_i,
            "accounts"       => accounts,
            "sequencestart"  => nil
        }
        NxBalls::commitBall(item, nxball)
    end

    # NxBalls::getNxBallOrNull(item)
    def self.getNxBallOrNull(item)
        filepath = "#{NxBalls::repository()}/#{item["uuid"]}.ball"
        return nil if !File.exist?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxBalls::destroyNxBall(item)
    def self.destroyNxBall(item)
        filepath = "#{NxBalls::repository()}/#{item["uuid"]}.ball"
        return nil if !File.exist?(filepath)
        FileUtils.rm(filepath)
    end

    # ---------------------------------
    # Statuses

    # NxBalls::itemIsRunning(item)
    # returns false if the item doesn't have a nxball or is paused
    def self.itemIsRunning(item)
        nxball = NxBalls::getNxBallOrNull(item)
        return false if nxball.nil?
        nxball["type"] == "running"
    end

    # NxBalls::itemIsPaused(item)
    def self.itemIsPaused(item)
        nxball = NxBalls::getNxBallOrNull(item)
        return false if nxball.nil?
        nxball["type"] == "paused"
    end

    # NxBalls::itemIsActive(item)
    def self.itemIsActive(item)
        NxBalls::itemIsRunning(item) or NxBalls::itemIsPaused(item)
    end

    # NxBalls::itemIsBallFree(item)
    def self.itemIsBallFree(item)
        NxBalls::getNxBallOrNull(item).nil?
    end

    # ---------------------------------
    # Ops

    # NxBalls::start(item)
    def self.start(item)
        return if !NxBalls::itemIsBallFree(item)
        accounts = PolyFunctions::itemsToBankingAccounts(item)
        accounts.each{|account|
            puts "starting account: (#{account["description"]}, #{account["number"]})"
        }
        NxBalls::issueNxBall(item, accounts)
    end

    # NxBalls::stop(item)
    def self.stop(item)
        if NxBalls::itemIsBallFree(item) then
            NxBalls::destroyNxBall(item)
            return
        end
        if NxBalls::itemIsPaused(item) then
            puts "stopping paused item, nothing to do..."
            NxBalls::destroyNxBall(item)
            return
        end
        nxball = NxBalls::getNxBallOrNull(item)
        if nxball["instance"] != Config::thisInstanceId() then
            puts "This ball wasn't created here, was created at #{nxball["instance"]}."
            return if !LucilleCore::askQuestionAnswerAsBoolean("Confirm stop operation: ")
        end
        timespanInSeconds = Time.new.to_i - nxball["startunixtime"]
        if item["mikuType"] == "NxTask" then
            timespanInSeconds = [timespanInSeconds, 300].max # we want all tasks to contribute to at least 5 mins
        end
        nxball["accounts"].each{|account|
            puts "adding #{timespanInSeconds} seconds to account: (#{account["description"]}, #{account["number"]})"
            Bank::put(account["number"], timespanInSeconds)
        }
        NxBalls::destroyNxBall(item)
    end

    # NxBalls::pause(item)
    def self.pause(item)
        return if !NxBalls::itemIsRunning(item)
        nxball = NxBalls::getNxBallOrNull(item)
        if nxball["instance"] != Config::thisInstanceId() then
            puts "This ball wasn't created here, was created at #{nxball["instance"]}."
            return if !LucilleCore::askQuestionAnswerAsBoolean("Confirm pause operation: ")
        end
        timespanInSeconds = Time.new.to_i - nxball["startunixtime"]
        nxball["accounts"].each{|account|
            puts "adding #{timespanInSeconds} seconds to account: (#{account["description"]}, #{account["number"]})"
            Bank::put(account["number"], timespanInSeconds)
        }
        nxball["type"] = "paused"
        nxball["sequencestart"] = nxball["sequencestart"] || Time.new.to_i
        NxBalls::commitBall(item, nxball)
    end

    # NxBalls::pursue(item)
    def self.pursue(item)
        if NxBalls::itemIsRunning(item) then
            # We do this to commit the time to the bank
            NxBalls::pause(item)
        end
        if NxBalls::itemIsPaused(item) then
            nxball = NxBalls::getNxBallOrNull(item)
            nxball["type"]          = "running"
            nxball["startunixtime"] = Time.new.to_i
            nxball["sequencestart"] = nxball["sequencestart"] || nxball["startunixtime"]
            NxBalls::commitBall(item, nxball)
        end
    end

    # ---------------------------------
    # Data

    # NxBalls::runningTime(item)
    def self.runningTime(item)
        return 0 if !NxBalls::itemIsRunning(item)
        nxball = NxBalls::getNxBallOrNull(item)
        return 0 if nxball.nil?
        Time.new.to_i - nxball["startunixtime"]
    end

    # NxBalls::nxBallToString(nxball)
    def self.nxBallToString(nxball)
        accounts = nxball["accounts"].map{|a| a["description"]}.compact.join(", ")
        if nxball["type"] == "running" and nxball["sequencestart"] then
            return "(nxball: running for #{((Time.new.to_i - nxball["startunixtime"]).to_f/3600).round(2)} hours, sequence started #{((Time.new.to_i - nxball["sequencestart"]).to_f/3600).round(2)} hours ago, #{accounts})"
        end
        if nxball["type"] == "running" then
            return "(nxball: running for #{((Time.new.to_i - nxball["startunixtime"]).to_f/3600).round(2)} hours, #{accounts})"
        end
        if nxball["type"] == "paused" then
            return "(nxball: paused) (#{accounts})"
        end
        raise "(error: 93abde39-fd9d-4aa5-8e56-d09cf47a0f46) nxball: #{nxball}"
    end

    # NxBalls::nxballSuffixStatusIfRelevant(item)
    def self.nxballSuffixStatusIfRelevant(item)
        nxball = NxBalls::getNxBallOrNull(item)
        return "" if nxball.nil?
        " #{NxBalls::nxBallToString(nxball)}"
    end

    # NxBalls::runningItems()
    def self.runningItems()
        NxBalls::all()
            .map{|ball| ball["itemuuid"] }
            .map{|uuid| DarkEnergy::itemOrNull(uuid) }
            .compact
    end
end
