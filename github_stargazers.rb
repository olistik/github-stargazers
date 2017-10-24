require "uri"
require "net/http"
require "json"

if ARGV.length != 1
  script_name = File.basename(__FILE__)
  puts "Usage: ./#{script_name} <repository>"
  puts "\nFor example ./#{script_name} rails/rails"
  exit 1
end

module Result
  class BaseResult
    attr_reader :code, :data

    def initialize(code: :ok, data:, success: true)
      @code = code
      @data = data
      @success = success
    end

    def success?
      @success == true
    end

    def error?
      !success?
    end
  end

  def Success(data = nil, code: :ok)
    BaseResult.new(code: code, data: data)
  end

  def Error(code: :ko, data: nil)
    BaseResult.new(code: code, data: data, success: false)
  end
end

class Promise
  include Result

  def initialize(value: nil)
    @success = nil
    @catch = nil
    @steps = []
    @result = Success(value)
  end

  def then(data: true, &blk)
    @steps.push({data: data, body: blk})
    self
  end

  def success(&blk)
    @success = blk
    self
  end

  def catch(&blk)
    @catch = blk
    self
  end

  def resolve
    has_error = @steps.find do |step|
      value = step[:data] ? @result.data : @result
      @result = step[:body].call(value)
      if !@result.kind_of?(Result::BaseResult)
        @result = Success(@result)
      end
      @result.error?
    end
    @result = if has_error
      @catch ? @catch.call(@result) : @result
    else
      @success ? @success.call(@result) : @result
    end
    @result
  end
end

module Utils
  include Result
  extend self

  def parse_url(url)
    Success(URI.parse(url))
  rescue URI::InvalidURIError => error
    return Error(code: :invalid_uri, data: error)
  end

  def fetch_uri(uri)
    Success(Net::HTTP.get(uri))
  rescue StandardError => error
    return Error(code: :cannot_fetch_uri, data: error)
  end

  def parse_json(json)
    Success(JSON.parse(json))
  rescue JSON::ParserError => error
    return Error(code: :invalid_json, data: error)
  end

  def get_json_from_url(url)
    Promise.new(value: url).
      then {|url| Utils.parse_url(url)}.
      then {|uri| Utils.fetch_uri(uri)}.
      then {|json| Utils.parse_json(json)}
  end
end

module GithubStargazers
  include Result
  extend self

  def extract_count(data)
    if data.has_key?("message") && data.fetch("message") == "Not Found"
      return Error(code: :repository_not_found)
    end
    if data.has_key?("stargazers_count")
      return Success(data.fetch("stargazers_count"))
    else
      return Error(code: :missing_field, data: data)
    end
  end

  def fetch(repository:)
    Utils.get_json_from_url("https://api.github.com/repos/#{repository}").
      then {|data| extract_count(data)}.
      resolve
  end
end

repository = ARGV[0]
result = GithubStargazers.fetch(repository: repository)
if result.error?
  case result.code
  when :repository_not_found then puts "Repository #{repository} not found."
  else
    puts "Cannot fetch github stargazers for #{repository}: #{result.code} [data:#{result.data.inspect}]"
  end
  exit 1
end

puts "Repository #{repository} has #{result.data} stargazers"
