# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestMrlRequirementRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_mrl_requirements
    end

    def test_crud_calls
      test_crud_calls_for :mrl_requirements, name: :mrl_requirement, wrapper: MrlRequirement
    end

    private

    def repo
      MrlRequirementRepo.new
    end
  end
end
