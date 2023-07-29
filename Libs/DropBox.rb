
class DropBox

    # DropBox::locationToItem(location)
    def self.locationToItem(location)
        uuid = File.basename(location)
        {
            "uuid" => uuid,
            "mikuType" => "DropBox",
            "description" => "(DropBox) #{IO.read(location).strip}"
        }
    end

    # DropBox::items()
    def self.items()
        LucilleCore::locationsAtFolder("#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/DropBox")
            .select{|location| File.basename(location)[-9, 9] == ".drop.txt" }
            .map{|location| DropBox::locationToItem(location)}
    end

    # DropBox::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/DropBox/#{uuid}"
    end

    # DropBox::done(uuid)
    def self.done(uuid)
        filepath = DropBox::filepath(uuid)
        return if !File.exist?(filepath)
        FileUtils.rm(filepath)
    end
end