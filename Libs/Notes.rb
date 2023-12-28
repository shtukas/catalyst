
class Notes

    # Notes::suffix(item)
    def self.suffix(item)
        return "" if (item["note-1531"].nil? or item["note-1531"].strip == "")
        " (note)".green
    end

end