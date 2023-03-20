
# create table records (key string primary key, value string)
# File naming convention: <l22>,<l22>.sqlite

$N2KVStore_Cache_ValueAtFile = {}

class N2KVStore

    # --------------------------------------
    # Utils

    IndexFileCountControlBase = 32

    # N2KVStore::folderpath()
    def self.folderpath()
        "#{Config::pathToDataCenter()}/N2KVStore"
    end

    # N2KVStore::existingFilepaths()
    def self.existingFilepaths()
        LucilleCore::locationsAtFolder(N2KVStore::folderpath())
            .select{|filepath| filepath[-8, 8] == ".sqlite3" }
    end

    # N2KVStore::renameFile(filepath)
    def self.renameFile(filepath)
        filepath2 = "#{N2KVStore::folderpath()}/#{File.basename(filepath)[0, 22]}@#{CommonUtils::timeStringL22()}.sqlite3" # we keep the creation l22 and set the update l22
        FileUtils.mv(filepath, filepath2)
    end

    # N2KVStore::fileCardinal(filepath)
    def self.fileCardinal(filepath)
        count = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select count(*) as _count_ from records", []) do |row|
            count = row["_count_"]
        end
        db.close
        count
    end

    # N2KVStore::fileCarriesRecord(filepath, key)
    def self.fileCarriesRecord(filepath, key)
        flag = false
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select key from records where key=?", [key]) do |row|
            flag = true
        end
        db.close
        flag
    end

    # N2KVStore::deleteKeyAtFilepath(filepath, key)
    def self.deleteKeyAtFilepath(filepath, key)
        return if !N2KVStore::fileCarriesRecord(filepath, key)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from records where key=?", [key]
        db.close
        if N2KVStore::fileCardinal(filepath) > 0 then
            N2KVStore::renameFile(filepath)
        else
            FileUtils.rm(filepath)
        end
    end

    # N2KVStore::deleteKeyInFiles(filepaths, key)
    def self.deleteKeyInFiles(filepaths, key)
        filepaths.each{|filepath|
            N2KVStore::deleteKeyAtFilepath(filepath, key)
        }
    end

    # N2KVStore::getValueAtFilepathOrNull(key, filepath)
    def self.getValueAtFilepathOrNull(key, filepath)
        cachekey = "#{key}:#{filepath}"
        if $N2KVStore_Cache_ValueAtFile[cachekey] then
            value = $N2KVStore_Cache_ValueAtFile[cachekey].clone
            return ( (value == "null") ? nil : value )
        end

        value = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from records where key=?", [key]) do |row|
            value = JSON.parse(row["value"].to_s) # .to_s beccause when I migrated DoNotShowUntil, the values were stored as integers
        end
        db.close

        $N2KVStore_Cache_ValueAtFile[cachekey] = ( value ? value : "null" )

        value
    end

    # N2KVStore::fileManagement()
    def self.fileManagement()
        if N2KVStore::existingFilepaths().size > IndexFileCountControlBase * 2 then

            puts "N2KVStore file management".green

            while N2KVStore::existingFilepaths().size > IndexFileCountControlBase do
                filepath1, filepath2 = N2KVStore::existingFilepaths().sort.take(2)

                keyExistsAtFile = lambda {|db, key|
                    flag = false
                    db.busy_timeout = 117
                    db.busy_handler { |count| true }
                    db.results_as_hash = true
                    db.execute("select key from objects where key=?", [key]) do |row|
                        flag = true
                    end
                    flag
                }

                db1 = SQLite3::Database.new(filepath1)
                db2 = SQLite3::Database.new(filepath2)

                # We move all the records from db1 to db2

                db1.busy_timeout = 117
                db1.busy_handler { |count| true }
                db1.results_as_hash = true
                db1.execute("select * from records", []) do |row|
                    next if keyExistsAtFile.call(db2, row["key"]) # The assumption is that the one in file2 is newer
                    db2.execute "insert into records (key, value) values (?, ?)", [row["key"], row["value"]] # we copy the value as encoded string without decoding it
                end

                db1.close
                db2.close

                # Let's now delete the two files
                FileUtils.rm(filepath1)
                N2KVStore::renameFile(filepath2)
            end
        end
    end

    # --------------------------------------
    # Interface

    # N2KVStore::set(key, value)
    def self.set(key, value)
        filepathszero = N2KVStore::existingFilepaths()

        filepath = "#{N2KVStore::folderpath()}/#{CommonUtils::timeStringL22()}@#{CommonUtils::timeStringL22()}.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table records (key string primary key, value string)", [])
        db.execute "insert into records (key, value) values (?, ?)", [key, JSON.generate(value)]
        db.close

        N2KVStore::deleteKeyInFiles(filepathszero, key)
    end

    # N2KVStore::getOrNull(key)
    def self.getOrNull(key)
        value = nil
        N2KVStore::existingFilepaths().each{|filepath|
            value = N2KVStore::getValueAtFilepathOrNull(key, filepath)
            break if value
        }
        value
    end

    # N2KVStore::destroy(key)
    def self.destroy(key)
        N2KVStore::deleteKeyInFiles(N2KVStore::existingFilepaths(), key)
    end
end
