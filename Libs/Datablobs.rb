
class Datablobs

    # Datablobs::directory()
    def self.directory()
        "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/Datablobs"
    end

    # Datablobs::putBlob(datablob)
    def self.putBlob(datablob) # nhash
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        fragment = "#{nhash[7, 2]}/#{nhash[9, 2]}"
        filename = "#{nhash}.blob"
        folder   = "#{Datablobs::directory()}/#{fragment}"
        if !File.exist?(folder) then
            FileUtils.mkpath(folder)
        end
        filepath = "#{folder}/#{filename}"
        File.open(filepath, "w"){|f| f.write(datablob) }
        nhash
    end

    # Datablobs::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        fragment = "#{nhash[7, 2]}/#{nhash[9, 2]}"
        folder   = "#{Datablobs::directory()}/#{fragment}"
        filename = "#{nhash}.blob"
        filepath = "#{folder}/#{filename}"
        return nil if !File.exist?(filepath)
        IO.read(filepath)
    end
end
