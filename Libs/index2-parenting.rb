
# create table index2 (parentuuid TEXT NOT NULL, childuuid TEXT NOT NULL, position REAL NOT NULL);

class Index2

    # ------------------------------------------------------
    # Basic IO management

    # Index2::directory()
    def self.directory()
        "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/indices/index2-parenting"
    end

    # Index2::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(Index2::directory())
            .select{|filepath| File.basename(filepath)[-8, 8] == ".sqlite3" }
    end

    # Index2::ensureContentAddressing(filepath)
    def self.ensureContentAddressing(filepath)
        filename2 = "#{Digest::SHA1.file(filepath).hexdigest}.sqlite3"
        filepath2 = "#{Index2::directory()}/#{filename2}"
        return filepath if filepath == filepath2
        FileUtils.mv(filepath, filepath2)
        filepath2
    end

    # Index2::initiateDatabaseFile() -> filepath
    def self.initiateDatabaseFile()
        filename = "#{SecureRandom.hex}.sqlite3"
        filepath = "#{Index2::directory()}/#{filename}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("create table index1 (parentuuid TEXT NOT NULL, childuuid TEXT NOT NULL, position REAL NOT NULL)", [])
        db.commit
        db.close
        Index2::ensureContentAddressing(filepath)
    end

    # Index2::extractDataFromFile(filepath)
    def self.extractDataFromFile(filepath)
        data = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from index1", []) do |row|
            data << {
                "parentuuid" => row["parentuuid"],
                "childuuid" => row["childuuid"],
                "position" => row["position"]
            }
        end
        db.close
        data
    end

    # Index2::getDatabaseFilepath()
    def self.getDatabaseFilepath()
        filepaths = Index2::filepaths()

        if filepaths.size == 0 then
            Index2::initiateDatabaseFile()
            return Index2::getDatabaseFilepath()
        end

        if filepaths.size == 1 then
            return filepaths[0]
        end

        data = filepaths
            .map{|filepath|
                Index2::extractDataFromFile(filepath)
            }
            .flatten

        # In this case filepath.size > 1
        newfilepath = Index2::initiateDatabaseFile()

        db = SQLite3::Database.new(newfilepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        data.each{|entry|
            db.execute("insert into index1 (parentuuid, childuuid, position) values (?, ?, ?)", [entry["parentuuid"], entry["childuuid"], entry["position"]])
        }
        db.commit
        db.close

        filepaths.each{|filepath|
            FileUtils::rm(filepath)
        }

        Index2::ensureContentAddressing(newfilepath)
    end

    # Index2::insertEntry(parentuuid, childuuid, position)
    def self.insertEntry(parentuuid, childuuid, position)
        filepath = Index2::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from index1 where parentuuid=? and childuuid=?", [parentuuid, childuuid])
        db.execute("insert into index1 (parentuuid, childuuid, position) values (?, ?, ?)", [parentuuid, childuuid, position])
        db.commit
        db.close
        Index2::ensureContentAddressing(filepath)
    end

    # Index2::removeIdentifierFromDatabase(uuid)
    def self.removeIdentifierFromDatabase(uuid)
        filepath = Index2::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from index1 where parentuuid=?", [uuid])
        db.execute("delete from index1 where childuuid=?", [uuid])
        db.commit
        db.close
        Index2::ensureContentAddressing(filepath)
    end

    # ------------------------------------------------------
    # Data

    # Index2::parentuuidToChildrenuuidsInOrder(parentuuid)
    def self.parentuuidToChildrenuuidsInOrder(parentuuid)
        uuids = []
        filepath = Index2::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from index1 where parentuuid=? order by position", [parentuuid]) do |row|
            uuids << row["childuuid"]
        end
        db.close
        uuids
    end

    # Index2::parentuuidToChildrenPositions(parentuuid)
    def self.parentuuidToChildrenPositions(parentuuid)
        positions = []
        filepath = Index2::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from index1 where parentuuid=? order by position", [parentuuid]) do |row|
            positions << row["position"]
        end
        db.close
        positions
    end

    # Index2::hasChildren(parentuuid)
    def self.hasChildren(parentuuid)
        answer = false
        filepath = Index2::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from index1 where parentuuid=? limit 1", [parentuuid]) do |row|
            answer = true
        end
        db.close
        answer
    end

    # Index2::parentuuidToChildrenInOrder(parentuuid)
    def self.parentuuidToChildrenInOrder(parentuuid)
        Index2::parentuuidToChildrenuuidsInOrder(parentuuid)
            .map{|uuid| Index3::itemOrNull(uuid) }
            .compact
    end

    # Index2::parentuuidToChildrenInOrderHead(parentuuid, size, selection)
    def self.parentuuidToChildrenInOrderHead(parentuuid, size, selection)
        Index2::parentuuidToChildrenuuidsInOrder(parentuuid)
            .reduce([]){|items, uuid|
                if items.size >= size then
                    items
                else
                    item = Index3::itemOrNull(uuid)
                    if item then
                        if selection.call(item) then
                            items + [item]
                        else
                            items
                        end
                    else
                        items
                    end
                end
            }
    end

    # Index2::childuuidToParentuuidOrNull(childuuid)
    def self.childuuidToParentuuidOrNull(childuuid)
        parentuuid = nil
        filepath = Index2::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from index1 where childuuid=?", [childuuid]) do |row|
            parentuuid = row["parentuuid"]
        end
        db.close
        parentuuid
    end

    # Index2::childuuidToParentOrNull(childuuid)
    def self.childuuidToParentOrNull(childuuid)
        parentuuid = Index2::childuuidToParentuuidOrNull(childuuid)
        if parentuuid.nil? then
            return nil
        end
        Index3::itemOrNull(parentuuid)
    end

    # Index2::childuuidToParentOrDefaultInfinityCore(childuuid)
    def self.childuuidToParentOrDefaultInfinityCore(childuuid)
        parentuuid = Index2::childuuidToParentuuidOrNull(childuuid)
        if parentuuid.nil? then
            Index2::insertEntry(NxCores::infinityuuid(), childuuid, 0)
            return Index3::itemOrNull(NxCores::infinityuuid())
        end
        Index3::itemOrNull(parentuuid)
    end

    # Index2::childPositionAtParentOrZero(childuuid, parentuuid)
    def self.childPositionAtParentOrZero(childuuid, parentuuid)
        position = 0
        filepath = Index2::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from index1 where parentuuid=? and childuuid=?", [parentuuid, childuuid]) do |row|
            position = row["position"]
        end
        db.close
        position
    end
end
