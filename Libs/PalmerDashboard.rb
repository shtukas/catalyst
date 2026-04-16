
class PalmerDashboard

    # PalmerDashboard::headlines()
    def self.headlines()
        IO.read("/Users/pascal_honore/Galaxy/DataHub/Catalyst/data/palmer-dashboard/report-catalyst-headlines.txt").strip
    end

    # PalmerDashboard::print_palmer_dashboard()
    def self.print_palmer_dashboard()
        dashboard = IO.read("/Users/pascal_honore/Galaxy/DataHub/Catalyst/data/palmer-dashboard/report-full.txt").strip
        puts dashboard
        LucilleCore::pressEnterToContinue()
    end
end