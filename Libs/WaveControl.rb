
class WaveControl

    # WaveControl::getControl()
    def self.getControl()
        key = "84ed59de-d5bc-4db0-8ac1-f0e235f4f2bc:#{CommonUtils::today()}"
        control = XCache::getOrNull(key)
        return JSON.parse(control) if control
        control = {
            "credits" => 0
        }
        XCache::set(key, JSON.generate(control))
        control
    end

    # WaveControl::putControl(control)
    def self.putControl(control)
        key = "84ed59de-d5bc-4db0-8ac1-f0e235f4f2bc:#{CommonUtils::today()}"
        XCache::set(key, JSON.generate(control))
    end

    # WaveControl::credit(timeInSeconds)
    def self.credit(timeInSeconds)
        control = WaveControl::getControl()
        control["credits"] = control["credits"] + timeInSeconds
        WaveControl::putControl(control)
    end

    # WaveControl::shouldShow()
    def self.shouldShow()
        control = WaveControl::getControl()
        control["credits"] >= 1 # Vx040
    end
end
