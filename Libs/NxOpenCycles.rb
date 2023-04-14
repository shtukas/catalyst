
class NxOpenCycles

    # NxOpenCycles::makeNxTasks()
    def self.makeNxTasks()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/OpenCycles")
            .select{|folderpath| File.basename(folderpath).start_with?("20") }
            .each{|folderpath|
                itemfilepath = "#{folderpath}/.catalyst-item-2dff0987"
                next if File.exist?(itemfilepath)
                puts File.basename(folderpath).green
                option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["ignore-permanently", "fire", "task"])
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
                    item = BoardsAndItems::askAndMaybeAttach(item)
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
                        position = NxTasks::thatPosition()
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
                    item = BoardsAndItems::askAndMaybeAttach(item)
                    N3Objects::commit(item)
                    File.open(itemfilepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
                end
            }
    end
end
