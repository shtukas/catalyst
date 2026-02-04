# encoding: UTF-8

require 'open3'

class CommonUtils

    # ----------------------------------------------------
    # Array Utilities

    # CommonUtils::removeDuplicateObjectsOnAttribute(items, attrname)
    def self.removeDuplicateObjectsOnAttribute(items, attrname)
        items
            .reduce([]){|selected, item|
                if selected.map{|i| i[attrname] }.include?(item[attrname]) then
                    selected
                else
                    selected + [item]
                end
            }
    end

    # ----------------------------------------------------
    # String Utilities

    # CommonUtils::sanitiseStringForFilenaming(str)
    def self.sanitiseStringForFilenaming(str)
        str
            .gsub(":", "-")
            .gsub("/", "-")
            .gsub("'", "")
            .strip
    end

    # CommonUtils::ends_with?(str, ending)
    def self.ends_with?(str, ending)
        str[-ending.size, ending.size] == ending
    end

    # CommonUtils::levenshteinDistance(s, t)
    def self.levenshteinDistance(s, t)
      # https://stackoverflow.com/questions/16323571/measure-the-distance-between-two-strings-with-ruby
      m = s.length
      n = t.length
      return m if n == 0
      return n if m == 0
      d = Array.new(m+1) {Array.new(n+1)}

      (0..m).each {|i| d[i][0] = i}
      (0..n).each {|j| d[0][j] = j}
      (1..n).each do |j|
        (1..m).each do |i|
          d[i][j] = if s[i-1] == t[j-1] # adjust index into string
                      d[i-1][j-1]       # no operation required
                    else
                      [ d[i-1][j]+1,    # deletion
                        d[i][j-1]+1,    # insertion
                        d[i-1][j-1]+1,  # substitution
                      ].min
                    end
        end
      end
      d[m][n]
    end

    # CommonUtils::stringDistance1(str1, str2)
    def self.stringDistance1(str1, str2)
        # This metric takes values between 0 and 1
        return 1 if str1.size == 0
        return 1 if str2.size == 0
        CommonUtils::levenshteinDistance(str1, str2).to_f/[str1.size, str2.size].max
    end

    # CommonUtils::stringDistance2(str1, str2)
    def self.stringDistance2(str1, str2)
        # We need the smallest string to come first
        if str1.size > str2.size then
            str1, str2 = str2, str1
        end
        diff = str2.size - str1.size
        (0..diff).map{|i| CommonUtils::levenshteinDistance(str1, str2[i, str1.size]) }.min
    end

    # CommonUtils::extract_digits(input_string)
    def self.extract_digits(input_string)
      # Use scan method with regex to find all digits
      digits = input_string.scan(/\d/)
      # Join the array of digits into a single string
      digits.join
    end

    # CommonUtils::uuidToUnitIntervalReal(uuid)
    def self.uuidToUnitIntervalReal(uuid)
        "0.#{extract_digits(uuid)}".to_f
    end

    # ----------------------------------------------------
    # Date Routines

    # CommonUtils::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # CommonUtils::isWeekday()
    def self.isWeekday()
        ![6, 0].include?(Time.new.wday)
    end

    # CommonUtils::isWeekend()
    def self.isWeekend()
        !CommonUtils::isWeekday()
    end

    # CommonUtils::todayAsLowercaseEnglishWeekDayName()
    def self.todayAsLowercaseEnglishWeekDayName()
        ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"][Time.new.wday]
    end

    # CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
    def self.interactivelyMakeUnixtimeUsingDateCodeOrNull()
        datecode = LucilleCore::askQuestionAnswerAsString("date code: +today, +tomorrow, +<weekdayname>, +<integer>hours(s), +<integer>day(s), +<integer>@HH:MM, +YYYY-MM-DD (empty to abort): ")
        unixtime = CommonUtils::codeToUnixtimeOrNull(datecode)
        return nil if unixtime.nil?
        unixtime
    end

    # CommonUtils::interactivelyMakeUnixtimeUsingDateCode()
    def self.interactivelyMakeUnixtimeUsingDateCode()
        loop {
            unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
            return unixtime if unixtime
        }
    end

    # CommonUtils::interactivelyMakeADateOrNull()
    def self.interactivelyMakeADateOrNull()
        unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
        return nil if unixtime.nil?
        Time.at(unixtime).to_s[0, 10]
    end

    # CommonUtils::interactivelyMakeADate()
    def self.interactivelyMakeADate()
        date = CommonUtils::interactivelyMakeADateOrNull()
        return date if date
        CommonUtils::interactivelyMakeADate()
    end

    # CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCodeOrNull()
    def self.interactivelyMakeDateTimeIso8601UsingDateCodeOrNull()
        unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
        return nil if unixtime.nil?
        Time.at(unixtime).utc.iso8601
    end

    # CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
    def self.interactivelyMakeDateTimeIso8601UsingDateCode()
        loop {
            code = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCodeOrNull()
            return code if code
        }
    end

    # CommonUtils::nDaysInTheFuture(n)
    def self.nDaysInTheFuture(n)
        (Time.now+86400*n).to_s[0,10]
    end

    # CommonUtils::dateIsWeekEnd(date)
    def self.dateIsWeekEnd(date)
        [6, 0].include?(Date.parse(date).to_time.wday)
    end

    # CommonUtils::codeToUnixtimeOrNull(code)
    def self.codeToUnixtimeOrNull(code)

        return nil if code.nil?
        return nil if code == ""
        return nil if code == "today"

        localsuffix = Time.new.to_s[-5,5]

        dateToMorningUnixtime = lambda {|date|
            DateTime.parse("#{date} 07:00:00 #{localsuffix}").to_time.to_i
        }

        # +++ postpone til midnight
        # ++ postpone by one hour
        # +today
        # +tomorrow
        # +<weekdayname>
        # +<integer>day(s)
        # +<integer>hour(s)
        # +YYYY-MM-DD
        # +1@12:34


        return CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()) if code == "+++"
        return (Time.new.to_i+3600) if code == "++"

        code = code[1,99].strip

        # today
        # tomorrow
        # <weekdayname>
        # <integer>day(s)
        # <integer>hour(s)
        # YYYY-MM-DD
        # 1@12:34

        
        weekdayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]

        if weekdayNames.include?(code) then
            # We have a week day
            weekdayName = code
            date = CommonUtils::selectDateOfNextNonTodayWeekDay(weekdayName)
            return dateToMorningUnixtime.call(date)
        end

        if code.include?("hour") then
            return Time.new.to_i + code.to_f*3600
        end

        if code == "today" then
            return dateToMorningUnixtime.call(CommonUtils::today())
        end

        if code == "tomorrow" then
            return dateToMorningUnixtime.call(CommonUtils::nDaysInTheFuture(1))
        end

        if code.include?("day") then
            return Time.new.to_i + code.to_f*86400
        end

        if code[4,1]=="-" and code[7,1]=="-" then
            return dateToMorningUnixtime.call(code)
        end

        if code.include?('@') then
            p1, p2 = code.split('@') # 1 12:34
            return DateTime.parse("#{CommonUtils::nDaysInTheFuture(p1.to_i)[0, 10]} #{p2}:00 #{localsuffix}").to_time.to_i
        end

        nil
    end

    # CommonUtils::today()
    def self.today()
        Time.new.to_s[0, 10]
    end

    # CommonUtils::tomorrow()
    def self.tomorrow()
        CommonUtils::nDaysInTheFuture(1)
    end

    # CommonUtils::getLocalTimeZone()
    def self.getLocalTimeZone()
        `date -Iseconds`.strip[-5 , 5]
    end

    # CommonUtils::unixtimeAtLastMidnightAtGivenTimeZone(timezone)
    def self.unixtimeAtLastMidnightAtGivenTimeZone(timezone)
        DateTime.parse("#{(DateTime.now.to_date).to_s} 00:00:00 #{timezone}").to_time.to_i
    end

    # CommonUtils::unixtimeAtLastMidnightAtLocalTimezone()
    def self.unixtimeAtLastMidnightAtLocalTimezone()
        CommonUtils::unixtimeAtLastMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone())
    end

    # CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(timezone)
    def self.unixtimeAtComingMidnightAtGivenTimeZone(timezone)
        DateTime.parse("#{(DateTime.now.to_date+1).to_s} 00:00:00 #{timezone}").to_time.to_i
    end

    # CommonUtils::unixtimeAtComingMidnightAtLocalTimezone()
    def self.unixtimeAtComingMidnightAtLocalTimezone()
        CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone())
    end

    # CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone()
    def self.unixtimeAtTomorrowMorningAtLocalTimezone()
        CommonUtils::unixtimeAtComingMidnightAtLocalTimezone() + 3600 * 6
    end

    # CommonUtils::isDateTime_UTC_ISO8601(datetime)
    def self.isDateTime_UTC_ISO8601(datetime)
        begin
            DateTime.parse(datetime).to_time.utc.iso8601 == datetime
        rescue
            false
        end
    end

    # CommonUtils::nowDatetimeIso8601()
    def self.nowDatetimeIso8601()
        Time.new.utc.iso8601
    end

    # CommonUtils::nowPlusOneDayDatetimeIso8601()
    def self.nowPlusOneDayDatetimeIso8601()
        Time.at(Time.new.to_i+86400).utc.iso8601
    end

    # CommonUtils::editDatetimeWithANewDate(datetime, date)
    def self.editDatetimeWithANewDate(datetime, date)
        datetime = "#{date}#{datetime[10, 99]}"
        if !CommonUtils::isDateTime_UTC_ISO8601(datetime) then
            raise "(error: 32c505fa-4168, #{datetime})"
        end
        datetime
    end

    # CommonUtils::datesSinceLastSaturday()
    def self.datesSinceLastSaturday()
        dates = []
        cursor = 0
        loop {
            date = CommonUtils::nDaysInTheFuture(cursor)
            dates << date
            break if Date.parse(date).to_time.wday == 6
            cursor = cursor - 1
        }
        dates
    end

    # CommonUtils::datesSinceLastMonday()
    def self.datesSinceLastMonday()
        dates = []
        cursor = 0
        loop {
            date = CommonUtils::nDaysInTheFuture(cursor)
            dates << date
            break if Date.parse(date).to_time.wday == 1
            cursor = cursor - 1
        }
        dates
    end

    # CommonUtils::interactivelySelectSomeDaysOfTheWeekLowercaseEnglish()
    def self.interactivelySelectSomeDaysOfTheWeekLowercaseEnglish()
        days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        CommonUtils::selectZeroOrMore(days)
    end

    # ----------------------------------------------------
    # File System Routines (Desktop selection)

    # CommonUtils::interactivelySelectDesktopLocationOrNull() 
    def self.interactivelySelectDesktopLocationOrNull()
        CommonUtils::interactivelySelectLocationAtSpecifiedDirectoryOrNull("#{Config::userHomeDirectory()}/Desktop")
    end

    # CommonUtils::interactivelySelectDesktopLocation()
    def self.interactivelySelectDesktopLocation()
        location = CommonUtils::interactivelySelectDesktopLocationOrNull()
        return location if location
        CommonUtils::interactivelySelectDesktopLocation()
    end

    # CommonUtils::locateGalaxyFileByNameFragment(namefragment)
    def self.locateGalaxyFileByNameFragment(namefragment)
        location = XCache::getOrNull("fcf91da7-0600-41aa-817a-7af95cd2570b:#{namefragment}")
        if location and File.exist?(location) then
            return location
        end
        roots = [Config::pathToGalaxy()]
        Galaxy::locationEnumerator(roots).each{|location|
            if File.basename(location).include?(namefragment) then
                XCache::set("fcf91da7-0600-41aa-817a-7af95cd2570b:#{namefragment}", location)
                return location
            end
        }
        nil
    end

    # ----------------------------------------------------
    # File System Routines (traces)

    # CommonUtils::locationTrace(location)
    def self.locationTrace(location)
        raise "(error: 4d172723-3748-4f0b-a309-3944e4f352d9)" if !File.exist?(location)
        if File.file?(location) then
            Digest::SHA256.hexdigest("#{File.basename(location)}:#{Digest::SHA256.file(location).hexdigest}")
        else
            t1 = File.basename(location)
            t2 = LucilleCore::locationsAtFolder(location)
                    .map{|loc| CommonUtils::locationTrace(loc) }
                    .join(":")
            Digest::SHA1.hexdigest([t1, t2].join(":"))
        end
    end

    # CommonUtils::locationTraceCode(location)
    def self.locationTraceCode(location)
        raise "(error: 4d172723-3748-4f0b-a309-3944e4f352d9)" if !File.exist?(location)
        return "" if File.basename(location) == "nslog.rb"
        if File.file?(location) then
            Digest::SHA1.hexdigest("#{File.basename(location)}:#{Digest::SHA1.file(location).hexdigest}")
        else
            t1 = File.basename(location)
            t2 = LucilleCore::locationsAtFolder(location)
                    .select{|loc| File.basename(loc)[0, 1] != "." }
                    .select{|loc| File.directory?(loc) or File.basename(loc)[-3, 3] == ".rb" }
                    .map{|loc| CommonUtils::locationTraceCode(loc) }
                    .join(":")
            Digest::SHA1.hexdigest([t1, t2].join(":"))
        end
    end

    # CommonUtils::locationTraceCodeWithMultipleRoots(roots)
    def self.locationTraceCodeWithMultipleRoots(roots)
        rtraces = roots.map{|root| CommonUtils::locationTraceCode(root) }
        Digest::SHA1.hexdigest(rtraces.join(":"))
    end

    # CommonUtils::catalystTraceCode()
    def self.catalystTraceCode()
        roots = [
            "#{File.dirname(__FILE__)}/.."
        ]
        CommonUtils::locationTraceCodeWithMultipleRoots(roots)
    end

    # CommonUtils::isOnline()
    def self.isOnline()
        command = "cd '#{File.dirname(__FILE__)}/..' && git fetch"
        stdout, stderr, status = Open3.capture3(command)
        !stderr.strip.include?("unable to access")
    end

    # CommonUtils::remoteLastCommitId()
    def self.remoteLastCommitId()
        `cd '#{File.dirname(__FILE__)}/..' && git rev-parse origin/main`.strip
    end

    # CommonUtils::localLastCommitId()
    def self.localLastCommitId()
        `cd '#{File.dirname(__FILE__)}/..' && git rev-parse HEAD`.strip
    end

    # ----------------------------------------------------
    # File System Routines (misc)

    # CommonUtils::firstDifferenceBetweenTwoLocations(location1, location2) nil or String (message)
    def self.firstDifferenceBetweenTwoLocations(location1, location2)
        if File.file?(location1) and !File.file?(location2) then
            return "difference: location1 is a file while location2 is a directory; location1: '#{location1}'; location2: '#{location2}'"
        end
        if !File.file?(location1) and File.file?(location2) then
            return "difference: location1 is a directory while location1 is a file; location1: '#{location1}'; location2: '#{location2}'"
        end
        if File.file?(location1) and File.file?(location2) then
            if Digest::SHA1.file(location1).hexdigest == Digest::SHA1.file(location2).hexdigest then
                return nil
            else
                return "difference: both files do not have the same content; file1: '#{location1}'; file2: '#{location2}'"
            end
        end
        # By this point both should be ships
        content1 = Dir.entries(location1) - [".", "..", ".DS_Store"]
        content2 = Dir.entries(location2) - [".", "..", ".DS_Store"]
        difference = content1 - content2
        if difference.size > 0 then
            return "difference: here is an element in directory1, but not in directory2: '#{difference.first}'; directory1: '#{location1}'; directory2: '#{location2}'"
        end
        difference = content2 - content1
        if difference.size > 0 then
            return "difference: here is an element in directory2, but not in directory1: '#{difference.first}'; directory1: '#{location1}'; directory2: '#{location2}'"
        end
        # By now, both ships have the same element names
        content1
            .each{|filename|
                locx1 = "#{location1}/#{filename}"
                locx2 = "#{location2}/#{filename}"
                status = CommonUtils::firstDifferenceBetweenTwoLocations(locx1, locx2)
                if status then
                    return status
                end
            }
        nil
    end

    # ----------------------------------------------------
    # Misc

    # CommonUtils::editTextSynchronously(text)
    def self.editTextSynchronously(text)
        filename = SecureRandom.uuid
        filepath = "/tmp/#{filename}.txt"
        File.open(filepath, 'w') {|f| f.write(text)}
        system("open '#{filepath}'")
        print "> press enter when done: "
        input = STDIN.gets
        IO.read(filepath)
    end

    # CommonUtils::accessText(text)
    def self.accessText(text)
        filename = SecureRandom.uuid
        filepath = "/tmp/#{filename}.txt"
        File.open(filepath, 'w') {|f| f.write(text)}
        system("open '#{filepath}'")
    end

    # CommonUtils::isInteger(str)
    def self.isInteger(str)
        str == str.to_i.to_s
    end

    # CommonUtils::parseAsInteger(str) # integer or null
    def self.parseAsInteger(str)
        if str == str.to_i.to_s then
            return str.to_i
        end
        nil
    end

    # CommonUtils::getNewValueEveryNSeconds(uuid, n)
    def self.getNewValueEveryNSeconds(uuid, n)
      Digest::SHA1.hexdigest("6bb2e4cf-f627-43b3-812d-57ff93012588:#{uuid}:#{(Time.new.to_f/n).to_i.to_s}")
    end

    # CommonUtils::openFilepath(filepath)
    def self.openFilepath(filepath)
        system("open '#{filepath}'")
    end

    # CommonUtils::openFilepathWithInvite(filepath)
    def self.openFilepathWithInvite(filepath)
        system("open '#{filepath}'")
        LucilleCore::pressEnterToContinue()
    end

    # CommonUtils::openUrlUsingSafari(url)
    def self.openUrlUsingSafari(url)
        system("open -na Safari '#{url}'")
    end

    # CommonUtils::openUrlUsingChrome(url)
    def self.openUrlUsingChrome(url)
        system('open -na "Google Chrome" --args --new-window "'+url+'"')
    end

    # CommonUtils::onScreenNotification(title, message)
    def self.onScreenNotification(title, message)
        title = title.gsub("'","")
        message = message.gsub("'","")
        message = message.gsub("[","|")
        message = message.gsub("]","|")
        command = "terminal-notifier -title '#{title}' -message '#{message}'"
        system(command)
    end

    # CommonUtils::selectDateOfNextNonTodayWeekDay(weekday) #2
    def self.selectDateOfNextNonTodayWeekDay(weekday)
        weekDayIndexToStringRepresentation = lambda {|indx|
            weekdayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
            weekdayNames[indx]
        }
        (1..7).each{|indx|
            if weekDayIndexToStringRepresentation.call((Time.new+indx*86400).wday) == weekday then
                return (Time.new+indx*86400).to_s[0,10]
            end
        }
    end

    # CommonUtils::screenHeight()
    def self.screenHeight()
        `/usr/bin/env tput lines`.to_i
    end

    # CommonUtils::screenWidth()
    def self.screenWidth()
        `/usr/bin/env tput cols`.to_i
    end

    # CommonUtils::verticalSize(displayStr)
    def self.verticalSize(displayStr)
        return 1 if displayStr == ""
        width = CommonUtils::screenWidth()
        displayStr.lines.map{|line| line.size/width + 1 }.inject(0, :+)
    end

    # CommonUtils::fileByFilenameIsSafelyOpenable(filename)
    def self.fileByFilenameIsSafelyOpenable(filename)
        safelyOpeneableExtensions = [".txt", ".jpg", ".jpeg", ".png", ".eml", ".webloc", ".pdf"]
        safelyOpeneableExtensions.any?{|extension| filename.downcase[-extension.size, extension.size] == extension }
    end

    # CommonUtils::putsOnPreviousLine(str)
    def self.putsOnPreviousLine(str)
        # \r move to the beginning \033[1A move up \033[0K erase to the end
        print "\r"
        print "\033[1A"
        print "\033[0K"
        puts str
    end

    # CommonUtils::nx45()
    def self.nx45()
        str1 = Time.new.strftime("%Y%m%d%H%M%S%6N")
        str2 = str1[0, 6]
        str3 = str1[6, 4]
        str4 = str1[10, 4]
        str5 = str1[14, 4]
        str6 = str1[18, 2]
        str7 = SecureRandom.hex[0, 10]
        "10#{str2}-#{str3}-#{str4}-#{str5}-#{str6}#{str7}"
    end

    # CommonUtils::base64_encode(str)
    def self.base64_encode(str)
        return nil if str.nil?
        [str].pack("m")
    end

    # CommonUtils::base64_decode(encoded)
    def self.base64_decode(encoded)
        return nil if encoded.nil?
        encoded.unpack("m").first
    end

    # CommonUtils::filepathToContentHash(filepath) # nhash
    def self.filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    # CommonUtils::atlas(pattern)
    def self.atlas(pattern)
        location = `#{Config::pathToGalaxy()}/Binaries/atlas '#{pattern}'`.strip
        (location != "") ? location : nil
    end

    # CommonUtils::interactivelySelectLocationAtSpecifiedDirectoryOrNull(folder)
    def self.interactivelySelectLocationAtSpecifiedDirectoryOrNull(folder)
        entries = Dir.entries(folder).select{|filename| !filename.start_with?(".") }.sort
        locationNameOnDesktop = LucilleCore::selectEntityFromListOfEntitiesOrNull("locationname", entries)
        return nil if locationNameOnDesktop.nil?
        "#{folder}/#{locationNameOnDesktop}"
    end

    # CommonUtils::moveFileToBinTimeline(location)
    def self.moveFileToBinTimeline(location)
        return if !File.exist?(location)
        directory = "#{Config::userHomeDirectory()}/x-space/bin-timeline/#{Time.new.strftime("%Y%m")}/#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath(directory)
        FileUtils.mv(location, directory)
    end

    # CommonUtils::uniqueStringLocationUsingPartialGalaxySearchOrNull(uniquestring)
    def self.uniqueStringLocationUsingPartialGalaxySearchOrNull(uniquestring)
        roots = [
            Config::pathToGalaxy()
        ]
        roots.each{|root|
            Find.find(root) do |path|
                if File.basename(path).downcase.include?(uniquestring.downcase) then
                    return path
                end
            end
        }
        nil
    end

    # CommonUtils::computeThatPosition(positions)
    def self.computeThatPosition(positions)
        return rand if positions.empty?
        if positions.size < 4 then
            return positions.max + 0.5 + rand
        end
        positions = positions.sort
        positions # a = [1, 2, 8, 9]
        x = positions.zip(positions.drop(1)) # [[1, 2], [2, 8], [8, nil]]
        x = x.select{|pair| pair[1] } # [[1, 2], [2, 8]
        differences = x.map{|pair| pair[1] - pair[0] } # [1, 7]
        difference_average = differences.inject(0, :+).to_f/differences.size
        x.each{|pair|
            next if (pair[1] - pair[0]) < difference_average
            return pair[0] + rand*(pair[1] - pair[0])
        }
        raise "CommonUtils::computeThatPosition failed: positions: #{positions.join(", ")}"
    end

    # CommonUtils::selectZeroOrMore(items, printLambda = lambda {|item| item })
    def self.selectZeroOrMore(items, printLambda = lambda {|item| item })
        puts "select zero or more (sort):"
        items.each_with_index{|item, i|
            puts "    [#{(i+1).to_s.rjust(2)}] #{printLambda.call(item)}"
        }
        indices = []
        loop {
            indx = LucilleCore::askQuestionAnswerAsString("> ")
            break if indx == ""
            if indx == "sort" then
                i1s, i2s = LucilleCore::selectZeroOrMore("items", [], indices, lambda { |indx| printLambda.call(items[indx]) })
                indices = i1s + i2s
                indices.each{|i|
                    puts "[#{(i+1).to_s.rjust(2)}] #{printLambda.call(items[i])}"
                }
                next
            end
            indx = indx.to_i - 1
            if indices.include?(indx) then
                indices = indices - [indx]
                indices.each{|i|
                    puts "[#{(i+1).to_s.rjust(2)}] #{printLambda.call(items[i])}"
                }
                next
            end
            indices << indx
            indices.each{|i|
                puts "[#{(i+1).to_s.rjust(2)}] #{printLambda.call(items[i])}"
            }
        }
        indices.map{|i| items[i] }
    end
end
