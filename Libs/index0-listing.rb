
# CREATE TABLE listing (itemuuid TEXT NOT NULL, position REAL NOT NULL, item TEXT NOT NULL, line TEXT NOT NULL);

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
        db.execute("CREATE TABLE listing (itemuuid TEXT NOT NULL, position REAL NOT NULL, item TEXT NOT NULL, line TEXT NOT NULL)", [])
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
        db.execute("select * from listing order by position", []) do |row|
            item = JSON.parse(row["item"])
            position_ = " (#{row["position"]})"
            data << {
                "itemuuid" => row["itemuuid"],
                "position" => row["position"],
                "item"     => item,
                "line"     => "#{row["line"]}#{position_.yellow}"
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
            .sort_by{|entry| entry["position"] }
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
            db.execute("insert into listing (itemuuid, position, item, line) values (?, ?, ?, ?)", [entry["itemuuid"], entry["position"], entry["item"], entry["line"]])
        }
        db.commit
        db.close

        filepaths.each{|filepath|
            FileUtils::rm(filepath)
        }

        Index0::ensureContentAddressing(newfilepath)
    end

    # ------------------------------------------------------
    # Getters

    # Index0::entriesInOrder()
    def self.entriesInOrder()
        Index0::extractDataFromFileEntriesInOrder(Index0::getReducedDatabaseFilepath())
            .sort_by{|item| item["position"] }
    end

    # Index0::entriesForListing(excludeuuids)
    def self.entriesForListing(excludeuuids)
        Index0::entriesInOrder()
            .reject{|entry| excludeuuids.include?(entry["itemuuid"]) }
    end

    # Index0::firstPositionInDatabase()
    def self.firstPositionInDatabase()
        entries = Index0::entriesInOrder()
        return 1 if entries.empty?
        entries.map{|e| e["position"] }.min
    end

    # Index0::lastPositionInDatabase()
    def self.lastPositionInDatabase()
        entries = Index0::entriesInOrder()
        return 1 if entries.empty?
        themax = entries.map{|e| e["position"] }.max
        return (themax + 1) if entries.size == 1 # this is to prevent first and last to have the same value
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

    # Index0::getPositionOrNull(itemuuid)
    def self.getPositionOrNull(itemuuid)
        position = nil
        filepath = Index0::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from listing where itemuuid=?", [itemuuid]) do |row|
            position = row["position"]
        end
        db.close
        position
    end

    # ------------------------------------------------------
    # Decisions

    # Index0::decideLine(item)
    def self.decideLine(item)
        return nil if item.nil?
        hasChildren = Index2::hasChildren(item["uuid"]) ? " [children]".red : ""
        line = "STORE-PREFIX #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{DoNotShowUntil::suffix2(item)}#{hasChildren}"

        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end

        if NxBalls::itemIsActive(item) then
            line = line.green
        end

        line
    end

    # Index0::determinePositionAfterTheLastElementOfSimilarMikuType(item)
    def self.determinePositionAfterTheLastElementOfSimilarMikuType(item)
        entries = Index0::entriesInOrder()

        loop {
            break if entries.empty?
            break if !entries.map{|entry| entry["item"]["mikuType"] }.include?(item["mikuType"]) 
            entries = entries.drop(1)
        }

        if entries.size == 0 then
            return Index0::lastPositionInDatabase() + 1
        end

        if entries.size == 1 then
            return entries["position"] + 1
        end

        if entries.size == 2 then
            return entries[1]["position"] + 1
        end

        # Entries has size at least 3
        entries = entries.drop(1)

        # Now entries has size at least 2
        0.5*( entries[0]["position"] + entries[1]["position"] )
    end

    # Index0::decidePositionOrNull(item)
    def self.decidePositionOrNull(item)
        # We return null if the item shouild not be listed at this time, because it has 
        # reached a time target or something.

        if item["mikuType"] == "NxLambda" then
            return Index0::firstPositionInDatabase() * 0.9
        end

        if item["mikuType"] == "NxFloat" then
            return Index0::determinePositionAfterTheLastElementOfSimilarMikuType(item)
        end

        if item["mikuType"] == "Wave" then
            return Index0::determinePositionAfterTheLastElementOfSimilarMikuType(item)
        end

        if item["mikuType"] == "NxCore" then
            return Index0::determinePositionAfterTheLastElementOfSimilarMikuType(item)
        end

        if item["mikuType"] == "NxTask" then
            return Index0::determinePositionAfterTheLastElementOfSimilarMikuType(item)
        end

        if item["mikuType"] == "NxProject" then
            if NxProjects::isStillUpToday(item) then
                return Index0::determinePositionAfterTheLastElementOfSimilarMikuType(item)
            end
            return nil
        end

        if item["mikuType"] == "NxLine" then
            return Index0::determinePositionAfterTheLastElementOfSimilarMikuType(item)
        end

        if item["mikuType"] == "NxDated" then
            return Index0::determinePositionAfterTheLastElementOfSimilarMikuType(item)
        end

        if item["mikuType"] == "NxAnniversary" then
            return Index0::firstPositionInDatabase() * 0.9
        end

        if item["mikuType"] == "NxBackup" then
            return Index0::determinePositionAfterTheLastElementOfSimilarMikuType(item)
        end

        puts "I do not know how to Index0::decidePositionOrNull(#{JSON.pretty_generate(item)})"
        raise "(error: 3ae9fe86)"
    end

    # --------------------------------------------------
    # Operations (1)

    # Index0::insertUpdateEntry(itemuuid, position, item, line)
    def self.insertUpdateEntry(itemuuid, position, item, line)
        filepath = Index0::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from listing where itemuuid=?", [itemuuid])
        db.execute("insert into listing (itemuuid, position, item, line) values (?, ?, ?, ?)", [itemuuid, position, JSON.generate(item), line])
        db.commit
        db.close
        Index0::ensureContentAddressing(filepath)
    end

    # Index0::decideAndUpdateItemAndLine(itemuuid)
    def self.decideAndUpdateItemAndLine(itemuuid)
        item = Items::itemOrNull(itemuuid)
        return if item.nil?
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

    # Index0::itemHasStoppedOrWasDoneOrWasDestroyed(item)
    def self.itemHasStoppedOrWasDoneOrWasDestroyed(item)
        item = Items::itemOrNull(item["uuid"])
        if item.nil? then
            Index0::removeEntry(item["uuid"])
            return
        end

        if item["mikuType"] == "NxLambda" then
            Index0::removeEntry(item["uuid"])
            return
        end

        if item["mikuType"] == "NxFloat" then
            Index0::removeEntry(item["uuid"])
            return
        end

        if item["mikuType"] == "Wave" then
            Index0::removeEntry(item["uuid"])
            return
        end

        if item["mikuType"] == "NxCore" then
            if NxCores::ratio(core) >= 1 then
                Index0::removeEntry(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            Index0::removeEntry(item["uuid"])
            return
        end

        if item["mikuType"] == "NxProject" then
            if !NxProjects::isStillUpToday(item) then
                Index0::removeEntry(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxLine" then
            Index0::removeEntry(item["uuid"])
            return
        end

        if item["mikuType"] == "NxDated" then
            Index0::removeEntry(item["uuid"])
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Index0::removeEntry(item["uuid"])
            return
        end

        if item["mikuType"] == "NxBackup" then
            Index0::removeEntry(item["uuid"])
            return
        end

        puts "I do not know how to Index0::itemHasStoppedOrWasDoneOrWasDestroyed(#{JSON.pretty_generate(item)})"
        raise "(error: 09ba2bb3)"
    end

    # ------------------------------------------------------
    # Operations (2)

    # Index0::listingMaintenance()
    def self.listingMaintenance()
        if Index0::firstPositionInDatabase() > 9 then
            filepath = Index0::getReducedDatabaseFilepath()
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("update listing set position = position/2", [])
            db.close
        end
        Listing::itemsForListing1().each{|item|
            Index0::ensureThatItemIsListedIfListable(item)
        }
    end

    # Index0::ensureThatItemIsListedIfListable(item)
    def self.ensureThatItemIsListedIfListable(item)
        return if Index0::hasItem(item["uuid"])
        puts "insert in listing: #{PolyFunctions::toString(item)}".yellow
        position = Index0::decidePositionOrNull(item)
        return if position.nil?
        line = Index0::decideLine(item)
        Index0::insertUpdateEntry(item["uuid"], position, item, line)
    end
end
