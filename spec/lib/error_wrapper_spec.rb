require 'spec_helper'
require 'batch_api/error_wrapper'

describe BatchApi::ErrorWrapper do
  let(:exception) {
    StandardError.new(Faker::Lorem.words(3)).tap do |e|
      e.set_backtrace(Kernel.caller)
    end
  }

  let(:error) { BatchApi::ErrorWrapper.new(exception) }

  describe "#body" do
    it "includes the message in the body" do
      error.body[:error][:message].should == exception.message
    end

    it "includes the backtrace if it should be there" do
      error.stub(:expose_backtrace?).and_return(true)
      error.body[:error][:backtrace].should == exception.backtrace
    end

    it "includes the backtrace if it should be there" do
      error.stub(:expose_backtrace?).and_return(false)
      error.body[:backtrace].should be_nil
    end
  end

  describe "#render" do
    it "returns the appropriate status" do
      status = stub
      error.stub(:status_code).and_return(status)
      error.render[0].should == status
    end

    it "returns appropriate content type" do
      ctype = stub
      BatchApi::RackMiddleware.stub(:content_type).and_return(ctype)
      error.render[1].should == ctype
    end

    it "returns the JSONified body as the 2nd" do
      error.render[2].should == [MultiJson.dump(error.body)]
    end
  end

  describe "#status_code" do
    it "returns 500 by default" do
      error.status_code.should == 500
    end

    it "returns another status code if the error supports that" do
      err = StandardError.new
      code = stub
      err.stub(:status_code).and_return(code)
      BatchApi::ErrorWrapper.new(err).status_code.should == code
    end
  end

  describe ".expose_backtrace?" do
    it "returns false if Rails.env.production?" do
      Rails.env.stub(:production?).and_return(true)
      BatchApi::ErrorWrapper.expose_backtrace?.should be_false
      Rails.env.stub(:production?).and_return(false)
      BatchApi::ErrorWrapper.expose_backtrace?.should be_true
    end
  end
end
