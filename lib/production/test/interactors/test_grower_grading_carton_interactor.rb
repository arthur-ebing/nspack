# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestGrowerGradingCartonInteractor < MiniTestWithHooks
    include GrowerGradingFactory
    include ResourceFactory
    include ProductionRunFactory
    include ProductSetupFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::PackagingFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::MarketingFactory
    include MasterfilesApp::TargetMarketFactory
    include MasterfilesApp::FruitFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::GeneralFactory
    include RawMaterialsApp::RmtBinFactory
    include MasterfilesApp::LocationFactory
    include MasterfilesApp::InspectionFactory
    include MasterfilesApp::FarmFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(ProductionApp::GrowerGradingRepo)
    end

    def test_grower_grading_carton
      ProductionApp::GrowerGradingRepo.any_instance.stubs(:find_grower_grading_carton).returns(fake_grower_grading_carton)
      entity = interactor.send(:grower_grading_carton, 1)
      assert entity.is_a?(GrowerGradingCartonFlat)
    end

    def test_create_grower_grading_carton
      attrs = fake_grower_grading_carton.to_h.reject { |k, _| k == :id }
      res = interactor.create_grower_grading_carton(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(GrowerGradingCartonFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_grower_grading_carton_fail
      attrs = fake_grower_grading_carton(grower_grading_pool_id: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_grower_grading_carton(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:grower_grading_pool_id]
    end

    def test_update_grower_grading_carton
      id = create_grower_grading_carton
      attrs = interactor.send(:repo).find_hash(:grower_grading_cartons, id).reject { |k, _| k == :id }
      value = attrs[:updated_by]
      attrs[:updated_by] = 'a_change'
      res = interactor.update_grower_grading_carton(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(GrowerGradingCartonFlat, res.instance)
      assert_equal 'a_change', res.instance.updated_by
      refute_equal value, res.instance.updated_by
    end

    def test_update_grower_grading_carton_fail
      id = create_grower_grading_carton
      attrs = interactor.send(:repo).find_hash(:grower_grading_cartons, id).reject { |k, _| %i[id grower_grading_pool_id].include?(k) }
      res = interactor.update_grower_grading_carton(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:grower_grading_pool_id]
    end

    def test_delete_grower_grading_carton
      id = create_grower_grading_carton(force_create: true)
      assert_count_changed(:grower_grading_cartons, -1) do
        res = interactor.delete_grower_grading_carton(id)
        assert res.success, res.message
      end
    end

    private

    def grower_grading_carton_attrs
      grower_grading_pool_id = create_grower_grading_pool
      grower_grading_rule_item_id = create_grower_grading_rule_item
      product_resource_allocation_id = create_product_resource_allocation
      pm_bom_id = create_pm_bom
      std_fruit_size_count_id = create_std_fruit_size_count
      fruit_actual_counts_for_pack_id = create_fruit_actual_counts_for_pack
      party_role_id = create_party_role
      target_market_group_id = create_target_market_group
      target_market_id = create_target_market
      inventory_code_id = create_inventory_code
      rmt_class_id = create_rmt_class
      rmt_size_id = create_rmt_size
      grade_id = create_grade
      marketing_variety_id = create_marketing_variety
      fruit_size_reference_id = create_fruit_size_reference

      {
        id: 1,
        grower_grading_pool_id: grower_grading_pool_id,
        grower_grading_rule_item_id: grower_grading_rule_item_id,
        product_resource_allocation_id: product_resource_allocation_id,
        pm_bom_id: pm_bom_id,
        std_fruit_size_count_id: std_fruit_size_count_id,
        fruit_actual_counts_for_pack_id: fruit_actual_counts_for_pack_id,
        marketing_org_party_role_id: party_role_id,
        packed_tm_group_id: target_market_group_id,
        target_market_id: target_market_id,
        inventory_code_id: inventory_code_id,
        rmt_class_id: rmt_class_id,
        rmt_size_id: rmt_size_id,
        grade_id: grade_id,
        marketing_variety_id: marketing_variety_id,
        fruit_size_reference_id: fruit_size_reference_id,
        changes_made: {},
        carton_quantity: 1,
        inspected_quantity: 1,
        not_inspected_quantity: 1,
        failed_quantity: 1,
        gross_weight: 1.0,
        nett_weight: 1.0,
        completed: false,
        updated_by: Faker::Lorem.unique.word,
        active: true,
        pool_name: 'ABC',
        bom_code: 'ABC',
        actual_count: 1,
        size_count: 1,
        marketing_org: 'ABC',
        packed_tm_group: 'ABC',
        target_market: 'ABC',
        inventory_code: 'ABC',
        rmt_class_code: 'ABC',
        grade_code: 'ABC',
        marketing_variety_code: 'ABC',
        size_reference: 'ABC',
        grading_carton_code: 'ABC'
      }
    end

    def fake_grower_grading_carton(overrides = {})
      GrowerGradingCartonFlat.new(grower_grading_carton_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= GrowerGradingCartonInteractor.new(current_user, {}, {}, {})
    end
  end
end
