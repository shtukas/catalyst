
class Fsck

    # Fsck::fsckOrError(item)
    def self.fsckOrError(item)
        if item["mikuType"] == "NxAnniversary" then
            return
        end
        if item["mikuType"] == "NxIce" then
            return
        end
        if item["mikuType"] == "NxPool" then
            return
        end
        if item["mikuType"] == "NxTask" then
            return
        end
        if item["mikuType"] == "PhysicalTarget" then
            return
        end
        if item["mikuType"] == "Wave" then
            return
        end
        if item["mikuType"] == "NxIce" then
            return
        end
        if item["mikuType"] == "NxStrat" then
            return
        end
        raise "I do not know how to fsck mikutype: #{item["mikuType"]}"
    end

    # Fsck::runAll()
    def self.runAll()
        Cubes2::items().each{|item|
            puts JSON.pretty_generate(item)
            if item["mikuType"] == "Nx101" then
                Cubes2::destroy(item["uuid"])
                next
            end
            if item["mikuType"] == "DxStackItem" then
                Cubes2::destroy(item["uuid"])
                next
            end
            if item["mikuType"] == "NxAvaldi" then
                Cubes2::destroy(item["uuid"])
                next
            end
            if item["field11"] then
                CoreDataRefStrings::fsck(item)
            end
            Fsck::fsckOrError(item)
        }
    end
end