

class Catalyst

    # Catalyst::editItem(item)
    def self.editItem(item)
        item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
        item.to_a.each{|key, value|
            Cubes2::setAttribute(item["uuid"], key, value)
        }
    end

    # Catalyst::program2(elements)
    def self.program2(elements)
        loop {

            elements = elements.map{|item| Cubes2::itemOrNull(item["uuid"]) }.compact
            return if elements.empty?

            system("clear")

            store = ItemStore.new()

            puts  ""

            elements
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts  MainUserInterface::toString2(store, item)
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Catalyst::periodicPrimaryInstanceMaintenance()
    def self.periodicPrimaryInstanceMaintenance()
        if Config::isPrimaryInstance() then
            puts "> Catalyst::periodicPrimaryInstanceMaintenance()"
            Cubes1::maintenance()
            DoNotShowUntil1::maintenance()
            if Cubes2::mikuType("NxTask").size < 100 then
                Cubes2::mikuType("NxIce").take(10).each{|item|

                }
            end
        end
    end

    # Catalyst::donationSuffix(item)
    def self.donationSuffix(item)
        return "" if item["donation-1752"].nil?
        " (#{item["donation-1752"].map{|uuid| Cubes2::itemOrNull(uuid)}.compact.map{|target| target["description"]}.join(", ")})".green
    end

    # Catalyst::selectTodoTextFileLocationOrNull(todotextfile)
    def self.selectTodoTextFileLocationOrNull(todotextfile)
        location = XCache::getOrNull("fcf91da7-0600-41aa-817a-7af95cd2570b:#{todotextfile}")
        if File.exist?(location) then
            return location
        end

        roots = [Config::pathToGalaxy()]
        Galaxy::locationEnumerator(roots).each{|location|
            if File.basename(location).include?(todotextfile) then
                XCache::set("fcf91da7-0600-41aa-817a-7af95cd2570b:#{todotextfile}", location)
                return location
            end
        }
        nil
    end
end
