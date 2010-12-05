require 'sequel'

module Testbot::Server

  DB = Sequel.sqlite

  DB.create_table :jobs do
    primary_key :id
    String :files
    String :result
    String :root
    String :project
    String :type
    String :requester_mac
    Integer :jruby
    Integer :build_id
    Integer :taken_by_id
    Boolean :success
    Datetime :taken_at, :default => nil
  end

  DB.create_table :runners do
    primary_key :id
    String :ip
    String :hostname
    String :uid
    String :username
    String :version
    Integer :idle_instances
    Integer :max_instances
    Datetime :last_seen_at
  end

end
