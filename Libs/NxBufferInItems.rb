
class NxBufferInItems

    # NxBufferInItems::locations()
    def self.locations()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/Buffer-In")
            .select{|location| !File.basename(location).start_with?('.') }
    end

    # NxBufferInItems::items()
    def self.items()
        NxBufferInItems::locations()
            .map{|location|
                {
                    "uuid"     => location,
                    "mikuType" => "NxBufferInItem",
                    "location" => location
                }
            }
    end

    # NxBufferInItems::toString(item)
    def self.toString(item)
        "[In] #{File.basename(item["location"])}"
    end
end
