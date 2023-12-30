
# encoding: UTF-8

class Desktop

    # Desktop::filepath()
    def self.filepath()
        "#{Config::pathToCatalystDataRepository()}/desktop.txt"
    end

    # Desktop::contents()
    def self.contents()
        IO.read(Desktop::filepath()).lines.first(10).join().strip
    end

    # Desktop::announce()
    def self.announce()
        [
            "Desktop:".green, 
            Desktop::contents().lines.map{|line| "            #{line}" }.join()
        ].join("\n")
    end

    # Desktop::listingItems()
    def self.listingItems()
        return [] if Desktop::contents() == ""
        [{
            "uuid"     => SecureRandom.uuid, # random uuid so that we can't hide it
            "mikuType" => "DesktopTx1",
            "announce" => Desktop::announce()
        }]
    end

    # Desktop::done()
    def self.done()
        text = IO.read(Desktop::filepath())
        text = SectionsType0141::applyNextTransformationToText(text)
        File.open(Desktop::filepath(), "w"){|f| f.puts(text) }
    end
end
