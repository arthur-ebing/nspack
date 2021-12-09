# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestGrowerGradingPoolInteractor < MiniTestWithHooks
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

    def test_grower_grading_pool
      ProductionApp::GrowerGradingRepo.any_instance.stubs(:find_grower_grading_pool).returns(fake_grower_grading_pool)
      entity = interactor.send(:grower_grading_pool, 1)
      assert entity.is_a?(GrowerGradingPoolFlat)
    end

    def test_create_grower_grading_pool
      attrs = fake_grower_grading_pool.to_h.reject { |k, _| k == :id }
      res = interactor.create_grower_grading_pool(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(GrowerGradingPoolFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_grower_grading_pool_fail
      attrs = fake_grower_grading_pool(pool_name: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_grower_grading_pool(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:pool_name]
    end

    def test_update_grower_grading_pool
      id = create_grower_grading_pool
      attrs = interactor.send(:repo).find_hash(:grower_grading_pools, id).reject { |k, _| k == :id }
      value = attrs[:pool_name]
      attrs[:pool_name] = 'a_change'
      res = interactor.update_grower_grading_pool(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(GrowerGradingPoolFlat, res.instance)
      assert_equal 'a_change', res.instance.pool_name
      refute_equal value, res.instance.pool_name
    end

    def test_update_grower_grading_pool_fail
      id = create_grower_grading_pool
      attrs = interactor.send(:repo).find_hash(:grower_grading_pools, id).reject { |k, _| %i[id pool_name].include?(k) }
      res = interactor.update_grower_grading_pool(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:pool_name]
    end

    def test_delete_grower_grading_pool
      id = create_grower_grading_pool(force_create: true)
      assert_count_changed(:grower_grading_pools, -1) do
        res = interactor.delete_grower_grading_pool(id)
        assert res.success, res.message
      end
    end

    private

    def grower_grading_pool_attrs
      grower_grading_rule_id = create_grower_grading_rule
      production_run_id = create_production_run
      season_id = create_season
      cultivar_group_id = create_cultivar_group
      cultivar_id = create_cultivar
      commodity_id = create_commodity
      farm_id = create_farm
      inspection_type_id = create_inspection_type

      {
        id: 1,
        grower_grading_rule_id: grower_grading_rule_id,
        pool_name: Faker::Lorem.unique.word,
        description: 'ABC',
        production_run_id: production_run_id,
        season_id: season_id,
        cultivar_group_id: cultivar_group_id,
        cultivar_id: cultivar_id,
        commodity_id: commodity_id,
        farm_id: farm_id,
        inspection_type_id: inspection_type_id,
        bin_quantity: 1,
        gross_weight: 1.0,
        nett_weight: 1.0,
        pro_rata_factor: 1.0,
        legacy_data: {},
        completed: false,
        rule_applied: false,
        created_by: 'ABC',
        updated_by: 'ABC',
        rule_applied_by: 'ABC',
        rule_applied_at: '2010-01-01 12:00',
        active: true,
        production_run_code: 'ABC',
        season_code: 'ABC',
        cultivar_group_code: 'ABC',
        cultivar_name: 'ABC',
        commodity_code: 'ABC',
        farm_code: 'ABC',
        inspection_type_code: 'ABC'
      }
    end

    def fake_grower_grading_pool(overrides = {})
      GrowerGradingPoolFlat.new(grower_grading_pool_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= GrowerGradingPoolInteractor.new(current_user, {}, {}, {})
    end
  end
end
