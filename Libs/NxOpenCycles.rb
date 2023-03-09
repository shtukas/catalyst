
class NxOpenCycles

    # NxOpenCycles::dataManagement()
    def self.dataManagement()
        return if !Config::isPrimaryInstance()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/OpenCycles")
            .select{|folderpath| File.basename(folderpath).start_with?("20") }
            .each{|folderpath|
                markfilepath = "#{folderpath}/.catalyst-d369f24b"
                if File.exist?(markfilepath) then
                    if IO.read(markfilepath) == "ignore-permanently-c079ee025d7f" then
                        next 
                    end
                end
                if File.exist?(markfilepath) then
                    item = JSON.parse(IO.read(markfilepath))
                    if N3Objects::getOrNull(item["uuid"]) then
                        # nothing to do
                    else
                        FileUtils.rm(markfilepath)
                        return
                    end
                else
                    puts "#{folderpath}".green
                    option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["ignore permanently", "make a catalyst item"])
                    if option.nil? then
                        return
                    end
                    if option == "ignore permanently" then
                        # We mark the file to be ignored permanently
                        File.open(markfilepath, "w"){|f|
                            f.write("ignore-permanently-c079ee025d7f")
                        }
                        next
                    end
                    if option == "make a catalyst item" then
                        item = PolyActions::dropmaking(useCoreData: false)
                        if item.nil? then
                            return
                        end
                        item["field11"] = "open-cycle:#{File.basename(folderpath)}"
                        N3Objects::commit(item)
                        File.open(markfilepath, "w"){|f|
                            f.puts(JSON.pretty_generate(item))
                        }
                        return
                    end
                end
            }
    end
end
