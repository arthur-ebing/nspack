# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestGrowerGradingRuleInteractor < MiniTestWithHooks
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

    def test_grower_grading_rule
      ProductionApp::GrowerGradingRepo.any_instance.stubs(:find_grower_grading_rule).returns(fake_grower_grading_rule)
      entity = interactor.send(:grower_grading_rule, 1)
      assert entity.is_a?(GrowerGradingRuleFlat)
    end

    def test_create_grower_grading_rule
      attrs = fake_grower_grading_rule.to_h.reject { |k, _| k == :id }
      res = interactor.create_grower_grading_rule(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(GrowerGradingRuleFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_grower_grading_rule_fail
      attrs = fake_grower_grading_rule(rule_name: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_grower_grading_rule(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:rule_name]
    end

    def test_update_grower_grading_rule
      id = create_grower_grading_rule
      attrs = interactor.send(:repo).find_hash(:grower_grading_rules, id).reject { |k, _| k == :id }
      value = attrs[:rule_name]
      attrs[:rule_name] = 'a_change'
      res = interactor.update_grower_grading_rule(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(GrowerGradingRuleFlat, res.instance)
      assert_equal 'a_change', res.instance.rule_name
      refute_equal value, res.instance.rule_name
    end

    def test_update_grower_grading_rule_fail
      id = create_grower_grading_rule
      attrs = interactor.send(:repo).find_hash(:grower_grading_rules, id).reject { |k, _| %i[id rule_name].include?(k) }
      res = interactor.update_grower_grading_rule(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:rule_name]
    end

    def test_delete_grower_grading_rule
      id = create_grower_grading_rule(force_create: true)
      assert_count_changed(:grower_grading_rules, -1) do
        res = interactor.delete_grower_grading_rule(id)
        assert res.success, res.message
      end
    end

    private

    def grower_grading_rule_attrs
      plant_resource_id = create_plant_resource
      line_resource_id = create_plant_resource
      season_id = create_season
      cultivar_group_id = create_cultivar_group
      cultivar_id = create_cultivar

      {
        id: 1,
        rule_name: Faker::Lorem.unique.word,
        description: 'ABC',
        file_name: 'ABC',
        packhouse_resource_id: plant_resource_id,
        line_resource_id: line_resource_id,
        season_id: season_id,
        cultivar_group_id: cultivar_group_id,
        cultivar_id: cultivar_id,
        rebin_rule: false,
        created_by: 'ABC',
        updated_by: 'ABC',
        active: true,
        packhouse_resource_code: 'ABC',
        line_resource_code: 'ABC',
        season_code: 'ABC',
        cultivar_group_code: 'ABC',
        cultivar_name: 'ABC'
      }
    end

    def fake_grower_grading_rule(overrides = {})
      GrowerGradingRuleFlat.new(grower_grading_rule_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= GrowerGradingRuleInteractor.new(current_user, {}, {}, {})
    end
  end
end
