
# encoding: UTF-8

class Prefix

    # Prefix::prefix(item)
    def self.prefix(item) # Array[Item]
        # This function takes an items and return a list of items to display. In most 
        # cases it's going to return the item itself, but in some cases (cliques) will reply 
        # more, or even empty.
        if item["mikuType"] == "NxClique" then
            head = Cliques::cliqueToItemsInOrder(item["uuid"]).reduce([]){|selected, item|
                if selected.size >= 3 then
                    selected
                else
                    if DoNotShowUntil::isVisible(item) then
                        selected + [item]
                    else
                        selected
                    end
                end
            }
           return head + [item]
        end

        # default case
        [item]
    end
end
