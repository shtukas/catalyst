
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
        "📥 #{File.basename(item["location"])}"
    end

    # NxBufferInItems::accessLocation(location)
    def self.accessLocation(location)
        if File.directory?(location) then
            puts "opening '#{location}'"
            system("open '#{location}'")
            LucilleCore::pressEnterToContinue()
            return
        end
        if File.file?(location) then
            puts "exporting '#{location}'"
            exportLocation = "#{Config::userHomeDirectory()}/x-space/xcache-v1-days/#{CommonUtils::today()}/#{SecureRandom.hex(1)}-#{Time.new.to_i}"
            FileUtils::mkpath(exportLocation)
            LucilleCore::copyFileSystemLocation(location, exportLocation)
            system("open '#{exportLocation}'")
            LucilleCore::pressEnterToContinue()
            return
        end
    end
end
