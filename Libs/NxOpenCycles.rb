
class NxOpenCycles

    # NxOpenCycles::items(board)
    def self.items(board)
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/OpenCycles")
            .select{|folderpath| File.basename(folderpath).start_with?("20") }
            .map{|folderpath|
                {
                    "uuid"     => Digest::SHA1.hexdigest("0B9D1889-D6B2-4FA5-AAC3-8D049A102AB7:#{folderpath}"),
                    "mikuType" => "NxOpenCycle",
                    "name"     => File.basename(folderpath)
                }
            }
    end

    # NxOpenCycles::dataManagement()
    def self.dataManagement()

    end
end
