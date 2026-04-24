
=begin

--------------------------------------------------------------------------------

TreeNode {
    "uuid"  : String
    "item"  : Item or null
    "left"  : Hash or null
    "right" : Hash or null
}

For the versioning, objects must have a _version35_ that is a unixtime with decimals

--------------------------------------------------------------------------------
{"uuid":"4973ece0-f7b9-446f-82ef-943f16634d77","item":null}
SHA256-05c4ec1ba5c05316399caa96d14606fa50a7f7ae1618907253f9918e3a2a9c0c

=end

class TheTree

    # ------------------------------------------------------------------
    # Config

    # TheTree::path_to_merkle()
    def self.path_to_merkle()
        "#{Config::pathToCatalystDataRepository()}/merkle"
    end

    # TheTree::path_to_datablobs()
    def self.path_to_datablobs()
        "#{TheTree::path_to_merkle()}/datablobs"
    end

    # ------------------------------------------------------------------
    # Datablob

    # TheTree::putBlob(datablob)
    def self.putBlob(datablob) # nhash
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        fragment = "#{nhash[7, 2]}/#{nhash[9, 2]}"
        filename = "#{nhash}.data"
        folder   = "#{TheTree::path_to_datablobs()}/#{fragment}"
        if !File.exist?(folder) then
            FileUtils.mkpath(folder)
        end
        filepath = "#{folder}/#{filename}"
        File.open(filepath, "w"){|f| f.write(datablob) }
        nhash
    end

    # TheTree::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        fragment = "#{nhash[7, 2]}/#{nhash[9, 2]}"
        folder   = "#{TheTree::path_to_datablobs()}/#{fragment}"
        filename = "#{nhash}.data"
        filepath = "#{folder}/#{filename}"
        return nil if !File.exist?(filepath)
        IO.read(filepath)
    end

    # TheTree::commit_treenode_to_datablobs_repository(treenode) -> hash
    def self.commit_treenode_to_datablobs_repository(treenode)
        puts JSON.pretty_generate(treenode).yellow
        TheTree::putBlob(JSON.generate(treenode))
    end

    # ------------------------------------------------------------------
    # roothash

    # TheTree::get_roothash()
    def self.get_roothash()
        filepath = LucilleCore::locationsAtFolder("#{TheTree::path_to_merkle()}/root")
            .select{|filepath| filepath[-9, 9] == ".root.txt" }
            .first

        if filepath.nil? then
            puts "[655d704f] Could not determine the file to the root record file"
            exit
        end

        [IO.read(filepath).strip, filepath]
    end

    # TheTree::replace_root_hashes(filepath1, roothash1, roothash2)
    def self.replace_root_hashes(filepath1, roothash1, roothash2)
        history_directory = "/Users/pascal_honore/Galaxy/DataHub/Catalyst/data/merkle/roots-history/#{Config::instanceId()}/#{Time.new.strftime("%Y")}/#{CommonUtils::today()}"
        history_directory = LucilleCore::indexsubfolderpath(history_directory, 300)
        if !File.exist?(history_directory) then
            FileUtils.mkpath(history_directory)
        end
        history_filepath = "#{history_directory}/#{CommonUtils::timeStringL22()}.root.txt"
        File.open(history_filepath, "w") {|f| f.puts(roothash1) }
        FileUtils.rm(filepath1)
        filepath2 = "#{TheTree::path_to_merkle()}/root/#{CommonUtils::timeStringL22()}.root.txt"
        File.open(filepath2, "w") {|f| f.puts(roothash2) }
    end

    # ------------------------------------------------------------------
    # operations at hash

    # TheTree::inject_item_at_hash(item, hash1) # -> hash
    def self.inject_item_at_hash(item, hash1)
        if hash1.nil? then
            return TheTree::commit_treenode_to_datablobs_repository({
                "uuid"  => item["uuid"],
                "item"  => item,
                "left"  => nil,
                "right" => nil
            })
        end
        treenode = JSON.parse(TheTree::getBlobOrNull(hash1))
        if treenode["uuid"] == item["uuid"] then
            treenode["item"] = item
            return TheTree::commit_treenode_to_datablobs_repository(treenode)
        end
        if item["uuid"] < treenode["uuid"] then
            treenode["left"] = TheTree::inject_item_at_hash(item, treenode["left"])
            return TheTree::commit_treenode_to_datablobs_repository(treenode)
        end
        if item["uuid"] > treenode["uuid"] then
            treenode["right"] = TheTree::inject_item_at_hash(item, treenode["right"])
            return TheTree::commit_treenode_to_datablobs_repository(treenode)
        end
        raise "[d538cdbd] How did that happen ? 🤔 item: #{item}, hash: #{hash1}, treenode: #{treenode}"
    end

    # TheTree::destroy_item_at_hash(uuid, hash1) -> hash
    def self.destroy_item_at_hash(uuid, hash1)
        return nil if hash1.nil?
        treenode = JSON.parse(TheTree::getBlobOrNull(hash1))
        if treenode["uuid"] == uuid then
            treenode["item"] = nil
            return TheTree::commit_treenode_to_datablobs_repository(treenode)
        end
        if item["uuid"] < treenode["uuid"] then
            treenode["left"] = TheTree::destroy_item_at_hash(item, treenode["left"])
            return TheTree::commit_treenode_to_datablobs_repository(treenode)
        end
        if item["uuid"] > treenode["uuid"] then
            treenode["right"] = TheTree::destroy_item_at_hash(item, treenode["right"])
            return TheTree::commit_treenode_to_datablobs_repository(treenode)
        end
        raise "[8404914c] How did that happen ? 🤔 uuid: #{uuid}, hash: #{hash1}, treenode: #{treenode}"
    end

    # TheTree::mikutype_at_hash(mikuType, hash1) -> hash
    def self.mikutype_at_hash(mikuType, hash1)
        return [] if hash1.nil?
        answer = []
        treenode = JSON.parse(TheTree::getBlobOrNull(hash1))
        if treenode["item"] and treenode["item"]["mikuType"] == mikuType then
            answer << treenode["item"]
        end
        if item["uuid"] < treenode["uuid"] then
            TheTree::mikutype_at_hash(mikuType, treenode["left"]).each{|item|
                answer << item
            }
        end
        if item["uuid"] > treenode["uuid"] then
            TheTree::mikutype_at_hash(mikuType, treenode["right"]).each{|item|
                answer << item
            }
        end
        answer
    end

    # TheTree::items_at_hash(hash1) -> hash
    def self.items_at_hash(hash1)
        return [] if hash1.nil?
        answer = []
        treenode = JSON.parse(TheTree::getBlobOrNull(hash1))
        if treenode["item"] then
            answer << treenode["item"]
        end
        if item["uuid"] < treenode["uuid"] then
            TheTree::items_at_hash(treenode["left"]).each{|item|
                answer << item
            }
        end
        if item["uuid"] > treenode["uuid"] then
            TheTree::items_at_hash(treenode["right"]).each{|item|
                answer << item
            }
        end
        answer
    end

    # ------------------------------------------------------------------
    # interface

    # TheTree::inject_item(item)
    def self.inject_item(item)
        roothash1, filepath1 = TheTree::get_roothash()
        roothash2 = TheTree::inject_item_at_hash(item, roothash1)
        TheTree::replace_root_hashes(filepath1, roothash1, roothash2)
    end

    # TheTree::delete_item(uuid)
    def self.delete_item(uuid)
        roothash1, filepath1 = TheTree::get_roothash()
        roothash2 = TheTree::destroy_item_at_hash(uuid, roothash1)
        TheTree::replace_root_hashes(filepath1, roothash1, roothash2)
    end

    # Blades::mikuType(mikuType) -> Array[Item]
    def self.mikuType(mikuType)
        roothash1, filepath1 = TheTree::get_roothash()
        roothash2 = TheTree::mikutype_at_hash(mikuType, roothash1)
        TheTree::replace_root_hashes(filepath1, roothash1, roothash2)
    end

    # Blades::items() -> Array[Item]
    def self.items()
        roothash1, filepath1 = TheTree::get_roothash()
        roothash2 = TheTree::items_at_hash(roothash1)
        TheTree::replace_root_hashes(filepath1, roothash1, roothash2)
    end

    # ------------------------------------------------------------------
    # operations

    # TheTree::dive(hash1 = nil)
    def self.dive(hash1)
        if hash1.nil? then
            roothash1, filepath1 = TheTree::get_roothash()
            return TheTree::dive(roothash1)
        end
        puts "hash1: #{hash1}"
        treenode = JSON.parse(TheTree::getBlobOrNull(hash1))
        loop {
            puts JSON.pretty_generate(treenode)
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("side", ["left", "right"])
            return if option.nil?
            if option == "left" and treenode["left"] then
                TheTree::dive(treenode["left"])
            end
            if option == "right" and treenode["right"] then
                TheTree::dive(treenode["right"])
            end
        }
    end

end
