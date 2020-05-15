# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestBinLoadRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_bin_load_purposes
      assert_respond_to repo, :for_select_bin_loads
      assert_respond_to repo, :for_select_bin_load_products
    end

    def test_crud_calls
      test_crud_calls_for :bin_load_purposes, name: :bin_load_purpose, wrapper: BinLoadPurpose
      test_crud_calls_for :bin_loads, name: :bin_load, wrapper: BinLoad
      test_crud_calls_for :bin_load_products, name: :bin_load_product, wrapper: BinLoadProduct
    end

    private

    def repo
      BinLoadRepo.new
    end
  end
end
