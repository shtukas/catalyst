
class Cliques

    # Cliques::setClique(item, cliquename)
    def self.setClique(item, cliquename)
        Items::setAttribute(item["uuid"], "clique-13", cliquename)
    end

    # Cliques::interactivelySelectCliqueNameOrNull()
    def self.interactivelySelectCliqueNameOrNull()
        names = Items::mikuType("NxTask")
                    .select{|item| item["clique-13"] }
                    .map{|item| item["clique-13"] }
                    .uniq
                    .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", names)
    end
end