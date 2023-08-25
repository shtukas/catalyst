
class Prefix

    # Prefix::prefix(items)
    def self.prefix(items)
        return [] if items.empty?
        stratification = Stratification::getItemStratification(items[0])
        if !stratification.empty? then
            return stratification.reverse + items
        end
        Pure::pure(items)
    end
end
