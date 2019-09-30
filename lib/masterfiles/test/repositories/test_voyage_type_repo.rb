# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestVoyageTypeRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_voyage_types
    end

    def test_crud_calls
      test_crud_calls_for :voyage_types, name: :voyage_type, wrapper: VoyageType
    end

    private

    def repo
      VoyageTypeRepo.new
    end
  end
end
