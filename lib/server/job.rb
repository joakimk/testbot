require File.join(File.dirname(__FILE__), 'db.rb') unless defined?(DB)

class Job < Sequel::Model
  def update(hash)
    super(hash)
    if build = Build.find([ "id = ?", self[:build_id] ])
      done = Job.filter([ "result IS NULL AND build_id = ?", self[:build_id] ]).count == 0
      build.update(:results => build[:results].to_s + hash[:result].to_s,
                   :done => done)
    end
    Runtime.store_results(self[:files].split(' '), Time.now - self[:taken_at], self[:type])
  end
  
  def self.next(params, remove_addr)
    params_without_requester_mac = params.reject { |k, v| k == "requester_mac" }
    runner = Runner.record! params_without_requester_mac.merge({ :ip => remove_addr, :last_seen_at => Time.now })
    return unless Server.valid_version?(params[:version])
    [ next_job_query(params["requester_mac"]).first, runner ]
  end
  
  private
  
  def self.next_job_query(requester_mac)
    release_jobs_taken_by_missing_runners!
    query = Job.filter("taken_at IS NULL").order("Random()".lit)
    if requester_mac
      query.filter("requester_mac = '#{requester_mac}'")
    else
      query
    end
  end
  
  def self.release_jobs_taken_by_missing_runners!
    missing_runners = Runner.filter([ "last_seen_at < ?", (Time.now - Runner.timeout) ])
    missing_runners.each { |r|
      Job.filter(:taken_by_id => r[:id]).update(:taken_at => nil)
    }    
  end
end
