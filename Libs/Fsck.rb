
class Fsck

    # Fsck::fsckItemOrError(item, verbose)
    def self.fsckItemOrError(item, verbose)
        if verbose then
            puts "fsck item: #{JSON.pretty_generate(item)}"
        end

        if item["mikuType"] == "NxDeleted" then
            return
        end

        if item["mikuType"] == "NxIce" then
            return
        end

        if item["mikuType"] == "NxPolymorph" then
            return
        end

        if item["mikuType"] == "NxSequenceItem" then
            return
        end

        if item["mikuType"] == "UxPayload" then
            UxPayload::fsck(item)
            return
        end

        if item["mikuType"] == "NxProject" then
            return
        end

        if item["mikuType"] == "NxTask" then
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
        Items::objects()
            .each{|item|
                key = "#{config["mark"]}:#{item["uuid"]}"
                next if XCache::getOrNull(key) == "done"
                Fsck::fsckItemOrError(item, true)
                XCache::set(key, "done")
            }
    end
end