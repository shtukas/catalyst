

class Catalyst

    # Catalyst::editItem(item)
    def self.editItem(item)
        item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
        item.to_a.each{|key, value|
            DataCenter::setAttribute(item["uuid"], key, value)
        }
    end

    # Catalyst::program2(elements)
    def self.program2(elements)
        loop {

            elements = elements.map{|item| DataCenter::itemOrNull(item["uuid"]) }.compact
            return if elements.empty?

            system("clear")

            store = ItemStore.new()

            puts  ""

            elements
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::toString2(store, item)
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Catalyst::periodicPrimaryInstanceMaintenance()
    def self.periodicPrimaryInstanceMaintenance()
        if Config::isPrimaryInstance() then
            puts "> Catalyst::periodicPrimaryInstanceMaintenance()"

            if DataCenter::mikuType("NxTask").size < 100 then
                DataCenter::mikuType("NxIce").take(10).each{|item|

                }
            end
        end
    end

    # Catalyst::donationSuffix(item)
    def self.donationSuffix(item)
        return "" if item["donation-1752"].nil?
        " (#{item["donation-1752"].map{|uuid| DataCenter::itemOrNull(uuid)}.compact.map{|target| target["description"]}.join(", ")})".green
    end

    # Catalyst::interactivelyIssueCatalystItemForOpenCycle(uuid)
    def self.interactivelyIssueCatalystItemForOpenCycle(uuid)
        NxEffects::interactivelyIssueNewOrNull2(uuid)
    end

    # Catalyst::openCyclesSync()
    def self.openCyclesSync()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/OpenCycles").each{|location|
            next if !File.directory?(location)
            next if File.basename(location).start_with?('.')
            markerfile = "#{location}/.marker-709b82a0903b"
            if !File.exist?(markerfile) then
                uuid = SecureRandom.uuid
                File.open(markerfile, "w"){|f| f.puts(uuid) }
                puts "Generating item for '#{File.basename(location).green}'"
                LucilleCore::pressEnterToContinue()
                Catalyst::interactivelyIssueCatalystItemForOpenCycle(uuid)
                next
            end
            uuid = IO.read(markerfile).strip
            item = DataCenter::itemOrNull(IO.read(markerfile).strip).nil?
            if item.nil? then
                uuid = SecureRandom.uuid
                File.open(markerfile, "w"){|f| f.puts(uuid) }
                puts "Generating item for '#{File.basename(location).green}'"
                LucilleCore::pressEnterToContinue()
                Catalyst::interactivelyIssueCatalystItemForOpenCycle(uuid)
                next
            end
        }
    end
end
