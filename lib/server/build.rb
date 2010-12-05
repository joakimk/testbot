module Testbot::Server

  class Build < Sequel::Model

    def self.create_and_build_jobs(hash)
      hash["jruby"] = (hash["jruby"] == "true") ? 1 : 0
      build = create(hash.reject { |k, v| k == 'available_runner_usage' })
      build.create_jobs!(hash['available_runner_usage'])
      build
    end

    def self.result!(job, runner, file, time)
      min_time = 1000000000
      Runner.filter("").each { |r|
        if min_time > r[:cpu_test_time]
          min_time = r[:cpu_test_time]
        end
      }
      
      cpu_speed = (min_time / runner[:cpu_test_time].to_f)

      if job[:profile]
        @@runtimes[file] = (time.to_i * cpu_speed).to_i
      end
      "MIN CPU: #{min_time} : RCPU: #{runner[:cpu_test_time]}: CS: #{cpu_speed} : Time: #{time} : Stored: #{@@runtimes[file]}"
    end

    def self.expected_time(files)
      time = 0
      min = @@runtimes.values.min
      files.split.each { |file|
        time += @@runtimes[file] - min if  @@runtimes[file] 
      }
      time + min
    end

    def create_jobs!(available_runner_usage)
      @@runtimes ||= {}
      if @@runtimes.empty?
        self[:files].split.each { |file|
          @@runtimes[file] = 0
          Job.create(:files => file,
                     :root => self[:root],
                     :project => self[:project],
                     :type => self[:type],
                     :requester_mac => self[:requester_mac],
                     :build_id => self[:id],
                     :jruby => self[:jruby],
                     :profile => true)
        }
      else
        #groups = Group.build(self[:files].split, self[:sizes].split.map { |size| size.to_i },
        rtimes = @@runtimes.map { |k, v| [ k, v.to_i ] }
        times = rtimes.map { |a| a.last }
        files = rtimes.map { |a| a.first }
        min = times.min
        times = times.map { |t|  t-min }
        groups = Group.build(files, times,
                             Runner.total_instances.to_f * (available_runner_usage.to_i / 100.0), self[:type])
        groups.each do |group|
          Job.create(:files => group.join(' '),
                     :root => self[:root],
                     :project => self[:project],
                     :type => self[:type],
                     :requester_mac => self[:requester_mac],
                     :build_id => self[:id],
                     :jruby => self[:jruby])
        end
      end
    end

    def destroy
      Job.filter([ 'build_id = ?', self[:id] ]).each { |job| job.destroy }
      super
    end

  end

end
