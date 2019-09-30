# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPortTypeRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_port_types
    end

    def test_crud_calls
      test_crud_calls_for :port_types, name: :port_type, wrapper: PortType
    end

    private

    def repo
      PortTypeRepo.new
    end
  end
end
