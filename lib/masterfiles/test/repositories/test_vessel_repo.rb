# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestVesselRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_vessels
    end

    def test_crud_calls
      test_crud_calls_for :vessels, name: :vessel, wrapper: Vessel
    end

    private

    def repo
      VesselRepo.new
    end
  end
end
