
class DropBox

    # DropBox::strFormat(str)
    def self.strFormat(str)
        str = str.strip
        return "" if str == ""
        str.lines.map{|l| "      #{l}" }
        .join()
    end

    # DropBox::locationToItem(location)
    def self.locationToItem(location)
        uuid = File.basename(location)
        {
            "uuid"        => uuid,
            "mikuType"    => "DropBox",
            "description" => "(DropBox)\n#{DropBox::strFormat(IO.read(location).strip)}"
        }
    end

    # DropBox::items()
    def self.items()
        LucilleCore::locationsAtFolder("#{Config::pathToCatalystDataRepository()}/DropBox")
            .select{|location| File.basename(location)[-4, 4] == ".txt" }
            .map{|location| DropBox::locationToItem(location)}
    end

    # DropBox::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToCatalystDataRepository()}/DropBox/#{uuid}"
    end

    # DropBox::done(uuid)
    def self.done(uuid)
        filepath = DropBox::filepath(uuid)
        return if !File.exist?(filepath)
        FileUtils.rm(filepath)
    end
end