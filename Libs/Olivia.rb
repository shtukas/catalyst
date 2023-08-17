
class Olivia

    # Olivia::getListing()
    def self.getListing()
        folder = "#{ENV['HOME']}/Galaxy/DataHub/catalyst/Olivia"
        filepaths = LucilleCore::locationsAtFolder(folder).select{|filepath| filepath[-5, 5] == ".json" }
        return [] if filepaths.empty?
        JSON.parse(IO.read(filepaths.last))
    end

    # Olivia::putListing(stack)
    def self.putListing(stack)
        folder = "#{ENV['HOME']}/Galaxy/DataHub/catalyst/Olivia"
        LucilleCore::locationsAtFolder(folder)
            .select{|filepath| filepath[-5, 5] == ".json" }
            .each{|filepath| FileUtils.rm(filepath) }
        filepath = "#{folder}/#{Time.new.to_i}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(stack)) }
    end

    # Olivia::processItem(item)
    # We call that function on new items
    # return null if the item was instantly processed or the item if we put it in the stack
    def self.processItem(item)
        return item if item["mikuType"] == "NxStrat" 
        system('clear')
        puts PolyFunctions::toString(item)
        options = ["access + done", "add to stack (default)"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        if option == "access + done" then
            PolyActions::accessAndHopefullyDone(item)
            return nil
        end
        if option.nil? or option == "add to stack (default)" then
            return item
        end
    end

    # Olivia::removeItem(item)
    def self.removeItem(item)
        stack = Olivia::getListing()
        stack = stack.select{|i| i["uuid"] != item["uuid"] }
        Olivia::putListing(stack)
    end

    # Olivia::addItem(item)
    def self.addItem(item)
        stack = Olivia::getListing()
        stack = stack + [item]
        Olivia::putListing(stack)
    end

    # Olivia::magic1(stack, items, final)
    def self.magic1(stack, items, final)
        if stack.empty? and items.empty? then
            return final
        end
        if stack.empty? then
            i1 = items.shift
            i1 = Olivia::processItem(i1)
            return Olivia::magic1(stack, items, final + [i1].compact)
        end
        i1    = stack.first                                      # item from stack
        stack = stack.drop(1)                                    # updated stack
        i2    = items.select{|i| i["uuid"] == i1["uuid"] }.first # item from items with the same uuid as i1
        items = items.select{|i| i["uuid"] != i1["uuid"] }       # updated items
        Olivia::magic1(stack, items, final + [i2].compact)
    end

    # Olivia::magic2(items)
    def self.magic2(items)
        items = Olivia::magic1(Olivia::getListing(), items, [])
        Olivia::putListing(items.select{|i| i["mikuType"] != "NxStrat" })
        items
    end
end