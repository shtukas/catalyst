
# encoding: UTF-8

class FileSystemCheck

    # FileSystemCheck::ensureAttribute(item, attname, type)
    def self.ensureAttribute(item, attname, type)
        if item[attname].nil? then
            raise "Missing attribute #{attname} in #{JSON.pretty_generate(item)}"
        end
        if type.nil? then
            return
        end
        if type == "Number" then
            types = ["Integer", "Float"]
        else
            types = [type]
        end
        if !types.include?(item[attname].class.to_s) then
            raise "Incorrect attribute type for #{attname} in #{JSON.pretty_generate(item)}, expected: #{type}, found: #{item[attname].class.to_s}"
        end
    end

    # FileSystemCheck::phageCore(item, verbose)
    def self.phageCore(item, verbose)

        if verbose then
            "FileSystemCheck::phageCore(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        FileSystemCheck::ensureAttribute(item, "uuid", "String")
        FileSystemCheck::ensureAttribute(item, "phage_uuid", "String")
        FileSystemCheck::ensureAttribute(item, "phage_time", "Number")
        FileSystemCheck::ensureAttribute(item, "phage_alive", nil)
        FileSystemCheck::ensureAttribute(item, "mikuType", "String")
        FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
        FileSystemCheck::ensureAttribute(item, "datetime", "String")
    end

    # FileSystemCheck::fsck_Nx11E(item, verbose)
    def self.fsck_Nx11E(item, verbose)
        if verbose then
            puts "FileSystemCheck::fsck_Nx11E(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"] != "Nx11E" then
            raise "Incorrect Miku type for function"
        end

        FileSystemCheck::ensureAttribute(item, "uuid", "String")

        if item["type"] == "hot" then
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            return
        end

        if item["type"] == "triage" then
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            return
        end

        if item["type"] == "ordinal" then
            FileSystemCheck::ensureAttribute(item, "ordinal", "Number")
            return
        end

        if item["type"] == "ondate" then
            FileSystemCheck::ensureAttribute(item, "datetime", "String")
            return
        end

        if item["type"] == "standard" then
            FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
            return
        end

        raise "(error: 2a5f46bd-c5db-48e7-a20f-4dd079868948)"
    end

    # FileSystemCheck::fsck_Nx113(item, runhash, verbose)
    def self.fsck_Nx113(item, runhash, verbose)
        return if item.nil?

        repeatKey = "#{runhash}:#{item}"
        return if XCache::getFlag(repeatKey)

        if verbose then
            puts "FileSystemCheck::fsck_Nx113(#{JSON.pretty_generate(item)}, #{runhash}, #{verbose})"
        end

        if item["mikuType"] != "Nx113" then
            raise "Incorrect Miku type for function"
        end

        if item["type"].nil? then
            raise "Nx113 doesn't have a type"
        end

        type = item["type"]

        if type == "text" then
            XCache::setFlag(repeatKey, true)
            return
        end

        if type == "url" then
            XCache::setFlag(repeatKey, true)
            return
        end

        if type == "file" then
            if item["dottedExtension"].nil? then
                 raise "dottedExtension is not defined on #{item}"
            end
            if item["nhash"].nil? then
                 raise "nhash is not defined on #{item}"
            end
            if item["parts"].nil? then
                 raise "parts is not defined on #{item}"
            end
            if item["database"].nil? then
                 raise "database is not defined on #{item}"
            end
            dottedExtension  = item["dottedExtension"]
            nhash            = item["nhash"]
            parts            = item["parts"]
            database         = item["database"]
            databasefilepath = DataStore1::getNearestFilepathForReadingErrorIfNotAcquisable(database, false)
            operator         = DataStore2SQLiteBlobStoreElizabethReadOnly.new(databasefilepath)
            status = PrimitiveFiles::fsckPrimitiveFileDataRaiseAtFirstError(operator, dottedExtension, nhash, parts, verbose)
            if !status then
                puts JSON.pretty_generate(item)
                raise "(error: 3e428541-805b-455e-b6a2-c400a6519aef) primitive file fsck failed"
            end
            XCache::setFlag(repeatKey, true)
            return
        end

        if type == "aion-point" then
            if item["rootnhash"].nil? then
                 raise "rootnhash is not defined on #{item}"
            end
            if item["database"].nil? then
                 raise "database is not defined on #{item}"
            end
            rootnhash        = item["rootnhash"]
            database         = item["database"]
            databasefilepath = DataStore1::getNearestFilepathForReadingErrorIfNotAcquisable(database, false)
            operator         = DataStore2SQLiteBlobStoreElizabethReadOnly.new(databasefilepath)
            status = AionFsck::structureCheckAionHash(operator, rootnhash)
            if !status then
                puts JSON.pretty_generate(item)
                raise "(error: 50daf867-0dab-47d9-ae79-d8e431650eab) aion structure fsck failed "
            end
            XCache::setFlag(repeatKey, true)
            return
        end

        if type == "Dx8Unit" then
            XCache::setFlag(repeatKey, true)
            return
        end

        if type == "unique-string" then
            XCache::setFlag(repeatKey, true)
            return
        end

        puts "FileSystemCheck::fsckNx113(#{JSON.pretty_generate(item)}, #{verbose})"
        raise "Unsupported Nx113 type: #{type}"
    end

    # FileSystemCheck::fsck_Cx22(item, verbose)
    def self.fsck_Cx22(item, verbose)
        return if item.nil?

        if verbose then
            puts "FileSystemCheck::fsck_Cx22(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        FileSystemCheck::phageCore(item, verbose)

        if item["mikuType"] != "Cx22" then
            raise "Incorrect Miku type for function"
        end

        FileSystemCheck::ensureAttribute(item, "description", "String")
        FileSystemCheck::ensureAttribute(item, "bankaccount", "String")
        FileSystemCheck::ensureAttribute(item, "ax39", "Hash")
    end

    # FileSystemCheck::fsck_Cx23(item, verbose)
    def self.fsck_Cx23(item, verbose)
        return if item.nil?

        if verbose then
            puts "FileSystemCheck::fsck_Cx23(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"] != "Cx23" then
            raise "Incorrect Miku type for function"
        end

        FileSystemCheck::ensureAttribute(item, "groupuuid", "String")
        FileSystemCheck::ensureAttribute(item, "position", "Number")
    end

    # FileSystemCheck::fsck_Dx33(item, verbose)
    def self.fsck_Dx33(item, verbose)
        return if item.nil?

        if verbose then
            puts "FileSystemCheck::fsck_Dx33(#{JSON.pretty_generate(item)}, #{verbose})"
        end

        if item["mikuType"] != "Dx33" then
            raise "Incorrect Miku type for function"
        end

        FileSystemCheck::ensureAttribute(item, "unitId", "String")
    end

    # FileSystemCheck::fsck_TxBankEvent(item, runhash, verbose)
    def self.fsck_TxBankEvent(item, runhash, verbose)
        repeatKey = "#{runhash}:#{JSON.generate(item)}"
        return if XCache::getFlag(repeatKey)

        if verbose then
            puts "FileSystemCheck::fsck_TxBankEvent(#{JSON.pretty_generate(item)}, #{runhash}, #{verbose})"
        end

        FileSystemCheck::phageCore(item, verbose)

        if item["mikuType"] != "TxBankEvent" then
            raise "Incorrect Miku type for function"
        end
        FileSystemCheck::ensureAttribute(item, "setuuid", "String")
        FileSystemCheck::ensureAttribute(item, "unixtime", "Number")
        FileSystemCheck::ensureAttribute(item, "date", "String")
        FileSystemCheck::ensureAttribute(item, "weight", "Number")

        XCache::setFlag(repeatKey, true)
    end

    # FileSystemCheck::fsck_NxGraphEdge1(item, runhash, verbose)
    def self.fsck_NxGraphEdge1(item, runhash, verbose)
        repeatKey = "#{runhash}:#{JSON.generate(item)}"
        return if XCache::getFlag(repeatKey)

        if verbose then
            puts "FileSystemCheck::fsck_NxGraphEdge1(#{JSON.pretty_generate(item)}, #{runhash}, #{verbose})"
        end

        FileSystemCheck::phageCore(item, verbose)

        if item["mikuType"].nil? then
            raise "item has no Miku type"
        end
        if item["mikuType"] != "NxGraphEdge1" then
            raise "Incorrect Miku type for function"
        end
        FileSystemCheck::ensureAttribute(item, "uuid1", "String")
        FileSystemCheck::ensureAttribute(item, "uuid2", "String")
        FileSystemCheck::ensureAttribute(item, "type", "String")
        if !["bidirectional", "arrow", "none"].include?(item["type"]) then
            raise "incorrect value for type: #{item["type"]}"
        end

        XCache::setFlag(repeatKey, true)
    end

    # FileSystemCheck::fsck_PhageItem(item, runhash, verbose)
    def self.fsck_PhageItem(item, runhash, verbose)

        repeatKey = "#{runhash}:#{JSON.generate(item)}"
        return if XCache::getFlag(repeatKey)

        if verbose then
            puts "FileSystemCheck::fsck_PhageItem(#{JSON.pretty_generate(item)}, #{runhash}, #{verbose})"
        end

        FileSystemCheck::phageCore(item, verbose)

        mikuType = item["mikuType"]

        if mikuType == "Cx22" then
            FileSystemCheck::fsck_Cx22(item, verbose)
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "Dx33" then
            FileSystemCheck::fsck_Dx33(item, verbose)
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "NxAnniversary" then
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::ensureAttribute(item, "startdate", "String")
            FileSystemCheck::ensureAttribute(item, "repeatType", "String")
            FileSystemCheck::ensureAttribute(item, "lastCelebrationDate", "String")
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "NxBall.v2" then
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::ensureAttribute(item, "desiredBankedTimeInSeconds", "Number")
            FileSystemCheck::ensureAttribute(item, "status", "Hash")
            FileSystemCheck::ensureAttribute(item, "accounts", "Array")
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "NxLine" then
            FileSystemCheck::ensureAttribute(item, "line", "String")
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "NxTodo" then
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::ensureAttribute(item, "nx11e", "Hash")
            FileSystemCheck::fsck_Nx11E(item["nx11e"], verbose)
            FileSystemCheck::fsck_Nx113(item["nx113"], runhash, verbose)
            FileSystemCheck::fsck_Cx23(item["cx23"], verbose)
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "NxGraphEdge1" then
            FileSystemCheck::fsck_NxGraphEdge1(item, runhash, verbose)
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "NyxNode" then
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::fsck_Nx113(item["nx113"], runhash, verbose)
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "TxBankEvent" then
            FileSystemCheck::ensureAttribute(item, "setuuid", "String")
            FileSystemCheck::ensureAttribute(item, "date", "String")
            FileSystemCheck::ensureAttribute(item, "weight", "Number")
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "TxManualCountDown" then
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::ensureAttribute(item, "dailyTarget", "Number")
            FileSystemCheck::ensureAttribute(item, "date", "String")
            FileSystemCheck::ensureAttribute(item, "counter", "Number")
            FileSystemCheck::fsck_Nx113(item["nx113"], runhash, verbose)
            XCache::setFlag(repeatKey, true)
            return
        end

        if mikuType == "Wave" then
            FileSystemCheck::ensureAttribute(item, "description", "String")
            FileSystemCheck::ensureAttribute(item, "nx46", "Hash")
            FileSystemCheck::ensureAttribute(item, "lastDoneDateTime", "String")
            FileSystemCheck::fsck_Nx113(item["nx113"], runhash, verbose)
            XCache::setFlag(repeatKey, true)
            return
        end

        raise "Unsupported Miku Type: #{JSON.pretty_generate(item)}"
    end

    # -----------------------------------------------------

    # FileSystemCheck::exitIfMissingCanary()
    def self.exitIfMissingCanary()
        if !File.exists?("#{Config::userHomeDirectory()}/Desktop/Pascal.png") then # We use this file to interrupt long runs at a place where it would not corrupt any file system.
            puts "Interrupted after missing canary file.".green
            exit
        end
    end

    # FileSystemCheck::getExistingRunHash()
    def self.getExistingRunHash()
        runhash = XCache::getOrNull("371dbc1d-8fbc-498b-ac98-d17d978cfdbf")
        if runhash.nil? then
            runhash = SecureRandom.hex
            XCache::set("371dbc1d-8fbc-498b-ac98-d17d978cfdbf", runhash)
        end
        runhash
    end

    # FileSystemCheck::setRunHash(runhash)
    def self.setRunHash(runhash)
        XCache::set("371dbc1d-8fbc-498b-ac98-d17d978cfdbf", runhash)
    end

    # FileSystemCheck::fsckErrorAtFirstFailure(runhash)
    def self.fsckErrorAtFirstFailure(runhash)
        PhageInternals::variantsEnumerator().each{|item|
            FileSystemCheck::exitIfMissingCanary()
            FileSystemCheck::fsck_PhageItem(item, runhash, true)
        }
        puts "fsck completed successfully".green
    end
end
