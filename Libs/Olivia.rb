
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

    # Olivia::magic1(stack, items, final)
    def self.magic1(stack, items, final)
        if stack.empty? then
            return final + items
        end
        i1    = stack.first                                      # item from stack
        stack = stack.drop(1)                                    # updated stack
        i2    = items.select{|i| i["uuid"] == i1["uuid"] }.first # item from items with the same uuid as i1
        items = items.select{|i| i["uuid"] != i1["uuid"] }       # updated items
        Olivia::magic1(stack, items, final + [i2].compact)
    end

end