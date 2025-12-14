
class Fsck

    # Fsck::fsckItemOrError(item, verbose)
    def self.fsckItemOrError(item, verbose)
        if verbose then
            puts "fsck item: #{JSON.pretty_generate(item)}"
        end

        if item["mikuType"] == "NxDeleted" then
            return
        end

        if item["mikuType"] == "UxPayload" then
            UxPayloads::fsck(item)
            return
        end

        if item["mikuType"] == "NxInfinity" then
            return
        end

        if item["mikuType"] == "NxHappening" then
            return
        end

        if item["mikuType"] == "NxLine" then
            return
        end

        if item["mikuType"] == "NxTask" then
            return
        end

        if item["mikuType"] == "NxLine" then
            return
        end

        if item["mikuType"] == "AionPoint" then
            AionFsck::structureCheckAionHashRaiseErrorIfAny(Elizabeth.new(), item["nhash"])
            return
        end

        if item["mikuType"] == "Dx8Unit" then
            if item["id"].nil? then
                raise "could not find `id` attribute for item #{item}"
            end
            return
        end

        if item["mikuType"] == "OpenCycle" then
            return
        end

        if item["mikuType"] == "Text" then
            if item["text"].nil? then
                raise "could not find `text` attribute for item #{item}"
            end
            return
        end

        if item["mikuType"] == "TodoTextFileByNameFragment" then
            return
        end

        if item["mikuType"] == "UniqueString" then
            return
        end

        if item["mikuType"] == "URL" then
            return
        end

        if item["mikuType"] == "Wave" then
            return
        end

        if item["mikuType"] == "NxOndate" then
            return
        end

        if item["mikuType"] == "NxHappening" then
            return
        end

        if item["mikuType"] == "NxBackup" then
            return
        end

        if item["mikuType"] == "Anniversary" then
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