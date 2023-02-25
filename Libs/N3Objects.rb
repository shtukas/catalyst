
# create table objects (uuid string primary key, mikuType string, object string)
# File naming convention: <l22>,<l22>.sqlite

$N3Objects_Cache_MikuTypesAtFile = {}
$N3Objects_Cache_ObjectAtFile = {}

class N3Objects

    # --------------------------------------
    # Utils

    IndexSplitSymbol = ","
    IndexFileMaxCount = 122 # the original number of waves

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
        tokens = File.basename(filepath).gsub(".sqlite", "").split(IndexSplitSymbol) # we remove the .sqlite and split on `;`
        if tokens.size == 2 then
            filepath2 = "#{N3Objects::folderpath()}/#{tokens[0]}#{IndexSplitSymbol}#{CommonUtils::timeStringL22()}.sqlite" # we keep the creation l22 and set the update l22
        else
            filepath2 = "#{N3Objects::folderpath()}/#{CommonUtils::timeStringL22()}#{IndexSplitSymbol}#{CommonUtils::timeStringL22()}.sqlite"
        end
        FileUtils.mv(filepath, filepath2)
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

    # N3Objects::update(uuid, mikuType, object)
    def self.update(uuid, mikuType, object)
        filepathszero = N3Objects::getExistingFilepaths()

        if filepathszero.size < IndexFileMaxCount then
            filepath = "#{N3Objects::folderpath()}/#{CommonUtils::timeStringL22()}#{IndexSplitSymbol}#{CommonUtils::timeStringL22()}.sqlite"
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("create table objects (uuid string primary key, mikuType string, object string)", [])
            db.execute "insert into objects (uuid, mikuType, object) values (?, ?, ?)", [uuid, mikuType, JSON.generate(object)]
            db.close
            N3Objects::deleteAtFiles(filepathszero, uuid)
        else
            filepath = filepathszero.pop
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.transaction
            db.execute "delete from objects where uuid=?", [uuid]
            db.execute "insert into objects (uuid, mikuType, object) values (?, ?, ?)", [uuid, mikuType, JSON.generate(object)]
            db.commit
            db.close
            N3Objects::renameFile(filepath)
            N3Objects::deleteAtFiles(filepathszero, uuid)
        end

        while N3Objects::getExistingFilepaths().size > IndexFileMaxCount do
            filepath1, filepath2 = N3Objects::getExistingFilepaths().sort.reverse.take(2)

            filepath = "#{N3Objects::folderpath()}/#{CommonUtils::timeStringL22()}#{IndexSplitSymbol}#{CommonUtils::timeStringL22()}.sqlite"
            db3 = SQLite3::Database.new(filepath)
            db3.busy_timeout = 117
            db3.busy_handler { |count| true }
            db3.results_as_hash = true
            db3.execute("create table objects (uuid string primary key, mikuType string, object string)", [])

            # We move all the objects from db1 to db3

            db1 = SQLite3::Database.new(filepath1)
            db1.busy_timeout = 117
            db1.busy_handler { |count| true }
            db1.results_as_hash = true
            db1.execute("select * from objects", []) do |row|
                db3.execute "insert into objects (uuid, mikuType, object) values (?, ?, ?)", [row["uuid"], row["mikuType"], row["object"]] # we copy as encoded json
            end
            db1.close

            # We move all the objects from db2 to db3

            db2 = SQLite3::Database.new(filepath2)
            db2.busy_timeout = 117
            db2.busy_handler { |count| true }
            db2.results_as_hash = true
            db2.execute("select * from objects", []) do |row|
                db3.execute "insert into objects (uuid, mikuType, object) values (?, ?, ?)", [row["uuid"], row["mikuType"], row["object"]] # we copy as encoded json
            end
            db2.close

            db3.close

            # Let's now delete the two files
            FileUtils.rm(filepath1)
            FileUtils.rm(filepath2)
        end
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
