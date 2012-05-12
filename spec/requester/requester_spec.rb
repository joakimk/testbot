require 'spec_helper'
require 'requester/requester'

describe Testbot::Requester::Requester do
  let(:adapter) { mock }
  let(:client) { mock.as_null_object }
  let(:display) { mock.as_null_object }

  it "reports an error and exists when requesting a run fails" do
    client.stub!(:request_run).and_return(false)
    client.stub!(:error_info).and_return("error message")
    display.should_receive(:text).with(/error message/)
    
    Testbot::Requester::Requester.new.run_tests(adapter, "spec/requests", client, display)
  end

  it "can report that there are no available runners" do
    client.stub!(:request_run).and_return(false)
    client.stub!(:error_type).and_return(:no_runners_available)
    display.should_receive(:text).with(/No runners available/)

    Testbot::Requester::Requester.new.run_tests(adapter, "spec/requests", client, display)
  end

  # scetch on how the API would ideally be
  #it do
  #  Testbot::Requester.new(client, display).run_tests_in("spec/requests")
  #end
end
