require File.expand_path(File.join(File.dirname(__FILE__), 'db.rb'))

module Testbot::Server

  class Job < Sequel::Model
    def update(hash)
      super(hash)
      if build = Build.find([ "id = ?", self[:build_id] ])
        done = Job.filter([ "result IS NULL AND build_id = ?", self[:build_id] ]).count == 0
        build.update(:results => build[:results].to_s + hash[:result].to_s,
                     :done => done)

        build_broken_by_job = (hash[:success] == "false" && build[:success])
        build.update(:success => false) if build_broken_by_job
      end
    end

    def self.next(params, remove_addr)
      clean_params = params.reject { |k, v| [ "requester_mac", "no_jruby" ].include?(k) }
      runner = Runner.record! clean_params.merge({ :ip => remove_addr, :last_seen_at => Time.now })
      return unless Server.valid_version?(params[:version])
      [ next_job_query(params["requester_mac"], params["no_jruby"]).first, runner ]
    end

    private

    def self.next_job_query(requester_mac, no_jruby)
      release_jobs_taken_by_missing_runners!
      query = Job.filter("taken_at IS NULL").order("Random()".lit)
      filters = []
      filters << "requester_mac = '#{requester_mac}'" if requester_mac
      filters << "jruby != 1" if no_jruby
      if filters.empty?
        query
      else
        query.filter(filters.join(' AND ')) 
      end
    end

    def self.release_jobs_taken_by_missing_runners!
      missing_runners = Runner.filter([ "last_seen_at < ?", (Time.now - Runner.timeout) ])
      missing_runners.each { |r|
        Job.filter(:taken_by_id => r[:id]).update(:taken_at => nil)
      }    
    end
  end

end
