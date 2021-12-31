# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestPresortGrowerGradingPoolInteractor < MiniTestWithHooks
    include PresortGrowerGradingFactory
    include RmtDeliveryFactory
    include ProductionApp::ResourceFactory
    include ProductionApp::ProductionRunFactory
    include ProductionApp::ProductSetupFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::TargetMarketFactory
    include MasterfilesApp::FruitFactory
    include MasterfilesApp::PartyFactory
    include RawMaterialsApp::RmtBinFactory
    include MasterfilesApp::LocationFactory
    include MasterfilesApp::FarmFactory
    include MasterfilesApp::RmtContainerFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(RawMaterialsApp::PresortGrowerGradingRepo)
    end

    def test_presort_grower_grading_pool
      RawMaterialsApp::PresortGrowerGradingRepo.any_instance.stubs(:find_presort_grower_grading_pool).returns(fake_presort_grower_grading_pool)
      entity = interactor.send(:presort_grower_grading_pool, 1)
      assert entity.is_a?(PresortGrowerGradingPool)
    end

    def test_create_presort_grower_grading_pool
      attrs = fake_presort_grower_grading_pool.to_h.reject { |k, _| k == :id }
      res = interactor.create_presort_grower_grading_pool(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PresortGrowerGradingPoolFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_presort_grower_grading_pool_fail
      attrs = fake_presort_grower_grading_pool(maf_lot_number: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_presort_grower_grading_pool(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:maf_lot_number]
    end

    def test_update_presort_grower_grading_pool
      id = create_presort_grower_grading_pool
      attrs = interactor.send(:repo).find_hash(:presort_grower_grading_pools, id).reject { |k, _| k == :id }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_presort_grower_grading_pool(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PresortGrowerGradingPoolFlat, res.instance)
      assert_equal 'a_change', res.instance.description
      refute_equal value, res.instance.description
    end

    def test_update_presort_grower_grading_pool_fail
      id = create_presort_grower_grading_pool
      attrs = interactor.send(:repo).find_hash(:presort_grower_grading_pools, id).reject { |k, _| %i[id description].include?(k) }
      res = interactor.update_presort_grower_grading_pool(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:description]
    end

    def test_delete_presort_grower_grading_pool
      id = create_presort_grower_grading_pool(force_create: true)
      assert_count_changed(:presort_grower_grading_pools, -1) do
        res = interactor.delete_presort_grower_grading_pool(id)
        assert res.success, res.message
      end
    end

    private

    def presort_grower_grading_pool_attrs
      repo = BaseRepo.new
      bin_id = create_rmt_bin(presort_tip_lot_number: '123456', bin_tipped: true)
      maf_lot_number = repo.get(:rmt_bins, :presort_tip_lot_number, bin_id)
      season_id = create_season
      commodity_id = create_commodity
      farm_id = create_farm

      {
        id: 1,
        maf_lot_number: maf_lot_number,
        description: 'ABC',
        track_slms_indicator_code: 'ABC',
        season_id: season_id,
        commodity_id: commodity_id,
        farm_id: farm_id,
        rmt_bin_count: 1,
        rmt_bin_weight: 1.0,
        pro_rata_factor: 1.0,
        completed: false,
        created_by: 'ABC',
        updated_by: 'ABC',
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
    end

    def fake_presort_grower_grading_pool(overrides = {})
      PresortGrowerGradingPool.new(presort_grower_grading_pool_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PresortGrowerGradingPoolInteractor.new(current_user, {}, {}, {})
    end
  end
end
