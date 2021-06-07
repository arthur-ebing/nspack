# frozen_string_literal: true

# A class for logging HTTP call responses
module Crossbeams
  class HTTPTextCallLogger
    attr_reader :keyword, :log_body, :log_path

    def initialize(keyword, log_body: true, log_path: nil)
      @log_body = log_body
      @keyword = keyword
      @log_path = log_path
    end

    def log_call(url, request, response, benchmk) # rubocop:disable Metrics/AbcSize
      out = <<~STR
        -------------------
        #{keyword}
        #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}
        -------------------
        ** REQUEST **
        method: #{request.method}
        url: #{url}
        request_body: #{request_body(request)}
        #{request.each_header.map { |k, v| "Header: #{k}: #{v}" }.join("\n")}

        ** RESPONSE **
        response_code: #{response.code}#{response_body(response)}
        #{response.each_header.map { |k, v| "Header: #{k}: #{v}" }.join("\n")}
        encoding: #{response['Content-Encoding']}
        content_type: #{response['Content-Type']}
        benchmark: #{benchmk}
      STR

      if log_path.nil?
        puts out
      else
        File.open(log_path, 'a') { |f| f << out }
      end
    end

    def log_fail(url, request, exception) # rubocop:disable Metrics/AbcSize
      out = <<~STR
        -------------------
        #{keyword}
        #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}
        -------------------
        ** REQUEST **
        method: #{request.method}
        url: #{url}
        request_body: #{request_body(request)}
        #{request.each_header.map { |k, v| "Header: #{k}: #{v}" }.join("\n")}

        ** FAILED **
        Exception: #{exception.class}
        Message: #{exception.message}
      STR

      if log_path.nil?
        puts out
      else
        File.open(log_path, 'a') { |f| f << out }
      end
    end

    private

    def request_body(request)
      body_stream = request.body_stream
      if body_stream
        body_stream.to_s # read and rewind for RestClient::Payload::Base
        body_stream.rewind if body_stream.respond_to?(:rewind) # RestClient::Payload::Base has no method rewind
        body_stream.read
      elsif request.body.nil? || request.body.empty?
        nil # body
      else
        request.body
      end
    end

    def response_body(response)
      return '' unless log_body

      "\nresponse_body: #{response.body}"
    end
  end
end
