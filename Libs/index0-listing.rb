
# create table listing (itemuuid TEXT NOT NULL, unixtime REAL NOT NULL, item TEXT NOT NULL, line TEXT NOT NULL, clique TEXT NOT NULL);

class Index0

    # ------------------------------------------------------
    # Basic IO management

    # Index0::directory()
    def self.directory()
        "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/indices/index0-listing"
    end

    # Index0::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(Index0::directory())
            .select{|filepath| File.basename(filepath)[-8, 8] == ".sqlite3" }
    end

    # Index0::ensureContentAddressing(filepath)
    def self.ensureContentAddressing(filepath)
        filename2 = "#{Digest::SHA1.file(filepath).hexdigest}.sqlite3"
        filepath2 = "#{Index0::directory()}/#{filename2}"
        return filepath if filepath == filepath2
        FileUtils.mv(filepath, filepath2)
        filepath2
    end

    # Index0::initiateDatabaseFile() -> filepath
    def self.initiateDatabaseFile()
        filename = "#{SecureRandom.hex}.sqlite3"
        filepath = "#{Index0::directory()}/#{filename}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("create table listing (itemuuid TEXT NOT NULL, unixtime REAL NOT NULL, item TEXT NOT NULL, line TEXT NOT NULL, clique TEXT NOT NULL)", [])
        db.commit
        db.close
        Index0::ensureContentAddressing(filepath)
    end

    # Index0::extractDataFromFileEntriesInOrder(filepath)
    def self.extractDataFromFileEntriesInOrder(filepath)
        data = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from listing order by unixtime", []) do |row|
            data << {
                "itemuuid" => row["itemuuid"],
                "unixtime" => row["unixtime"],
                "item"     => JSON.parse(row["item"]),
                "line"     => row["line"],
                "clique"   => row["clique"],
            }
        end
        db.close
        data
    end

    # Index0::getReducedDatabaseFilepath()
    def self.getReducedDatabaseFilepath()
        filepaths = Index0::filepaths()

        if filepaths.size == 0 then
            return Index0::initiateDatabaseFile()
        end

        if filepaths.size == 1 then
            return filepaths[0]
        end

        data = filepaths
            .map{|filepath|
                Index0::extractDataFromFileEntriesInOrder(filepath)
            }
            .flatten
            .sort_by{|entry| entry["unixtime"] }
            .reduce([]){|entries, entry|
                if entries.map{|e| e["itemuuid"] }.include?(entry["itemuuid"]) then
                    entries
                else
                    entries + [entry]
                end
            }

        # In this case filepath.size > 1
        newfilepath = Index0::initiateDatabaseFile()

        db = SQLite3::Database.new(newfilepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        data.each{|entry|
            db.execute("insert into listing (itemuuid, unixtime, item, line) values (?, ?, ?, ?)", [entry["itemuuid"], entry["unixtime"], entry["item"], entry["line"]])
        }
        db.commit
        db.close

        filepaths.each{|filepath|
            FileUtils::rm(filepath)
        }

        Index0::ensureContentAddressing(newfilepath)
    end

    # --------------------------------------------------
    # setters and updates

    # Index0::insertEntry(itemuuid, unixtime, item, line, clique)
    def self.insertEntry(itemuuid, unixtime, item, line, clique)
        filepath = Index0::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from listing where itemuuid=?", [itemuuid])
        db.execute("insert into listing (itemuuid, unixtime, item, line, clique) values (?, ?, ?, ?, ?)", [itemuuid, unixtime, JSON.generate(item), line, clique])
        db.commit
        db.close
        Index0::ensureContentAddressing(filepath)
    end

    # Index0::removeEntry(itemuuid)
    def self.removeEntry(itemuuid)
        filepath = Index0::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from listing where itemuuid=?", [itemuuid])
        db.commit
        db.close
        Index0::ensureContentAddressing(filepath)
    end

    # Index0::updateUnixtime(itemuuid, unixtime)
    def self.updateUnixtime(itemuuid, unixtime)
        filepath = Index0::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("update listing set unixtime = ? where itemuuid = ?", [unixtime, itemuuid])
        db.commit
        db.close
        Index0::ensureContentAddressing(filepath)
    end

    # Index0::updateRecord(itemuuid, item, line, clique)
    def self.updateRecord(itemuuid, item, line, clique)
        filepath = Index0::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("update listing set item=?, line=?, clique=? where itemuuid=?", [JSON.generate(item), line, clique, itemuuid])
        db.commit
        db.close
        Index0::ensureContentAddressing(filepath)
    end

    # Index0::updateEntry(itemuuid)
    def self.updateEntry(itemuuid)
        item = Items::itemOrNull(itemuuid)
        line = Index0::decideLine(item)
        filepath = Index0::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("update listing set item=?, line=? where itemuuid=?", [JSON.generate(item), line, itemuuid])
        db.commit
        db.close
        Index0::ensureContentAddressing(filepath)
    end

    # ------------------------------------------------------
    # Decisions

    # Index0::decideLine(item)
    def self.decideLine(item)
        return nil if item.nil?
        hasChildren = Index2::hasChildren(item["uuid"]) ? " [children]".red : ""
        impt = item["nx2290-important"] ? " [important]".red : ""
        line = "STORE-PREFIX #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{DoNotShowUntil::suffix2(item)}#{impt}#{hasChildren}"

        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end

        if NxBalls::itemIsActive(item) then
            line = line.green
        end

        line
    end

    # Index0::decideClique(item)
    def self.decideClique(item)

        # - prelude

        if item["mikuType"] == "NxAnniversary" then
            return "prelude"
        end

        if item["mikuType"] == "Wave" and item["interruption"] then
            return "prelude"
        end

        if item["mikuType"] == "NxLine" then
            return "prelude"
        end

        # - today

        if item["mikuType"] == "NxBackup" then
            return "today"
        end

        if item["mikuType"] == "NxDated" then
            return "today"
        end

        if item["mikuType"] == "NxFloat" then
            return "today"
        end

        if item["mikuType"] == "NxTask" and item["important"] then
            return "today"
        end

        # - waves

        if item["mikuType"] == "Wave" then
            return "waves"
        end

        # - todos

        if item["mikuType"] == "NxTask" then
            return "todos"
        end

        if item["mikuType"] == "NxCore" then
            return "todos"
        end

        raise "(error) I do not know how to Index0::decideClique item: #{item}"
    end

    # Index0::cliquesInListingOrder()
    def self.cliquesInListingOrder()

        bratio = lambda{|clique|
            if clique == "today" then
                return Bank1::recoveredAverageHoursPerDay(clique) - 3
            end
            Bank1::recoveredAverageHoursPerDay(clique)
        }

        cliques = []

        cliques << "prelude"

        if Bank1::recoveredAverageHoursPerDay("today") < 3 then
            cliques << "today"
            cliques2 = [
                "waves",
                "todos"
            ].sort_by{|clique|
                bratio.call(clique)
            }
            return cliques + cliques2
        end

        cliques2 = [
            "today",
            "waves",
            "todos"
        ].sort_by{|clique|
            bratio.call(clique)
        }

        cliques + cliques2
    end

    # ------------------------------------------------------
    # Data

    # Index0::itemsForListing(excludeuuids)
    def self.itemsForListing(excludeuuids)
        entries = Index0::extractDataFromFileEntriesInOrder(Index0::getReducedDatabaseFilepath())
            .reject{|entry| excludeuuids.include?(entry["itemuuid"]) }
        Index0::cliquesInListingOrder().each{|clique|
            clique_entries = entries.select{|entry| entry["clique"] == clique }
            if clique_entries.size > 0 then
                return clique_entries
            end
        }
        []
    end

    # Index0::firstPositionInDatabase()
    def self.firstPositionInDatabase()
        data = Index0::itemsForListing([])
        return 1 if data.empty?
        data.map{|e| e["position"] }.min
    end

    # Index0::lastPositionInDatabase()
    def self.lastPositionInDatabase()
        data = Index0::itemsForListing([])
        return 1 if data.empty?
        themax = data.map{|e| e["position"] }.max
        return (themax + 1) if data.size == 1 # this is to prevent first and last to have the same value
        themax
    end

    # Index0::hasItem(itemuuid)
    def self.hasItem(itemuuid)
        answer = false
        filepath = Index0::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from listing where itemuuid=?", [itemuuid]) do |row|
            answer = true
        end
        db.close
        answer
    end

    # Index0::getUnixtimeOrNull(itemuuid)
    def self.getUnixtimeOrNull(itemuuid)
        unixtime = nil
        filepath = Index0::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from listing where itemuuid=?", [itemuuid]) do |row|
            unixtime = row["unixtime"]
        end
        db.close
        unixtime
    end

    # ------------------------------------------------------
    # Operations

    # Index0::listingMaintenance()
    def self.listingMaintenance()
        Listing::itemsForListing1().each{|item|
            if Index0::hasItem(item["uuid"]) then
                clique = Index0::decideClique(item)
                line = Index0::decideLine(item)
                Index0::updateRecord(item["uuid"], item, line, clique)
            else
                clique = Index0::decideClique(item)
                line = Index0::decideLine(item)
                Index0::insertEntry(item["uuid"], Time.new.to_f, item, line, clique)
            end
        }
    end
end
