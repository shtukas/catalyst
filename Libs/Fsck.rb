
class Fsck

    # Fsck::fsckOrError(item)
    def self.fsckOrError(item)
        puts "fsck item: #{JSON.pretty_generate(item)}"

        UxPayload::fsck(item["uxpayload-b4e4"])

        if item["mikuType"] == "NxAnniversary" then
            return
        end
        if item["mikuType"] == "NxBackup" then
            return
        end
        if item["mikuType"] == "NxFloat" then
            return
        end
        if item["mikuType"] == "NxTask" then
            return
        end
        if item["mikuType"] == "Wave" then
            return
        end
        raise "I do not know how to fsck mikutype: #{item["mikuType"]}"
    end

    # Fsck::fsckAll()
    def self.fsckAll()
        Items::items()
            .each{|item| Fsck::fsckOrError(item) }
    end
end