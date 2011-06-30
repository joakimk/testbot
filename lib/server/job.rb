module Testbot::Server

  class Job < MemoryModel

    def update(hash)
      super(hash)
      if self.build
        all_files = self.build.files.to_s.split
        completed_files = self.build.completed_files + self.files.split
        done = (all_files.sort == completed_files.sort)
        self.build.update(:results => build.results.to_s + self.result.to_s,
                          :done => done, :completed_files => completed_files.uniq)

        build_broken_by_job = (self.success == "false" && build.success)
        self.build.update(:success => false) if build_broken_by_job
      end
    end

    def self.next(params, remove_addr)
      clean_params = params.reject { |k, v| k == "no_jruby" }
      runner = Runner.record! clean_params.merge({ :ip => remove_addr, :last_seen_at => Time.now })
      return unless Server.valid_version?(params[:version])
      [ next_job(params["build_id"], params["no_jruby"]), runner ]
    end

    private

    def self.next_job(build_id, no_jruby)
      release_jobs_taken_by_missing_runners!
      jobs = Job.all.find_all { |j|
        !j.taken_at &&
          (build_id ? j.build.id.to_s == build_id : true) &&
          (no_jruby ? j.jruby != 1 : true)
      }

      jobs[rand(jobs.size)]
    end

    def self.release_jobs_taken_by_missing_runners!
      missing_runners = Runner.all.find_all { |r| r.last_seen_at < (Time.now - Runner.timeout) }
      missing_runners.each { |runner|
        Job.all.find_all { |job| job.taken_by == runner }.each { |job| job.update(:taken_at => nil) }
      }
    end

  end

end
