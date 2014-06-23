require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
begin
  require 'yajl/bzip2'
rescue
  warn "Couldn't load yajl/bzip2, maybe you don't have bzip2-ruby installed? Continuing without running bzip2 specs."
end
require 'yajl/gzip'
require 'yajl/deflate'
require 'yajl/http_stream'

def parse_off_headers(io)
  io.each_line do |line|
    if line == "\r\n" # end of the headers
      break
    end
  end
end

describe "Yajl HTTP GET request" do
  before(:all) do
    raw = File.new(File.expand_path(File.dirname(__FILE__) + '/fixtures/http.raw.dump'), 'rb')
    parse_off_headers(raw)
    @template_hash = Yajl::Parser.parse(raw)

    raw.rewind
    parse_off_headers(raw)
    @template_hash_symbolized = Yajl::Parser.parse(raw, :symbolize_keys => true)

    @deflate = File.new(File.expand_path(File.dirname(__FILE__) + '/fixtures/http.deflate.dump'), 'rb')
    @gzip = File.new(File.expand_path(File.dirname(__FILE__) + '/fixtures/http.gzip.dump'), 'rb')
    @chunked_body = {"item"=>{"price"=>1.99, "updated_by_id"=>nil, "cached_tag_list"=>"", "name"=>"generated", "created_at"=>"2009-03-24T05:25:09Z", "cost"=>0.597, "delta"=>false, "created_by_id"=>nil, "updated_at"=>"2009-03-24T05:25:09Z", "import_tag"=>nil, "account_id"=>16, "id"=>1, "taxable"=>true, "unit"=>nil, "sku"=>"06317-0306", "company_id"=>0, "description"=>nil, "active"=>true}}
  end

  after(:each) do
    @file_path = nil
  end

  def prepare_mock_request_dump(format=:raw)
    @request = File.new(File.expand_path(File.dirname(__FILE__) + "/fixtures/http.#{format}.dump"), 'rb')
    @uri = 'file://'+File.expand_path(File.dirname(__FILE__) + "/fixtures/http/http.#{format}.dump")
    TCPSocket.should_receive(:new).and_return(@request)
    @request.should_receive(:write)
  end

  it "should parse a raw response" do
    prepare_mock_request_dump :raw
    @template_hash.should == Yajl::HttpStream.get(@uri)
  end

  it "should parse a raw response and symbolize keys" do
    prepare_mock_request_dump :raw
    @template_hash_symbolized.should == Yajl::HttpStream.get(@uri, :symbolize_keys => true)
  end

  it "should parse a raw response using instance method" do
    prepare_mock_request_dump :raw
    @uri.should_receive(:host)
    @uri.should_receive(:port)
    stream = Yajl::HttpStream.new
    @template_hash.should == stream.get(@uri)
  end

  it "should parse a chunked response using instance method" do
    prepare_mock_request_dump :chunked
    @uri.should_receive(:host)
    @uri.should_receive(:port)
    stream = Yajl::HttpStream.new
    stream.get(@uri) do |obj|
      obj.should eql(@chunked_body)
    end
  end

  if defined?(Yajl::Bzip2::StreamReader)
    it "should parse a bzip2 compressed response" do
      prepare_mock_request_dump :bzip2
      @template_hash.should == Yajl::HttpStream.get(@uri)
    end

    it "should parse a bzip2 compressed response and symbolize keys" do
      prepare_mock_request_dump :bzip2
      @template_hash_symbolized.should == Yajl::HttpStream.get(@uri, :symbolize_keys => true)
    end
  end

  it "should parse a deflate compressed response" do
    prepare_mock_request_dump :deflate
    @template_hash.should == Yajl::HttpStream.get(@uri)
  end

  it "should parse a deflate compressed response and symbolize keys" do
    prepare_mock_request_dump :deflate
    @template_hash_symbolized.should == Yajl::HttpStream.get(@uri, :symbolize_keys => true)
  end

  it "should parse a gzip compressed response" do
    prepare_mock_request_dump :gzip
    @template_hash.should == Yajl::HttpStream.get(@uri)
  end

  it "should parse a gzip compressed response and symbolize keys" do
    prepare_mock_request_dump :gzip
    @template_hash_symbolized.should == Yajl::HttpStream.get(@uri, :symbolize_keys => true)
  end

  it "should raise when an HTTP code that isn't 200 is returned" do
    prepare_mock_request_dump :error
    lambda { Yajl::HttpStream.get(@uri) }.should raise_exception(Yajl::HttpStream::HttpError)
  end
end
