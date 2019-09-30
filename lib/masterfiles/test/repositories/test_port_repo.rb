# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPortRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_ports
    end

    def test_crud_calls
      test_crud_calls_for :ports, name: :port, wrapper: Port
    end

    private

    def repo
      PortRepo.new
    end
  end
end
