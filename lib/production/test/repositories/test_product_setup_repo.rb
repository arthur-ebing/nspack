# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestProductSetupRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_product_setup_templates
      assert_respond_to repo, :for_select_product_setups
    end

    def test_crud_calls
      test_crud_calls_for :product_setup_templates, name: :product_setup_template, wrapper: ProductSetupTemplate
      test_crud_calls_for :product_setups, name: :product_setup, wrapper: ProductSetup
    end

    private

    def repo
      ProductSetupRepo.new
    end
  end
end
