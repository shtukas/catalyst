
class NxOpenCycles

    # NxOpenCycles::listingItems()
    def self.listingItems()
        [{
            "uuid" => "1057b16e-d486-4451-a165-67c92dfd5268", # same account a the scheduler1
            "mikuType" => "NxOpenCycles",
            "description" => "open cycles (general) [discard for day if nothing]"
        }]
    end

    # NxOpenCycles::commandInterpreter(input)
    def self.commandInterpreter(input)

        if Interpreting::match("boardtail", input) then
            return NxBoardTails::interactivelyIssueNullOrNull()
        end

        if Interpreting::match("drop", input) then
            options = ["NxBoard", "NxList"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            return nil if option.nil?
            if option == "NxBoard" then
                return NxHeads::interactivelyIssueNewBoardedOrNull()
            end
            if option == "NxList" then
                return NxHeads::interactivelyIssueNewBoardlessOrNull()
            end
        end

        if Interpreting::match("ondate", input) then
            item = NxOndates::interactivelyIssueNullOrNull()
            return nil if item.nil?
            puts JSON.pretty_generate(item)
            return BoardsAndItems::interactivelyOffersToAttach(item)
        end

        if Interpreting::match("float", input) then
            item = NxFloats::interactivelyIssueNullOrNull()
            return nil if item.nil?
            puts JSON.pretty_generate(item)
            return BoardsAndItems::interactivelyOffersToAttach(item)
        end

        if Interpreting::match("priority", input) then
            item = NxHeads::priority()
            return nil if item.nil?
            puts JSON.pretty_generate(item)
            return BoardsAndItems::interactivelyOffersToAttach(item)
        end

        if Interpreting::match("project", input) then
            item = NxProjects::interactivelyIssueNullOrNull()
            return nil if item.nil?
            puts JSON.pretty_generate(item)
            return item
        end

        if Interpreting::match("today", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return nil if item.nil?
            puts JSON.pretty_generate(item)
            return BoardsAndItems::interactivelyOffersToAttach(item)
        end

        if Interpreting::match("top", input) then
            item = NxTops::interactivelyIssueNullOrNull()
            return nil if item.nil?
            puts JSON.pretty_generate(item)
            return item
        end

        if input == "wave" then
            item = Waves::issueNewWaveInteractivelyOrNull()
            return nil if item.nil?
            puts JSON.pretty_generate(item)
            return BoardsAndItems::interactivelyOffersToAttach(item)
        end
    end

    # NxOpenCycles::dataManagement()
    def self.dataManagement()
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
                        FileUtils.rm(filepath)
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
                        command = LucilleCore::askQuestionAnswerAsString("command: ")
                        if command == "" then
                            return
                        end
                        item = NxOpenCycles::commandInterpreter(command)
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
