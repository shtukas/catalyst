# encoding: UTF-8

class NxDrops

    # NxDrops::viennaUrl(url)
    def self.viennaUrl(url)
        uuid  = SecureRandom.uuid
        description = "(vienna) #{url}"
        coredataref = "url:#{N1Data::putBlob(url)}"
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxDrop",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
        }
        N3Objects::commit(item)
        item
    end

    # NxDrops::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nhash = AionCore::commitLocationReturnHash(N1DataElizabeth.new(), location)
        coredataref = "aion-point:#{nhash}"
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxDrop",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
        }
        N3Objects::commit(item)
        item
    end
end
