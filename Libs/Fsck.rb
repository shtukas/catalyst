
class Fsck

    # Fsck::fsckOrError(item)
    def self.fsckOrError(item)
        if item["mikuType"] == "NxAnniversary" then
            return
        end
        if item["mikuType"] == "NxBurner" then
            return
        end
        if item["mikuType"] == "NxIce" then
            if item["field11"] then
                CoreDataRefStrings::fsck(item)
            end
            return
        end
        if item["mikuType"] == "NxLine" then
            return
        end
        if item["mikuType"] == "NxCruise" then
            NxCruises::fsck()
            return
        end
        if item["mikuType"] == "NxOndate" then
            if item["field11"] then
                CoreDataRefStrings::fsck(item)
            end
            return
        end
        if item["mikuType"] == "NxPool" then
            if item["field11"] then
                CoreDataRefStrings::fsck(item)
            end
            return
        end
        if item["mikuType"] == "NxStrat" then
            if item["field11"] then
                CoreDataRefStrings::fsck(item)
            end
            return
        end
        if item["mikuType"] == "NxTask" then
            if item["field11"] then
                CoreDataRefStrings::fsck(item)
            end
            return
        end
        if item["mikuType"] == "PhysicalTarget" then
            if item["field11"] then
                CoreDataRefStrings::fsck(item)
            end
            return
        end
        if item["mikuType"] == "TxCore" then
            return
        end 
        if item["mikuType"] == "Wave" then
            if item["field11"] then
                CoreDataRefStrings::fsck(item)
            end
            return
        end 
        raise "I do not know how to fsck mikutype: #{item["mikuType"]}"
    end

    # Fsck::run_all()
    def self.run_all()
        Catalyst::catalystItems().each{|item|
            Fsck::fsckOrError(item)
        }
    end
end