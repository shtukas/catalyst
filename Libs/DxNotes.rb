
class DxNotes

    # DxNotes::getTextOrNull(item)
    def self.getTextOrNull(item)
        DarkEnergy::read(item["uuid"], "note")
    end

    # DxNotes::getText(item)
    def self.getText(item)
        DxNotes::getTextOrNull(item) || ""
    end

    # DxNotes::hasNoteText(item)
    def self.hasNoteText(item)
        DxNotes::getText(item).strip.size > 0
    end

    # DxNotes::commit(item, text)
    def self.commit(item, text)
        DarkEnergy::patch(item["uuid"], "note", text)
    end

    # DxNotes::toStringSuffix(item)
    def self.toStringSuffix(item)
        text = DxNotes::getTextOrNull(item)
        ( text and text.strip.size > 0 ) ? " (note)".green : ""
    end

    # DxNotes::edit(item)
    def self.edit(item)
        text = DxNotes::getText(item)
        text = CommonUtils::editTextSynchronously(text)
        DxNotes::commit(item, text)
    end
end