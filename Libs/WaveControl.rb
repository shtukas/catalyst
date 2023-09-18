
class WaveControl

    # WaveControl::getControl()
    def self.getControl()
        key = "84ed59de-d5bc-4db0-8ac1-f0e235f4f2bb:#{CommonUtils::today()}"
        control = XCache::getOrNull(key)
        return JSON.parse(control) if control
        control = {
            "timebucket" => 0
        }
        XCache::set(key, JSON.generate(control))
        control
    end

    # WaveControl::putControl(control)
    def self.putControl(control)
        key = "84ed59de-d5bc-4db0-8ac1-f0e235f4f2bb:#{CommonUtils::today()}"
        XCache::set(key, JSON.generate(control))
    end

    # WaveControl::addTime(timeInSeconds)
    def self.addTime(timeInSeconds)
        control = WaveControl::getControl()
        control["timebucket"] = control["timebucket"] + timeInSeconds
        WaveControl::putControl(control)
    end

    # WaveControl::shouldShow()
    def self.shouldShow()
        control = WaveControl::getControl()
        control["timebucket"] >= 20*60 # Vx040
    end
end
