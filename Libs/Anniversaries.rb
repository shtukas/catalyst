
class Anniversaries

    # ----------------------------------------------------------------------------------
    # Time Manipulations

    # Anniversaries::dateIsCorrect(date)
    def self.dateIsCorrect(date)
        begin
            Date.parse(date)
            true
        rescue
            false
        end
    end

    # Anniversaries::datePlusNMonthAnniversaryStyle(date: String, shiftInMonths: Integer)
    def self.datePlusNMonthAnniversaryStyle(date, shiftInMonths)
        dateElements = [date[0, 4].to_i, date[5, 2].to_i+shiftInMonths, date[8, 2].to_i]

        while dateElements[1] > 12 do
            dateElements[0] = dateElements[0]+1
            dateElements[1] = dateElements[1] - 12
        end

        date = "#{dateElements[0]}-#{dateElements[1].to_s.rjust(2, "0")}-#{dateElements[2].to_s.rjust(2, "0")}"

        while !Anniversaries::dateIsCorrect(date) do
            date = "#{date[0, 4]}-#{date[5, 2]}-#{(date[8, 2].to_i-1).to_s.rjust(2, "0")}"
        end
        date
    end

    # Anniversaries::datePlusNYearAnniversaryStyle(date: String, shiftInYears: Integer)
    def self.datePlusNYearAnniversaryStyle(date, shiftInYears)
        dateElements = [date[0, 4].to_i+shiftInYears, date[5, 2].to_i, date[8, 2].to_i]

        date = "#{dateElements[0]}-#{dateElements[1].to_s.rjust(2, "0")}-#{dateElements[2].to_s.rjust(2, "0")}"

        while !Anniversaries::dateIsCorrect(date) do
            date = "#{date[0, 4]}-#{date[5, 2]}-#{(date[8, 2].to_i-1).to_s.rjust(2, "0")}"
        end
        date
    end

    # Anniversaries::computeNextCelebrationDate(startdate: String, repeatType: String) # date
    def self.computeNextCelebrationDate(startdate, repeatType)
        date = Date.parse(startdate)
        today = Date.today()
        if repeatType == "weekly" then
            while date <= today do
                date = date + 7
            end 
            return date.to_s
        end
        if repeatType == "monthly" then
            counter = 0 
            loop {
                counter += 1
                xdate = Anniversaries::datePlusNMonthAnniversaryStyle(date.to_s, counter)
                if today < Date.parse(xdate) then
                    return xdate
                end
            }
         end
        if repeatType == "yearly" then
            counter = 0 
            loop {
                counter += 1
                xdate = Anniversaries::datePlusNYearAnniversaryStyle(date.to_s, counter)
                if today < Date.parse(xdate) then
                    return xdate
                end
            }
        end
    end

    # Anniversaries::difference_between_dates_in_specified_unit(date1, date2, unit)
    def self.difference_between_dates_in_specified_unit(date1, date2, unit)
        # unit is a repeat type: "weekly" | "monthly" | "yearly"



        if unit == "weekly" then
            date1 = Date.parse(date1)
            date2 = Date.parse(date2)
            counter = 0
            loop {
                return counter if (date1 + counter*7) >= date2
                counter += 1
            }
        end

        if unit == "monthly" then
            counter = 0
            loop {
                if Anniversaries::datePlusNMonthAnniversaryStyle(date1, counter) >= date2 then
                    return counter
                end
                counter += 1
            }
        end

        if unit == "yearly" then
            counter = 0
            loop {
                if Anniversaries::datePlusNYearAnniversaryStyle(date1, counter) >= date2 then
                    return counter
                end
                counter += 1
            }
        end
    end

    # ----------------------------------------------------------------------------------
    # Data

    # Anniversaries::issueNewAnniversaryOrNullInteractively()
    def self.issueNewAnniversaryOrNullInteractively()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        if description == "" then
            return nil
        end

        startdate = LucilleCore::askQuestionAnswerAsString("startdate (empty to abort): ")
        if startdate == "" then
            return nil
        end

        repeatType = LucilleCore::selectEntityFromListOfEntitiesOrNull("repeat type", ["weekly", "monthly", "yearly"])
        if repeatType.nil? then
            return nil
        end

        uuid = SecureRandom.uuid

        Items::itemInit(uuid, "NxAnniversary")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "startdate", startdate)
        Items::setAttribute(uuid, "repeatType", repeatType)

        Items::itemOrNull(uuid)
    end

    # Anniversaries::toString(anniversary)
    def self.toString(anniversary)
        difference = Anniversaries::difference_between_dates_in_specified_unit(anniversary["startdate"], anniversary["next_celebration"], anniversary["repeatType"])
        "(anniversary) [#{anniversary["startdate"]}, #{Time.at(anniversary["listing-positioning-2141"]).to_s[0, 10]}, #{difference.to_s.rjust(4)}, #{anniversary["repeatType"].ljust(7)}] #{anniversary["description"]}"
    end

    # Anniversaries::next_unixtime(item)
    def self.next_unixtime(item)
        date = Anniversaries::computeNextCelebrationDate(item["startdate"], item["repeatType"])
        Date.parse(date).to_time.to_i
    end

    # ----------------------------------------------------------------------------------
    # Operations

    # Anniversaries::mark_next_celebration_date(item)
    def self.mark_next_celebration_date(item)
        date = Anniversaries::computeNextCelebrationDate(item["startdate"], item["repeatType"])
        Items::setAttribute(item["uuid"], "next_celebration", date)
    end

    # Anniversaries::program1(item)
    def self.program1(item)
        loop {
            puts PolyFunctions::toString(item).green
            actions = ["update description", "update start date", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            break if action.nil?
            if action == "update description" then
                description = CommonUtils::editTextSynchronously(item["description"]).strip
                return if description == ""
                Items::setAttribute(item["uuid"], "description", description)
            end
            if action == "update start date" then
                startdate = CommonUtils::editTextSynchronously(item["startdate"])
                return if startdate == ""
                Items::setAttribute(item["uuid"], "startdate", startdate)
            end
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
                    Items::destroy(item["uuid"])
                    return
                end
            end
        }
    end

    # Anniversaries::program2()
    def self.program2()
        loop {
            anniversaries = Items::mikuType("NxAnniversary").sort_by{|item| Anniversaries::next_unixtime(item) }
            anniversary = LucilleCore::selectEntityFromListOfEntitiesOrNull("anniversary", anniversaries, lambda{|item| Anniversaries::toString(item) })
            return if anniversary.nil?
            Anniversaries::program1(anniversary)
        }
    end
end
