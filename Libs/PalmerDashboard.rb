
class PalmerDashboard

    # PalmerDashboard::fetch(url)
    def self.fetch(url)
        uri = URI(url)
        request = Net::HTTP::Get.new(uri)
        request['User-Agent'] = 'curl/7.68.0'
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
            http.request(request).body
        end
    end

    # PalmerDashboard::headlines()
    def self.headlines()
        urls = JSON.parse(IO.read("#{Config::pathToCatalystDataRepository()}/palmer-dashboard-urls.json"))
        Thread.new {
            report = PalmerDashboard::fetch(urls["headlines"])
            XCache::set("b7dc5d8e-2753-46c9-a82c-ae8ab1ab8062", report)
        }
        XCache::getOrNull("b7dc5d8e-2753-46c9-a82c-ae8ab1ab8062") || ""
    end

    # PalmerDashboard::print_palmer_dashboard()
    def self.print_palmer_dashboard()
        urls = JSON.parse(IO.read("#{Config::pathToCatalystDataRepository()}/palmer-dashboard-urls.json"))
        report = PalmerDashboard::fetch(urls["full"])
        puts report.strip.strip
        LucilleCore::pressEnterToContinue()
    end
end