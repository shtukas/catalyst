
class NxShips

    # NxShips::interactivelyIssueNew(targetuuid, hours)
    def self.interactivelyIssueNew(targetuuid, hours)
        uuid = SecureRandom.uuid
        Cubes2::itemInit(uuid, "NxShip")
        Cubes2::setAttribute(uuid, "targetuuid", targetuuid)
        Cubes2::setAttribute(uuid, "hours", hours)
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxShips::toString(item, context = nil)
    def self.toString(item, context = nil)
        target = Cubes2::itemOrNull(item["targetuuid"])
        if target.nil? then
            Cubes2::destroy(item["uuid"])
            return "(ship) (deletion in progress)"
        end
        ratio = NxShips::ratio(item)
        ratiostring = "(ship: #{100 * ratio} % of #{item["hours"]} hours)".green
        if context == "listing" then
            return "#{PolyFunctions::toString(target, "ship")} #{ratiostring}"
        end
        "#{ratiostring} #{PolyFunctions::toString(target, "ship")}"
    end

    # NxShips::ratio(item)
    def self.ratio(item)
        Bank2::recoveredAverageHoursPerDay(item["uuid"]).to_f/item["hours"]
    end

    # NxShips::muiItems()
    def self.muiItems()
        Cubes2::mikuType("NxShip")
            .select{|item| NxShips::ratio(item) < 1 }
            .sort_by{|item| NxShips::ratio(item) }
    end

    # NxShips::program()
    def self.program()
        loop {

            ships = Cubes2::mikuType("NxShip")
            return if ships.empty?

            system("clear")

            store = ItemStore.new()

            puts ""

            ships
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts MainUserInterface::toString2(store, item, "inventory")
                }

            puts ""
            puts "hours *"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input.start_with?("hours") then
                listord = input[5, input.size].strip.to_i
                s = store.get(listord.to_i)
                next if s.nil?
                puts PolyFunctions::toString(s).green
                hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
                Cubes2::setAttribute(s["uuid"], "hours", hours)
                next
            end

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
