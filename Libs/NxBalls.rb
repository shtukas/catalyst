
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
            "unixtime"       => Time.new.to_f,
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
        accounts = PolyFunctions::itemToBankingAccounts(item)
        accounts.each{|account|
            puts "starting account: (#{account["description"]}, #{account["number"]})"
        }
        NxBalls::issueNxBall(item, accounts)
    end

    # NxBalls::stop(item) # timespanInSeconds
    def self.stop(item) # timespanInSeconds
        if NxBalls::itemIsBallFree(item) then
            NxBalls::destroyNxBall(item)
            return 0 
        end
        if NxBalls::itemIsPaused(item) then
            puts "stopping paused item, nothing to do..."
            NxBalls::destroyNxBall(item)
            return 0
        end
        nxball = NxBalls::getNxBallOrNull(item)
        if nxball["instance"] != Config::thisInstanceId() then
            puts "This ball wasn't created here, was created at #{nxball["instance"]}."
            return 0 if !LucilleCore::askQuestionAnswerAsBoolean("Confirm stop operation: ")
        end
        timespanInSeconds = Time.new.to_i - nxball["startunixtime"]
        nxball["accounts"].each{|account|
            puts "adding #{timespanInSeconds} seconds to account: (#{account["description"]}, #{account["number"]})"
            Bank::put(account["number"], timespanInSeconds)
        }
        NxBalls::destroyNxBall(item)
        timespanInSeconds
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
            nxball["unixtime"]      = Time.new.to_f
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
        if nxball["type"] == "running" and nxball["sequencestart"] then
            return "(nxball: running for #{((Time.new.to_i - nxball["startunixtime"]).to_f/3600).round(2)} hours, sequence started #{((Time.new.to_i - nxball["sequencestart"]).to_f/3600).round(2)} hours ago)"
        end
        if nxball["type"] == "running" then
            return "(nxball: running for #{((Time.new.to_i - nxball["startunixtime"]).to_f/3600).round(2)} hours)"
        end
        if nxball["type"] == "paused" then
            return "(nxball: paused)"
        end
        raise "(error: 93abde39-fd9d-4aa5-8e56-d09cf47a0f46) nxball: #{nxball}"
    end

    # NxBalls::nxballSuffixStatusIfRelevant(item)
    def self.nxballSuffixStatusIfRelevant(item)
        nxball = NxBalls::getNxBallOrNull(item)
        return "" if nxball.nil?
        " #{NxBalls::nxBallToString(nxball)}"
    end

    # NxBalls::activeItems()
    def self.activeItems()
        NxBalls::all()
            .sort_by{|item| item["unixtime"] }
            .reverse
            .map{|ball| ball["itemuuid"] }
            .map{|itemuuid| 
                ix = DataCenter::itemOrNull(itemuuid)
                if ix.nil? then
                    filepath = "#{NxBalls::repository()}/#{itemuuid}.ball"
                    if File.exist?(filepath) then
                        puts "garbage collecting NxBall: #{filepath}".green
                        FileUtils.rm(filepath)
                    end
                    nil
                else
                    ix
                end
            }
            .compact
    end
end
