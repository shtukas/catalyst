
# create table objects (uuid string primary key, mikuType string, object string)
# File naming convention: <l22>,<l22>.sqlite

$N3Objects_Cache_MikuTypesAtFile = {}
$N3Objects_Cache_ObjectAtFile = {}

class N3Objects

    # --------------------------------------
    # Utils

    IndexFileCountBaseControl = 50

    # N3Objects::folderpath()
    def self.folderpath()
        "#{Config::pathToDataCenter()}/N3Objects"
    end

    # N3Objects::getExistingFilepaths()
    def self.getExistingFilepaths()
        LucilleCore::locationsAtFolder("#{N3Objects::folderpath()}")
            .select{|filepath| filepath[-7, 7] == ".sqlite" }
    end

    # N3Objects::renameFile(filepath)
    def self.renameFile(filepath)
        filepathv2 = "#{N3Objects::folderpath()}/#{File.basename(filepath)[0, 22]}-#{CommonUtils::timeStringL22()}.sqlite3"
        FileUtils.mv(filepath, filepathv2)
    end

    # N3Objects::fileCardinal(filepath)
    def self.fileCardinal(filepath)
        count = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select count(*) as _count_ from objects", []) do |row|
            count = row["_count_"]
        end
        db.close
        count
    end

    # N3Objects::fileCarries(filepath, uuid)
    def self.fileCarries(filepath, uuid)
        flag = false
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select uuid from objects where uuid=?", [uuid]) do |row|
            flag = true
        end
        db.close
        flag
    end

    # N3Objects::deleteAtFilepath(filepath, uuid)
    def self.deleteAtFilepath(filepath, uuid)
        return if !N3Objects::fileCarries(filepath, uuid)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from objects where uuid=?", [uuid]
        db.close
        if N3Objects::fileCardinal(filepath) > 0 then
            N3Objects::renameFile(filepath)
        else
            FileUtils.rm(filepath)
        end
    end

    # N3Objects::deleteAtFiles(filepaths, uuid)
    def self.deleteAtFiles(filepaths, uuid)
        filepaths.each{|filepath|
            N3Objects::deleteAtFilepath(filepath, uuid)
        }
    end

    # N3Objects::fileManagement()
    def self.fileManagement()
        if N3Objects::getExistingFilepaths().size > IndexFileCountBaseControl * 2 then

            puts "N3Objects file management".green

            while N3Objects::getExistingFilepaths().size > IndexFileCountBaseControl do

                # We are taking the first two files (therefore the two oldest files and emptying the oldest)

                filepath1, filepath2 = N3Objects::getExistingFilepaths().sort.take(2)

                uuidExistsAtFile = lambda {|db, uuid|
                    flag = false
                    db.busy_timeout = 117
                    db.busy_handler { |count| true }
                    db.results_as_hash = true
                    db.execute("select uuid from objects where uuid=?", [uuid]) do |row|
                        flag = true
                    end
                    flag
                }

                db1 = SQLite3::Database.new(filepath1)
                db2 = SQLite3::Database.new(filepath2)

                # We move all the objects from db1 to db2

                db1.busy_timeout = 117
                db1.busy_handler { |count| true }
                db1.results_as_hash = true
                db1.execute("select * from objects", []) do |row|
                    next if uuidExistsAtFile.call(db2, row["uuid"]) # The assumption is that the one in file2 is newer
                    db2.execute "insert into objects (uuid, mikuType, object) values (?, ?, ?)", [row["uuid"], row["mikuType"], row["object"]] # we copy as encoded json
                end

                db1.close
                db2.close

                # Let's now delete the two files
                FileUtils.rm(filepath1)
                N3Objects::renameFile(filepath2)
            end
        end
    end

    # N3Objects::update(uuid, mikuType, object)
    def self.update(uuid, mikuType, object)

        # Make a record of the existing files
        filepathszero = N3Objects::getExistingFilepaths()

        # Make a new file for the object
        filepath = "#{N3Objects::folderpath()}/#{CommonUtils::timeStringL22()}-#{CommonUtils::timeStringL22()}.sqlite"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table objects (uuid string primary key, mikuType string, object string)", [])
        db.execute "insert into objects (uuid, mikuType, object) values (?, ?, ?)", [uuid, mikuType, JSON.generate(object)]
        db.close

        # Remove the object from the previously existing files
        N3Objects::deleteAtFiles(filepathszero, uuid)
    end

    # N3Objects::getMikuTypeAtFile(mikuType, filepath)
    def self.getMikuTypeAtFile(mikuType, filepath)
        cachekey = "#{mikuType}:#{filepath}"
        if $N3Objects_Cache_MikuTypesAtFile[cachekey] then
            return $N3Objects_Cache_MikuTypesAtFile[cachekey].clone
        end

        objects = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from objects where mikuType=?", [mikuType]) do |row|
            objects << JSON.parse(row["object"])
        end
        db.close

        $N3Objects_Cache_MikuTypesAtFile[cachekey] = objects

        objects
    end

    # N3Objects::getAtFilepathOrNull(uuid, filepath)
    def self.getAtFilepathOrNull(uuid, filepath)
        key = "#{uuid}:#{filepath}"
        if $N3Objects_Cache_ObjectAtFile[key] then
            object = $N3Objects_Cache_ObjectAtFile[key].clone
            return ( object == "null" ? nil : object )
        end

        object = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from objects where uuid=?", [uuid]) do |row|
            object = JSON.parse(row["object"])
        end
        db.close

        $N3Objects_Cache_ObjectAtFile[key] = ( object ? object : "null" )

        object
    end

    # N3Objects::getall()
    def self.getall()
        objects = []
        N3Objects::getExistingFilepaths().each{|filepath|
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from objects", []) do |row|
                objects << JSON.parse(row["object"])
            end
            db.close
        }
        objects
    end

    # --------------------------------------
    # Interface

    # N3Objects::commit(object)
    def self.commit(object)
        if object["uuid"].nil? then
            raise "object is missing uuid: #{JSON.pretty_generate(object)}"
        end
        if object["mikuType"].nil? then
            raise "object is missing mikuType: #{JSON.pretty_generate(object)}"
        end
        N3Objects::update(object["uuid"], object["mikuType"], object)
    end

    # N3Objects::getOrNull(uuid)
    def self.getOrNull(uuid)
        object = nil
        N3Objects::getExistingFilepaths().each{|filepath|
            object = N3Objects::getAtFilepathOrNull(uuid, filepath)
            break if object
        }
        object
    end

    # N3Objects::getMikuType(mikuType)
    def self.getMikuType(mikuType)
        objects = []
        N3Objects::getExistingFilepaths().each{|filepath|
            N3Objects::getMikuTypeAtFile(mikuType, filepath).each{|object|
                objects << object
            }
        }
        objects
    end

    # N3Objects::getMikuTypeCount(mikuType)
    def self.getMikuTypeCount(mikuType)
        count = 0
        N3Objects::getExistingFilepaths().each{|filepath|
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select count(*) as _count_ from objects where mikuType=?", [mikuType]) do |row|
                count = count + row["_count_"]
            end
            db.close
        }
        count
    end

    # N3Objects::destroy(uuid)
    def self.destroy(uuid)
        filepaths = N3Objects::getExistingFilepaths()
        N3Objects::deleteAtFiles(filepaths, uuid)
    end
end
