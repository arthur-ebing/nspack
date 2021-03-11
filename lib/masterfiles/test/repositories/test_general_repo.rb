# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestGeneralRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_uom_types
      assert_respond_to repo, :for_select_uoms
      assert_respond_to repo, :for_select_mf_variant
      assert_respond_to repo, :for_select_mf_transformation
    end

    def test_crud_calls
      test_crud_calls_for :uom_types, name: :uom_type, wrapper: UomType
      test_crud_calls_for :uoms, name: :uom, wrapper: Uom
      test_crud_calls_for :masterfile_variants, name: :masterfile_variant, wrapper: MasterfileVariant
      test_crud_calls_for :masterfile_transformations, name: :masterfile_transformation, wrapper: MasterfileTransformation
    end

    private

    def repo
      GeneralRepo.new
    end
  end
end
