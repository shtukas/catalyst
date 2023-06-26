
class EnergyGrid

    # EnergyGrid::griduuid()
    def self.griduuid()
        "f96cc544-06ef-4e30-b415-e57e78eb3d73"
    end

    # EnergyGrid::grid()
    def self.grid()
        engine = DarkEnergy::itemOrNull(EnergyGrid::griduuid())
        if engine.nil? then
            raise "(error: 7320289f-10c4-49c9-8f50-1f5fa22fcb5a) could not find reverse infinity engine"
        end
        engine
    end
 
    # EnergyGrid::items()
    def self.items()
        items = Memoize::evaluate(
            "32ab7fb3-f85c-4fdf-aafe-9465d7db2f5f", 
            lambda{
                puts "Computing EnergyGrid::items() ..."
                items = DarkEnergy::mikuType("NxTask")
                                .select{|task| task["parent"].nil? }
                                .select{|task| task["engine"].nil? }
                                .sort_by{|item| item["unixtime"] }
                (items.take(100) + items.reverse.take(100)).shuffle
            })
        items
            .select{|item| DarkEnergy::itemOrNull(item["uuid"]) }
            .compact
    end

    # EnergyGrid::itemBelongsToEnergyGrid(item)
    def self.itemBelongsToEnergyGrid(item)
        EnergyGrid::items().map{|item| item["uuid"] }.include?(item["uuid"])
    end
end
