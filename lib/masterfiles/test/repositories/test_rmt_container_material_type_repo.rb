# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestRmtContainerMaterialTypeRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_rmt_container_material_types
    end

    def test_crud_calls
      test_crud_calls_for :rmt_container_material_types, name: :rmt_container_material_type, wrapper: RmtContainerMaterialType
    end

    private

    def repo
      RmtContainerMaterialTypeRepo.new
    end
  end
end
