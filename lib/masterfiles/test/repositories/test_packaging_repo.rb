# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPackagingRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_pallet_bases
      assert_respond_to repo, :for_select_pallet_stack_types
      assert_respond_to repo, :for_select_pallet_formats
      assert_respond_to repo, :for_select_cartons_per_pallet
      assert_respond_to repo, :for_select_packing_methods
    end

    def test_crud_calls
      test_crud_calls_for :pallet_bases, name: :pallet_base, wrapper: PalletBase
      test_crud_calls_for :pallet_stack_types, name: :pallet_stack_type, wrapper: PalletStackType
      test_crud_calls_for :pallet_formats, name: :pallet_format, wrapper: PalletFormat
      test_crud_calls_for :cartons_per_pallet, name: :cartons_per_pallet, wrapper: CartonsPerPallet
      test_crud_calls_for :packing_methods, name: :packing_method, wrapper: PackingMethod
    end

    private

    def repo
      PackagingRepo.new
    end
  end
end
