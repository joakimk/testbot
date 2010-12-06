module Testbot::Server

  class Runner < MemoryModel

    def self.record!(hash)
      create_or_update_by_mac!(hash)
    end

    def self.create_or_update_by_mac!(hash)
      if runner = find_by_uid(hash[:uid])
        runner.update hash
      else
        Runner.create hash
      end
    end

    def self.timeout
      10
    end

    def self.find_by_uid(uid)
      all.find { |r| r.uid == uid }
    end

    def self.find_all_outdated
      all.find_all { |r| r.version != Testbot.version }
    end

    def self.find_all_available
      all.find_all { |r| r.version == Testbot.version && r.last_seen_at > (Time.now - Runner.timeout) }
    end  

    def self.available_instances
      find_all_available.inject(0) { |sum, r| r[:idle_instances].to_i + sum }
    end

    def self.total_instances
      return 1 if ENV['INTEGRATION_TEST']
      find_all_available.inject(0) { |sum, r| r[:max_instances].to_i + sum }
    end

  end

end
