
class OpenCycles

    # OpenCycles::getLocationId(location)
    def self.getLocationId(location)

        if File.file?(location) then
            return Digest::SHA1.hexdigest("#{File.basename(location)}:f0f4b780-028e-4d12-825f-53f0b9308381")
        end

        filepath = "#{location}/.catalyst-id-d9fd70ad-7bd3"
        if !File.exist?(filepath) then
            File.open(filepath, "w"){|f| f.write(SecureRandom.uuid) }
        end
        IO.read(filepath).strip
    end

    # OpenCycles::getItemByOpenCycleId(id)
    def self.getItemByOpenCycleId(id)
        Catalyst::catalystItems().select{|item| item["open-cycle-1143"] == id }.first
    end

    # OpenCycles::makeItemOrNull(message)
    def self.makeItemOrNull(message)
        puts "> make item for open cycle: #{message.green}"
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["wave", "ondate", "task"])
        return nil if option.nil?
        item = nil
        if option == "wave" then
            item = Waves::issueNewWaveInteractivelyOrNull()
        end
        if option == "ondate" then
            item = NxOndates::interactivelyIssueNewOrNull()
        end
        if option == "task" then
            item = NxTasks::interactivelyIssueNewOrNull()
        end
        item
    end

    # OpenCycles::maintenance()
    def self.maintenance()
        LucilleCore::locationsAtFolder("#{Config::userHomeDirectory()}/Galaxy/OpenCycles").each{|location|
            next if File.basename(location)[0, 1] == "."
            id = OpenCycles::getLocationId(location)
            item = OpenCycles::getItemByOpenCycleId(id)
            next if item
            message = "> required item for open cycle folder: #{File.basename(location)}"
            item = OpenCycles::makeItemOrNull(message)
            next if item.nil?
            Events::publishItemAttributeUpdate(item["uuid"], "open-cycle-1143", id)
            core = TxCores::interactivelySelectOneOrNull()
            if core then
                Events::publishItemAttributeUpdate(item["uuid"], "coreX-2300", core["uuid"])
            end
        }
    end

    # OpenCycles::suffix(item)
    def self.suffix(item)
        return "" if item["open-cycle-1143"].nil?
        " (open cycle)"
    end
end
