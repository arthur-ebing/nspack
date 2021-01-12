# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestBomRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_pm_types
      assert_respond_to repo, :for_select_pm_subtypes
      assert_respond_to repo, :for_select_pm_products
      assert_respond_to repo, :for_select_pm_boms
      assert_respond_to repo, :for_select_pm_boms_products
      assert_respond_to repo, :for_select_pm_composition_levels
      assert_respond_to repo, :for_select_pm_marks
    end

    def test_crud_calls
      test_crud_calls_for :pm_types, name: :pm_type, wrapper: PmType
      test_crud_calls_for :pm_subtypes, name: :pm_subtype, wrapper: PmSubtype
      test_crud_calls_for :pm_products, name: :pm_product, wrapper: PmProduct
      test_crud_calls_for :pm_boms, name: :pm_bom, wrapper: PmBom
      test_crud_calls_for :pm_boms_products, name: :pm_boms_product, wrapper: PmBomsProduct
      test_crud_calls_for :pm_composition_levels, name: :pm_composition_level, wrapper: PmCompositionLevel
      test_crud_calls_for :pm_marks, name: :pm_mark, wrapper: PmMark
    end

    private

    def repo
      BomRepo.new
    end
  end
end
