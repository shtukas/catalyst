
class NxGPS

    # NxGPS::itemsInOrder()
    def self.itemsInOrder()
        Items::items()
            .select{|item| item["gps-2119"] }
            .sort_by{|item| item["gps-2119"] }
    end

    # NxGPS::reposition(item)
    def self.reposition(item)
        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::gps_reposition(item)
            return
        end
        if item["mikuType"] == "Wave" then
            Waves::gps_reposition(item)
            return
        end

        if item["mikuType"] == "NxBackup" then
            NxBackups::gps_reposition(item)
            return
        end

        if item["mikuType"] == "NxDated" then
            NxDateds::gps_reposition(item)
            return
        end

        if item["mikuType"] == "NxCore" then
            NxCores::gps_reposition(item)
            return
        end

        raise "(error: c21b8535) do not know how to reposition #{JSON.pretty_generate(item)}"
    end
end

