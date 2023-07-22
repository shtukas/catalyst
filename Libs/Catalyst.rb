

class Catalyst

    # Catalyst::catalystItems()
    def self.catalystItems()
        [
            BladesItemised::mikuType("Wave")
        ]
            .flatten
    end

    # Catalyst::fsck()
    def self.fsck()
        Waves::fsck()
        NxTasks::fsck()
        NxOndates::fsck()
        NxLongTasks::fsck()
        BladesItemised::mikuType("NxIce").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end
end
