
# create table index2 (parentuuid TEXT NOT NULL, childuuid TEXT NOT NULL, position REAL NOT NULL);

class Parenting

    # ------------------------------------------------------
    # Basic IO management

    # Parenting::directory()
    def self.directory()
        "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/databases/index2-parenting"
    end

    # Parenting::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(Parenting::directory())
            .select{|filepath| File.basename(filepath)[-8, 8] == ".sqlite3" }
    end

    # Parenting::ensureContentAddressing(filepath)
    def self.ensureContentAddressing(filepath)
        filename2 = "#{Digest::SHA1.file(filepath).hexdigest}.sqlite3"
        filepath2 = "#{Parenting::directory()}/#{filename2}"
        return filepath if filepath == filepath2
        FileUtils.mv(filepath, filepath2)
        filepath2
    end

    # Parenting::initiateDatabaseFile() -> filepath
    def self.initiateDatabaseFile()
        filename = "#{SecureRandom.hex}.sqlite3"
        filepath = "#{Parenting::directory()}/#{filename}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("create table index1 (parentuuid TEXT NOT NULL, childuuid TEXT NOT NULL, position REAL NOT NULL)", [])
        db.commit
        db.close
        Parenting::ensureContentAddressing(filepath)
    end

    # Parenting::extractDataFromFile(filepath)
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

    # Parenting::getDatabaseFilepath()
    def self.getDatabaseFilepath()
        filepaths = Parenting::filepaths()

        # This case should not really happen (anymore), so if the condition 
        # is true, let's error noisily.
        if filepaths.size == 0 then
            #Parenting::initiateDatabaseFile()
            #return Parenting::getDatabaseFilepath()
            raise "(error: 7728dc35)"
        end

        if filepaths.size == 1 then
            return filepaths[0]
        end

        data = filepaths
            .map{|filepath|
                Parenting::extractDataFromFile(filepath)
            }
            .flatten

        # In this case filepath.size > 1
        newfilepath = Parenting::initiateDatabaseFile()

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

        Parenting::ensureContentAddressing(newfilepath)
    end

    # Parenting::insertEntry(parentuuid, childuuid, position)
    def self.insertEntry(parentuuid, childuuid, position)
        puts "Parenting::insertEntry: #{[parentuuid, childuuid, position].join(', ')}"
        filepath = Parenting::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from index1 where childuuid=?", [childuuid])
        db.execute("insert into index1 (parentuuid, childuuid, position) values (?, ?, ?)", [parentuuid, childuuid, position])
        db.commit
        db.close
        Parenting::ensureContentAddressing(filepath)

        if !Parenting::parentuuidToChildrenuuidsInOrder(parentuuid).include?(childuuid) then
            raise "(error: 338c4cdb) How did this happen? 🤔"
        end
    end

    # Parenting::removeIdentifierFromDatabase(uuid)
    def self.removeIdentifierFromDatabase(uuid)
        filepath = Parenting::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from index1 where parentuuid=?", [uuid])
        db.execute("delete from index1 where childuuid=?", [uuid])
        db.commit
        db.close
        Parenting::ensureContentAddressing(filepath)
    end

    # ------------------------------------------------------
    # Data

    # Parenting::parentuuidToChildrenuuidsInOrder(parentuuid)
    def self.parentuuidToChildrenuuidsInOrder(parentuuid)
        uuids = []
        filepath = Parenting::getDatabaseFilepath()
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

    # Parenting::parentuuidToChildrenPositions(parentuuid)
    def self.parentuuidToChildrenPositions(parentuuid)
        positions = []
        filepath = Parenting::getDatabaseFilepath()
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

    # Parenting::hasChildren(parentuuid)
    def self.hasChildren(parentuuid)
        answer = false
        filepath = Parenting::getDatabaseFilepath()
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

    # Parenting::parentuuidToChildrenInOrder(parentuuid)
    def self.parentuuidToChildrenInOrder(parentuuid)
        if parentuuid == NxCores::infinityuuid() then
            return Parenting::parentuuidToChildrenInOrderHead(parentuuid, 100, lambda {|item| true })
        end
        Parenting::parentuuidToChildrenuuidsInOrder(parentuuid)
            .map{|uuid| Items::itemOrNull(uuid) }
            .compact
    end

    # Parenting::parentuuidToChildrenInOrderHead(parentuuid, size, selection)
    def self.parentuuidToChildrenInOrderHead(parentuuid, size, selection)
        Parenting::parentuuidToChildrenuuidsInOrder(parentuuid)
            .reduce([]){|items, uuid|
                if items.size >= size then
                    items
                else
                    item = Items::itemOrNull(uuid)
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

    # Parenting::childuuidToParentUuidOrNull(childuuid)
    def self.childuuidToParentUuidOrNull(childuuid)
        parentuuid = nil
        filepath = Parenting::getDatabaseFilepath()
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

    # Parenting::childuuidToParentOrNull(childuuid)
    def self.childuuidToParentOrNull(childuuid)
        parentuuid = Parenting::childuuidToParentUuidOrNull(childuuid)
        return nil if parentuuid.nil?
        Items::itemOrNull(parentuuid)
    end

    # Parenting::childPositionAtParentOrZero(parentuuid, childuuid)
    def self.childPositionAtParentOrZero(parentuuid, childuuid)
        position = 0
        filepath = Parenting::getDatabaseFilepath()
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

    # ------------------------------------------------------
    # Interface

    # Parenting::maintenance()
    def self.maintenance()
        archive_filepath = "#{Parenting::directory()}/archives/#{CommonUtils::today()}.sqlite3"
        if !File.exist?(archive_filepath) then
            FileUtils.cp(Parenting::getDatabaseFilepath(), archive_filepath)
        end
    end
end
