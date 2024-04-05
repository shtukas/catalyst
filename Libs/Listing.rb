=begin

Listing: Array[Nx45]

Nx45:
    - trace: string
    - item : item

=end

class Listing

    # Listing::get()
    def self.get()
        JSON.parse(XCache::getOrDefaultValue("2dea29de-dd57-4630-937e-4e3fd1af8cb5", "[]"))
    end

    # Listing::store(listing)
    def self.store(listing)
        XCache::set("2dea29de-dd57-4630-937e-4e3fd1af8cb5", JSON.generate(listing))
    end

    # Listing::trace(item)
    def self.trace(item)
        item["uuid"]
    end

    # Listing::apply(items)
    def self.apply(items)
        listing = Listing::get()
        listing = listing.map{|nx45|
            nx45["item"] = nil
            nx45
        }
        items.each{|item|
            trace = Listing::trace(item)
            hasBeenPositioned = false
            listing = listing.map{|nx45|
                if nx45["trace"] == trace then
                    nx45["item"] = item
                    hasBeenPositioned = true
                end
                nx45
            }
            if !hasBeenPositioned then
                listing << {
                    "trace" => trace,
                    "item"  => item
                }
            end
        }
        listing = listing.select{|nx45|
            nx45["item"]
        }
        Listing::store(listing)
        listing.map{|nx45| nx45["item"] }.compact
    end

end
