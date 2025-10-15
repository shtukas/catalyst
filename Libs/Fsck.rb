
class Fsck

    # Fsck::fsckOrError(item)
    def self.fsckOrError(item)
        puts "fsck item: #{JSON.pretty_generate(item)}"

        if item["mikuType"] == "NxDeleted" then
            return
        end

        UxPayload::fsck(item["uuid"], item["uxpayload-b4e4"])

        if item["mikuType"] == "NxAnniversary" then
            return
        end
        if item["mikuType"] == "NxBackup" then
            return
        end
        if item["mikuType"] == "NxTask" then
            return
        end
        if item["mikuType"] == "Wave" then
            return
        end
        if item["mikuType"] == "NxMonitor" then
            return
        end
        if item["mikuType"] == "NxIce" then
            return
        end
        raise "I do not know how to fsck mikutype: #{item["mikuType"]}"
    end

    # Fsck::fsckAll()
    def self.fsckAll()
        config = XCache::getOrNull("82e98b31-2d0a-4a9d-9030-28fd195a97c0")
        if config then
            config = JSON.parse(config)
            if Time.new.to_i - config["unixtime"] > 3600*2 then
                if LucilleCore::askQuestionAnswerAsBoolean("The fsck mark is more than two hour(s) old, do you want to replace it ? (will run fsck from zero) ") then
                    config = nil
                end
            end
        end
        if config.nil? then
            config = {
                "unixtime" => Time.new.to_i,
                "mark" => SecureRandom.hex
            }
            XCache::set("82e98b31-2d0a-4a9d-9030-28fd195a97c0", JSON.generate(config))
        end
        Items::items()
            .each{|item|
                key = "#{config["mark"]}:#{item["uuid"]}"
                next if XCache::getOrNull(key) == "done"
                Fsck::fsckOrError(item)
                XCache::set(key, "done")
            }
        LucilleCore::pressEnterToContinue()
    end
end