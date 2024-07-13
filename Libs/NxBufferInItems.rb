
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
                    "uuid"     => Digest::SHA1.hexdigest("a2531d0e-e411-44b8-8de4-999f0d7790e2:#{location}"),
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
