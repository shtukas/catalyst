
class Olivia

    # Olivia::getStack()
    def self.getStack()
        folder = "#{ENV['HOME']}/Galaxy/DataHub/catalyst/Olivia"
        filepaths = LucilleCore::locationsAtFolder(folder).select{|filepath| filepath[-5, 5] == ".json" }
        return [] if filepaths.empty?
        JSON.parse(IO.read(filepaths.last))
    end

    # Olivia::putStack(stack)
    def self.putStack(stack)
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
        stack = Olivia::getStack()
        stack = stack.select{|i| i["uuid"] != item["uuid"] }
        Olivia::putStack(stack)
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
end