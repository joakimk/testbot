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

end
