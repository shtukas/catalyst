# encoding: UTF-8

class Blades

    # -----------------------------------------------
    # Core

    # Blades::rename_blade_file(filepath1)
    def self.rename_blade_file(filepath1)
        item = Blades::readItemFromBladeFile(filepath1)
        filepath2 = "#{File.dirname(filepath1)}/#{SecureRandom.hex(6)}.catalyst-blade"
        FileUtils.mv(filepath1, filepath2)
        XCache::set("uuid-to-filepath-4eed-afdb-a241e01d0e86:#{item["uuid"]}", filepath2)
    end

    # Blades::blades_repository()
    def self.blades_repository()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/Catalyst/data/Blades"
    end

    # Blades::blade_filepaths_enumeration()
    def self.blade_filepaths_enumeration()
        Enumerator.new do |filepaths|
            Find.find(Blades::blades_repository()) do |path|
                if File.basename(path)[-15, 15] == ".catalyst-blade" then
                    filepaths << path
                end
            end
        end
    end

    # Blades::uuidToBladeFilepathOrNull_UseTheForce(uuid) -> filepath or nil
    def self.uuidToBladeFilepathOrNull_UseTheForce(uuid)
        Blades::blade_filepaths_enumeration().each{|filepath|
            item = Blades::readItemFromBladeFile(filepath)
            if item["uuid"] == uuid then
                return filepath
            end
        }
        nil
    end

    # Blades::uuidToBladeFilepathOrNull(uuid) -> filepath or nil
    def self.uuidToBladeFilepathOrNull(uuid)
        # Takes a uuid and return the filepath to the blade if it could find it
        filepath = XCache::getOrNull("uuid-to-filepath-4eed-afdb-a241e01d0e86:#{uuid}")
        if filepath then
            if File.exist?(filepath) then
                item = Blades::readItemFromBladeFile(filepath)
                if item["uuid"] == uuid then
                    return filepath
                end
            end
        end
        filepath = Blades::uuidToBladeFilepathOrNull_UseTheForce(uuid)
        if filepath then
            XCache::set("uuid-to-filepath-4eed-afdb-a241e01d0e86:#{uuid}", filepath)
        end
        filepath
    end

    # Blades::readItemFromBladeFile(filepath)
    def self.readItemFromBladeFile(filepath)
        item = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from blade where _key_=?", ["item"]) do |row|
            item = JSON.parse(row["_data_"])
        end
        db.close
        if item.nil? then
            raise "This is an extremelly odd condition. This blade file doesn't have an item, filepath: #{filepath}"
        end
        item
    end

    # Blades::commitItemToItsBladeFile(item)
    def self.commitItemToItsBladeFile(item)
        filepath = Blades::uuidToBladeFilepathOrNull(item["uuid"])
        if filepath.nil? then
            raise "(error: 192ba5e3) I could not find a blade file for item: #{item}"
        end
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from blade where _key_=?", ["item"])
        db.execute("insert into blade (_key_, _data_) values (?, ?)", ["item", JSON.generate(item)])
        db.commit
        db.close
        Blades::rename_blade_file(filepath)
    end

    # -----------------------------------------------
    # Interface

    # Blades::spawn_new_blade(uuid)
    def self.spawn_new_blade(uuid)

        filename = "#{SecureRandom.hex(6)}.catalyst-blade"
        filepath = "#{Blades::blades_repository()}/#{filename}"

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("create table blade (_key_ TEXT primary key, _data_ BLOB);", [])
        db.commit
        db.close

        item = {
          "uuid" => uuid,
          "mikuType" => "NxFloat",
          "unixtime" => 1749022592,
          "datetime" => "2025-06-04T07:36:32Z",
          "description" => "be awesome"
        }

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from blade where _key_=?", ["item"])
        db.execute("insert into blade (_key_, _data_) values (?, ?)", ["item", JSON.generate(item)])
        db.commit
        db.close

        XCache::set("uuid-to-filepath-4eed-afdb-a241e01d0e86:#{uuid}", filepath)

        filepath
    end

    # Blades::getItemOrNull(uuid) -> item or nil
    def self.getItemOrNull(uuid)
        filepath = Blades::uuidToBladeFilepathOrNull(uuid)
        return nil if filepath.nil?
        Blades::readItemFromBladeFile(filepath)
    end

    # Blades::destroy(uuid) -> item or nil
    def self.destroy(uuid)
        filepath = Blades::uuidToBladeFilepathOrNull(uuid)
        if filepath then
            FileUtils.rm(filepath)
        end
    end

    # Blades::items_enumerator()
    def self.items_enumerator()
        Enumerator.new do |items|
            Blades::blade_filepaths_enumeration().each{|filepath|
                begin
                    items << Blades::readItemFromBladeFile(filepath)
                rescue
                end
                
            }
        end
    end

    # Blades::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        item = Blades::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 9c438e85) I could not find an item for uuid: #{uuid}"
        end
        item[attrname] = attrvalue
        Blades::commitItemToItsBladeFile(item)
    end

    # Blades::putBlob(uuid, datablob)
    def self.putBlob(uuid, datablob)
        filepath = uuidToBladeFilepathOrNull(uuid)
        if filepath.nil? then
            raise "(error: 1e1a1a4b) could not find the filepath for uuid: #{uuid}"
        end
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from blade where _key_=?", [nhash])
        db.execute("insert into blade (_key_, _data_) values (?, ?)", [nhash, datablob])
        db.commit
        db.close
        nhash
    end

    # Blades::getBlob(uuid, nhash)
    def self.getBlob(uuid, nhash)
        filepath = uuidToBladeFilepathOrNull(uuid)
        if filepath.nil? then
            raise "(error: ed215999) could not find the filepath for uuid: #{uuid}"
        end
        datablob = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from blade where _key_=?", [nhash]) do |row|
            datablob = row["_data_"]
        end
        db.close
        if datablob and "SHA256-#{Digest::SHA256.hexdigest(datablob)}" != nhash then
            raise "This is an extremelly odd condition. Retrived the datablob, but its nhash doens't check. uuid: #{uuid}, nhash: #{nhash}"
        end
        datablob
    end

    # Blades::commitItemToDisk(item)
    def self.commitItemToDisk(item)
        blade_filepath = Blades::uuidToBladeFilepathOrNull(item["uuid"])
        if blade_filepath.nil? then
            # We do not have a file yet. Let's make one
            blade_filepath = Blades::spawn_new_blade(item["uuid"])
        end
        Blades::commitItemToItsBladeFile(item)
    end
end

class ElizabethBlade

    def initialize(uuid)
        @uuid = uuid
    end

    def putBlob(datablob) # nhash
        Blades::putBlob(@uuid, datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        Blades::getBlob(@uuid, nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        raise "(error: ff339aa3-b7ea-4b92-a211-5fc1048c048b, nhash: #{nhash})"
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 900a9a53-66a3-4860-be5e-dffa7a88c66d) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
