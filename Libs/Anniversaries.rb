
# encoding: UTF-8

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

    # Anniversaries::makeDetails()
    def self.makeDetails()
        startdate = LucilleCore::askQuestionAnswerAsString("startdate (YYYY-MM-DD): ")
        repeatType = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("type", ["weekly", "monthly", "yearly"])
        next_celebration = Anniversaries::computeNextCelebrationDate(startdate, repeatType)
        {
            "startdate" => startdate,
            "repeatType" => repeatType,
            "next_celebration" => next_celebration
        }
    end

    # Anniversaries::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        details = Anniversaries::makeDetails()
        uuid = SecureRandom.uuid
        Blades::init(uuid)
        Blades::setAttribute(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute(uuid, "description", description)
        Blades::setAttribute(uuid, "startdate", details["startdate"])
        Blades::setAttribute(uuid, "repeatType", details["repeatType"])
        Blades::setAttribute(uuid, "next_celebration", details["next_celebration"])
        Blades::setAttribute(uuid, "mikuType", "Anniversary")
        item = Blades::itemOrNull(uuid)
        item
    end

    # Anniversaries::toString(item)
    def self.toString(item)
        difference = Anniversaries::difference_between_dates_in_specified_unit(item["startdate"], item["next_celebration"], item["repeatType"])
        "🎂 [#{item["startdate"]}, #{item["next_celebration"]}, #{difference.to_s.rjust(4)}, #{item["repeatType"].ljust(7)}] #{item["description"]}"
    end

    # Anniversaries::listingItems()
    def self.listingItems()
        Blades::mikuType("Anniversary")
    end
end
