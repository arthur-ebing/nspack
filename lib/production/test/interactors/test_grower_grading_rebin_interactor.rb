# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestGrowerGradingRebinInteractor < MiniTestWithHooks
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

    def test_grower_grading_rebin
      ProductionApp::GrowerGradingRepo.any_instance.stubs(:find_grower_grading_rebin).returns(fake_grower_grading_rebin)
      entity = interactor.send(:grower_grading_rebin, 1)
      assert entity.is_a?(GrowerGradingRebinFlat)
    end

    def test_create_grower_grading_rebin
      attrs = fake_grower_grading_rebin.to_h.reject { |k, _| k == :id }
      res = interactor.create_grower_grading_rebin(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(GrowerGradingRebinFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_grower_grading_rebin_fail
      attrs = fake_grower_grading_rebin(grower_grading_pool_id: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_grower_grading_rebin(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:grower_grading_pool_id]
    end

    def test_update_grower_grading_rebin
      id = create_grower_grading_rebin
      attrs = interactor.send(:repo).find_hash(:grower_grading_rebins, id).reject { |k, _| k == :id }
      value = attrs[:updated_by]
      attrs[:updated_by] = 'a_change'
      res = interactor.update_grower_grading_rebin(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(GrowerGradingRebinFlat, res.instance)
      assert_equal 'a_change', res.instance.updated_by
      refute_equal value, res.instance.updated_by
    end

    def test_update_grower_grading_rebin_fail
      id = create_grower_grading_rebin
      attrs = interactor.send(:repo).find_hash(:grower_grading_rebins, id).reject { |k, _| %i[id grower_grading_pool_id].include?(k) }
      res = interactor.update_grower_grading_rebin(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:grower_grading_pool_id]
    end

    def test_delete_grower_grading_rebin
      id = create_grower_grading_rebin(force_create: true)
      assert_count_changed(:grower_grading_rebins, -1) do
        res = interactor.delete_grower_grading_rebin(id)
        assert res.success, res.message
      end
    end

    private

    def grower_grading_rebin_attrs
      grower_grading_pool_id = create_grower_grading_pool
      grower_grading_rule_item_id = create_grower_grading_rule_item
      rmt_class_id = create_rmt_class
      rmt_size_id = create_rmt_size
      std_fruit_size_count_id = create_std_fruit_size_count
      fruit_actual_counts_for_pack_id = create_fruit_actual_counts_for_pack
      fruit_size_reference_id = create_fruit_size_reference

      {
        id: 1,
        grower_grading_pool_id: grower_grading_pool_id,
        grower_grading_rule_item_id: grower_grading_rule_item_id,
        rmt_class_id: rmt_class_id,
        rmt_size_id: rmt_size_id,
        std_fruit_size_count_id: std_fruit_size_count_id,
        fruit_actual_counts_for_pack_id: fruit_actual_counts_for_pack_id,
        fruit_size_reference_id: fruit_size_reference_id,
        changes_made: {},
        rebins_quantity: 1,
        gross_weight: 1.0,
        nett_weight: 1.0,
        pallet_rebin: false,
        completed: false,
        updated_by: Faker::Lorem.unique.word,
        active: true,
        pool_name: 'ABC',
        rmt_class_code: 'ABC',
        rmt_size_code: 'ABC',
        actual_count: 1,
        size_count: 1,
        size_reference: 'ABC',
        grading_rebin_code: 'ABC'
      }
    end

    def fake_grower_grading_rebin(overrides = {})
      GrowerGradingRebinFlat.new(grower_grading_rebin_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= GrowerGradingRebinInteractor.new(current_user, {}, {}, {})
    end
  end
end
