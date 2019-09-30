# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestVesselTypeRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_vessel_types
    end

    def test_crud_calls
      test_crud_calls_for :vessel_types, name: :vessel_type, wrapper: VesselType
    end

    private

    def repo
      VesselTypeRepo.new
    end
  end
end
