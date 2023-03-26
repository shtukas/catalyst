
class NxOpenCycles

    # NxOpenCycles::items(board)
    def self.items(board)
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/OpenCycles")
            .select{|folderpath| File.basename(folderpath).start_with?("20") }
            .select{|folderpath| 
                itemfilepath = "#{folderpath}/.catalyst-item-2dff0987"
                !File.exists?(itemfilepath)
            }
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
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/OpenCycles")
            .select{|folderpath| File.basename(folderpath).start_with?("20") }
            .each{|folderpath|
                itemfilepath = "#{folderpath}/.catalyst-item-2dff0987"
                next if File.exists?(itemfilepath)
                puts File.basename(folderpath).green
                option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["ignore-permanently", "fire", "task", "project"])
                next if option.nil?
                if option == "ignore-permanently" then
                    File.open(itemfilepath, "w"){|f| f.write("ignore-permanently") }
                end
                if option == "fire" then
                    description = "open cycle: #{File.basename(folderpath)}"
                    uuid  = SecureRandom.uuid
                    coredataref = "open-cycle:#{File.basename(folderpath)}"
                    item = {
                        "uuid"        => uuid,
                        "mikuType"    => "NxFire",
                        "unixtime"    => Time.new.to_i,
                        "datetime"    => Time.new.utc.iso8601,
                        "description" => description,
                        "field11"     => coredataref
                    }
                    item = BoardsAndItems::askAndAttach(item)
                    puts JSON.pretty_generate(item)
                    N3Objects::commit(item)
                    File.open(itemfilepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
                end
                if option == "task" then
                    description = "open cycle: #{File.basename(folderpath)}"
                    uuid  = SecureRandom.uuid
                    coredataref = "open-cycle:#{File.basename(folderpath)}"
                    board = NxBoards::interactivelySelectOneOrNull()
                    if board then
                        position = NxBoards::interactivelyDecideNewBoardPosition(board)
                        item = {
                            "uuid"        => uuid,
                            "mikuType"    => "NxTask",
                            "unixtime"    => Time.new.to_i,
                            "datetime"    => Time.new.utc.iso8601,
                            "description" => description,
                            "field11"     => coredataref,
                            "position"    => position,
                            "boarduuid"   => board["uuid"],
                        }
                    else
                        position = NxTasks::nextPosition()
                        item = {
                            "uuid"        => uuid,
                            "mikuType"    => "NxTask",
                            "unixtime"    => Time.new.to_i,
                            "datetime"    => Time.new.utc.iso8601,
                            "description" => description,
                            "field11"     => coredataref,
                            "position"    => position,
                            "boarduuid"   => nil,
                        }
                    end
                    item = BoardsAndItems::askAndAttach(item)
                    N3Objects::commit(item)
                    File.open(itemfilepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
                end
                if option == "project" then
                    description = "open cycle: #{File.basename(folderpath)}"
                    uuid = SecureRandom.uuid
                    hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
                    coredataref = "open-cycle:#{File.basename(folderpath)}"
                    item = {
                        "uuid"          => uuid,
                        "mikuType"      => "NxProject",
                        "unixtime"      => Time.new.to_i,
                        "datetime"      => Time.new.utc.iso8601,
                        "description"   => description,
                        "field11"       => coredataref,
                        "hours"         => hours,
                        "lastResetTime" => 0,
                        "capsule"       => SecureRandom.hex
                    }
                    item = BoardsAndItems::askAndAttach(item)
                    N3Objects::commit(item)
                    File.open(itemfilepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
                end
            }
    end
end
