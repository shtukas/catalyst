
# encoding: UTF-8

=begin
{
    "type": "done",
    "uuid": string
}
=end

class SigOps

    # SigOps::incoming(event)
    def self.incoming(event)
        if event["type"] == 'done' then
            uuid = event["uuid"]
            data = XCache::getOrNull("74e3f0ff-cd23-470a-bb99-974d2fbeb09a")
            return if data.nil?
            data = JSON.parse(data)
            data = data.reject{|item| item["uuid"] == uuid }
            XCache::set("74e3f0ff-cd23-470a-bb99-974d2fbeb09a", JSON.generate(data))
            return
        end
    end
end
