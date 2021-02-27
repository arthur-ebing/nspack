# frozen_string_literal: true

require File.join(File.expand_path('./../', __FILE__), 'test_helper')

class TestHTTPCalls < MiniTestWithHooks
  def test_defaults
    http = Crossbeams::HTTPCalls.new
    refute http.use_ssl
    assert_nil http.instance_variable_get(:@responder)
    assert_equal 5, http.instance_variable_get(:@open_timeout)
    assert_equal 10, http.instance_variable_get(:@read_timeout)
  end

  def test_ssl_auto_setting
    http = Crossbeams::HTTPCalls.new
    Net::HTTP.any_instance.expects(:request).returns(OpenStruct.new(code: '200', body: 'ok'))
    http.request_get('http://place.com')
    refute http.use_ssl

    Net::HTTP.any_instance.expects(:request).returns(OpenStruct.new(code: '200', body: 'ok'))
    http.request_get('https://place.com')
    assert http.use_ssl
  end
end
