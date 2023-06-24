
class NxNotes

    # NxNotes::getTextOrNull(item)
    def self.getTextOrNull(item)
        DarkEnergy::read(item["uuid"], "note")
    end

    # NxNotes::getText(item)
    def self.getText(item)
        NxNotes::getTextOrNull(item) || ""
    end

    # NxNotes::hasNoteText(item)
    def self.hasNoteText(item)
        NxNotes::getText(item).strip.size > 0
    end

    # NxNotes::commit(item, text)
    def self.commit(item, text)
        DarkEnergy::patch(item["uuid"], "note", text)
    end

    # NxNotes::toStringSuffix(item)
    def self.toStringSuffix(item)
        Memoize::evaluate("215286a6-db0b-44ac-a52e-443808e44920:#{item["uuid"]}", lambda{
            text = NxNotes::getTextOrNull(item)
            ( text and text.strip.size > 0 ) ? " (note)".green : ""
        })
    end

    # NxNotes::edit(item)
    def self.edit(item)
        text = NxNotes::getText(item)
        text = CommonUtils::editTextSynchronously(text)
        NxNotes::commit(item, text)
    end
end