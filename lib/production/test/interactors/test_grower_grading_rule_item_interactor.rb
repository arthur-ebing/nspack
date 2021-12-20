# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestGrowerGradingRuleItemInteractor < MiniTestWithHooks
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

    def test_grower_grading_rule_item
      ProductionApp::GrowerGradingRepo.any_instance.stubs(:find_grower_grading_rule_item).returns(fake_grower_grading_rule_item)
      entity = interactor.send(:grower_grading_rule_item, 1)
      assert entity.is_a?(GrowerGradingRuleItemFlat)
    end

    def test_create_grower_grading_rule_item
      attrs = fake_grower_grading_rule_item.to_h.reject { |k, _| k == :id }
      res = interactor.create_grower_grading_rule_item(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(GrowerGradingRuleItemFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_grower_grading_rule_item_fail
      attrs = fake_grower_grading_rule_item(grower_grading_rule_id: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_grower_grading_rule_item(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:grower_grading_rule_id]
    end

    def test_update_grower_grading_rule_item
      id = create_grower_grading_rule_item
      attrs = interactor.send(:repo).find_hash(:grower_grading_rule_items, id).reject { |k, _| k == :id }
      value = attrs[:created_by]
      attrs[:created_by] = 'a_change'
      res = interactor.update_grower_grading_rule_item(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(GrowerGradingRuleItemFlat, res.instance)
      assert_equal 'a_change', res.instance.created_by
      refute_equal value, res.instance.created_by
    end

    def test_update_grower_grading_rule_item_fail
      id = create_grower_grading_rule_item
      attrs = interactor.send(:repo).find_hash(:grower_grading_rule_items, id).reject { |k, _| %i[id grower_grading_rule_id].include?(k) }
      res = interactor.update_grower_grading_rule_item(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:grower_grading_rule_id]
    end

    def test_delete_grower_grading_rule_item
      id = create_grower_grading_rule_item(force_create: true)
      assert_count_changed(:grower_grading_rule_items, -1) do
        res = interactor.delete_grower_grading_rule_item(id)
        assert res.success, res.message
      end
    end

    private

    def grower_grading_rule_item_attrs
      grower_grading_rule_id = create_grower_grading_rule
      commodity_id = create_commodity
      grade_id = create_grade
      std_fruit_size_count_id = create_std_fruit_size_count
      fruit_actual_counts_for_pack_id = create_fruit_actual_counts_for_pack
      marketing_variety_id = create_marketing_variety
      rmt_class_id = create_rmt_class
      rmt_size_id = create_rmt_size
      fruit_size_reference_id = create_fruit_size_reference
      inspection_type_id = create_inspection_type

      {
        id: 1,
        grower_grading_rule_id: grower_grading_rule_id,
        commodity_id: commodity_id,
        grade_id: grade_id,
        std_fruit_size_count_id: std_fruit_size_count_id,
        fruit_actual_counts_for_pack_id: fruit_actual_counts_for_pack_id,
        marketing_variety_id: marketing_variety_id,
        rmt_class_id: rmt_class_id,
        rmt_size_id: rmt_size_id,
        fruit_size_reference_id: fruit_size_reference_id,
        inspection_type_id: inspection_type_id,
        legacy_data: {},
        changes: {},
        created_by: 'ABC',
        updated_by: 'ABC',
        active: true,
        commodity_code: 'ABC',
        marketing_variety_code: 'ABC',
        grade_code: 'ABC',
        inspection_type_code: 'ABC',
        rmt_class_code: 'ABC',
        rmt_size_code: 'ABC',
        actual_count: 1,
        size_count: 1,
        size_reference: 'ABC',
        grading_rule: 'ABC',
        rule_item_code: 'ABC'
      }
    end

    def fake_grower_grading_rule_item(overrides = {})
      GrowerGradingRuleItemFlat.new(grower_grading_rule_item_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= GrowerGradingRuleItemInteractor.new(current_user, {}, {}, {})
    end
  end
end
