
# encoding: UTF-8

class Anniversary

    # ----------------------------------------------------------------------------------
    # Time Manipulations

    # Anniversary::dateIsCorrect(date)
    def self.dateIsCorrect(date)
        begin
            Date.parse(date)
            true
        rescue
            false
        end
    end

    # Anniversary::datePlusNMonthAnniversaryStyle(date: String, shiftInMonths: Integer)
    def self.datePlusNMonthAnniversaryStyle(date, shiftInMonths)
        dateElements = [date[0, 4].to_i, date[5, 2].to_i+shiftInMonths, date[8, 2].to_i]

        while dateElements[1] > 12 do
            dateElements[0] = dateElements[0]+1
            dateElements[1] = dateElements[1] - 12
        end

        date = "#{dateElements[0]}-#{dateElements[1].to_s.rjust(2, "0")}-#{dateElements[2].to_s.rjust(2, "0")}"

        while !Anniversary::dateIsCorrect(date) do
            date = "#{date[0, 4]}-#{date[5, 2]}-#{(date[8, 2].to_i-1).to_s.rjust(2, "0")}"
        end
        date
    end

    # Anniversary::datePlusNYearAnniversaryStyle(date: String, shiftInYears: Integer)
    def self.datePlusNYearAnniversaryStyle(date, shiftInYears)
        dateElements = [date[0, 4].to_i+shiftInYears, date[5, 2].to_i, date[8, 2].to_i]

        date = "#{dateElements[0]}-#{dateElements[1].to_s.rjust(2, "0")}-#{dateElements[2].to_s.rjust(2, "0")}"

        while !Anniversary::dateIsCorrect(date) do
            date = "#{date[0, 4]}-#{date[5, 2]}-#{(date[8, 2].to_i-1).to_s.rjust(2, "0")}"
        end
        date
    end

    # Anniversary::computeNextCelebrationDate(startdate: String, repeatType: String) # date
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
                xdate = Anniversary::datePlusNMonthAnniversaryStyle(date.to_s, counter)
                if today < Date.parse(xdate) then
                    return xdate
                end
            }
         end
        if repeatType == "yearly" then
            counter = 0 
            loop {
                counter += 1
                xdate = Anniversary::datePlusNYearAnniversaryStyle(date.to_s, counter)
                if today < Date.parse(xdate) then
                    return xdate
                end
            }
        end
    end

    # Anniversary::difference_between_dates_in_specified_unit(date1, date2, unit)
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
                if Anniversary::datePlusNMonthAnniversaryStyle(date1, counter) >= date2 then
                    return counter
                end
                counter += 1
            }
        end

        if unit == "yearly" then
            counter = 0
            loop {
                if Anniversary::datePlusNYearAnniversaryStyle(date1, counter) >= date2 then
                    return counter
                end
                counter += 1
            }
        end
    end

    # ----------------------------------------------------------------------------------
    # toString

    # Anniversary::makeNew()
    def self.makeNew()
        startdate = LucilleCore::askQuestionAnswerAsString("startdate (YYYY-MM-DD): ")
        repeatType = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("type", ["weekly", "monthly", "yearly"])
        next_celebration = Anniversary::computeNextCelebrationDate(startdate, repeatType)
        {
            "btype" => "anniversary",
            "startdate" => startdate,
            "repeatType" => repeatType,
            "next_celebration" => next_celebration
        }
    end

    # Anniversary::toString(behaviour)
    def self.toString(behaviour)
        difference = Anniversary::difference_between_dates_in_specified_unit(behaviour["startdate"], behaviour["next_celebration"], behaviour["repeatType"])
        "[#{behaviour["startdate"]}, #{behaviour["next_celebration"]}, #{difference.to_s.rjust(4)}, #{behaviour["repeatType"].ljust(7)}]"
    end

end
