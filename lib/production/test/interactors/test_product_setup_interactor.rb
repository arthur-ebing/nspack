# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestProductSetupInteractor < MiniTestWithHooks
    include ProductSetupFactory
    include MasterfilesApp::MarketingFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::GeneralFactory
    include MasterfilesApp::FruitFactory
    include MasterfilesApp::PackagingFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::TargetMarketFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(ProductionApp::ProductSetupRepo)
    end

    def test_product_setup
      ProductionApp::ProductSetupRepo.any_instance.stubs(:find_product_setup).returns(fake_product_setup)
      entity = interactor.send(:product_setup, 1)
      assert entity.is_a?(ProductSetup)
    end

    def test_create_product_setup
      attrs = fake_product_setup.to_h.reject { |k, _| k == :id }
      res = interactor.create_product_setup(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ProductSetup, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_product_setup_fail
      attrs = fake_product_setup(marketing_variety_id: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_product_setup(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:marketing_variety_id]
    end

    def test_update_product_setup
      id = create_product_setup
      attrs = interactor.send(:repo).find_product_setup(id)
      attrs = attrs.to_h
      value = attrs[:client_size_reference]
      attrs[:client_size_reference] = 'a_change'
      res = interactor.update_product_setup(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ProductSetup, res.instance)
      assert_equal 'a_change', res.instance.client_size_reference
      refute_equal value, res.instance.client_size_reference
    end

    def test_update_product_setup_fail
      id = create_product_setup
      attrs = interactor.send(:repo).find_product_setup(id)
      attrs = attrs.to_h
      attrs.delete(:marketing_variety_id)
      value = attrs[:client_product_code]
      attrs[:client_product_code] = 'a_change'
      res = interactor.update_product_setup(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:marketing_variety_id]
      after = interactor.send(:repo).find_product_setup(id)
      after = after.to_h
      refute_equal 'a_change', after[:client_product_code]
      assert_equal value, after[:client_product_code]
    end

    def test_delete_product_setup
      id = create_product_setup
      assert_count_changed(:product_setups, -1) do
        res = interactor.delete_product_setup(id)
        assert res.success, res.message
      end
    end

    private

    def product_setup_attrs
      product_setup_template_id = create_product_setup_template
      marketing_variety_id = create_marketing_variety
      basic_pack_code_id = create_basic_pack_code
      standard_pack_code_id = create_standard_pack_code
      fruit_size_reference_id = create_fruit_size_reference
      marketing_org_party_role_id = create_party_role('O', AppConst::ROLE_MARKETER)
      packed_tm_group_id = create_target_market_group
      target_market_id = create_target_market
      mark_id = create_mark
      pm_mark_id = create_pm_mark
      pallet_format_id = create_pallet_format
      cartons_per_pallet_id = create_cartons_per_pallet
      grade_id = create_grade
      inventory_code_id = create_inventory_code
      fruit_actual_counts_for_pack_id = create_fruit_actual_counts_for_pack

      {
        id: 1,
        product_setup_template_id: product_setup_template_id,
        marketing_variety_id: marketing_variety_id,
        customer_variety_id: nil,
        std_fruit_size_count_id: nil,
        basic_pack_code_id: basic_pack_code_id,
        standard_pack_code_id: standard_pack_code_id,
        fruit_actual_counts_for_pack_id: fruit_actual_counts_for_pack_id,
        fruit_size_reference_id: fruit_size_reference_id,
        marketing_org_party_role_id: marketing_org_party_role_id,
        packed_tm_group_id: packed_tm_group_id,
        mark_id: mark_id,
        pm_mark_id: pm_mark_id,
        inventory_code_id: inventory_code_id,
        pallet_format_id: pallet_format_id,
        cartons_per_pallet_id: cartons_per_pallet_id,
        pm_bom_id: nil,
        extended_columns: {},
        client_size_reference: Faker::Lorem.unique.word,
        client_product_code: 'ABC',
        treatment_ids: [1, 2, 3],
        marketing_order_number: 'ABC',
        sell_by_code: 'ABC',
        pallet_label_name: 'ABC',
        active: true,
        product_setup_code: 'ABC',
        in_production: true,
        commodity_id: 1,
        grade_id: grade_id,
        product_chars: 'ABC',
        pallet_base_id: 1,
        pallet_stack_type_id: 1,
        pm_type_id: 1,
        pm_subtype_id: 1,
        target_market_id: target_market_id,
        description: 'ABC',
        erp_bom_code: 'ABC',
        gtin_code: 'ABC'
      }
    end

    def fake_product_setup(overrides = {})
      ProductSetup.new(product_setup_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= ProductSetupInteractor.new(current_user, {}, {}, {})
    end
  end
end
