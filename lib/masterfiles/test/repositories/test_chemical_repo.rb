# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestChemicalRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_chemicals
    end

    def test_crud_calls
      test_crud_calls_for :chemicals, name: :chemical, wrapper: Chemical
    end

    private

    def repo
      ChemicalRepo.new
    end
  end
end
