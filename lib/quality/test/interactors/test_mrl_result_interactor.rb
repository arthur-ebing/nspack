# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module QualityApp
  class TestMrlResultInteractor < MiniTestWithHooks
    include MrlResultFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::FarmFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::QualityFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::LocationFactory
    include ProductionApp::ResourceFactory
    include ProductionApp::ProductSetupFactory
    include ProductionApp::ProductionRunFactory
    include ProductionApp::ProductionRunFactory
    include RawMaterialsApp::RmtDeliveryFactory
    include MasterfilesApp::RmtContainerFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(QualityApp::MrlResultRepo)
    end

    def test_mrl_result
      QualityApp::MrlResultRepo.any_instance.stubs(:find_mrl_result).returns(fake_mrl_result)
      entity = interactor.send(:mrl_result, 1)
      assert entity.is_a?(MrlResult)
    end

    def test_create_mrl_result
      attrs = fake_mrl_result.to_h.reject { |k, _| k == :id }
      res = interactor.create_mrl_result(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(MrlResultFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_mrl_result_fail
      attrs = fake_mrl_result(season_id: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_mrl_result(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:season_id]
    end

    def test_update_mrl_result
      id = create_mrl_result
      attrs = interactor.send(:repo).find_hash(:mrl_results, id).reject { |k, _| k == :id }
      value = attrs[:waybill_number]
      attrs[:waybill_number] = 'a_change'
      res = interactor.update_mrl_result(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(MrlResultFlat, res.instance)
      assert_equal 'a_change', res.instance.waybill_number
      refute_equal value, res.instance.waybill_number
    end

    def test_update_mrl_result_fail
      id = create_mrl_result
      attrs = interactor.send(:repo).find_hash(:mrl_results, id).reject { |k, _| %i[id season_id].include?(k) }
      res = interactor.update_mrl_result(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:season_id]
    end

    def test_delete_mrl_result
      id = create_mrl_result(force_create: true)
      assert_count_changed(:mrl_results, -1) do
        res = interactor.delete_mrl_result(id)
        assert res.success, res.message
      end
    end

    private

    def mrl_result_attrs
      mrl_result_id = create_mrl_result
      cultivar_id = create_cultivar
      puc_id = create_puc
      season_id = create_season
      rmt_delivery_id = create_rmt_delivery
      farm_id = create_farm
      laboratory_id = create_laboratory
      mrl_sample_type_id = create_mrl_sample_type
      orchard_id = create_orchard
      production_run_id = create_production_run

      {
        id: 1,
        post_harvest_parent_mrl_result_id: mrl_result_id,
        cultivar_id: cultivar_id,
        puc_id: puc_id,
        season_id: season_id,
        rmt_delivery_id: rmt_delivery_id,
        farm_id: farm_id,
        laboratory_id: laboratory_id,
        mrl_sample_type_id: mrl_sample_type_id,
        orchard_id: orchard_id,
        production_run_id: production_run_id,
        waybill_number: Faker::Lorem.unique.word,
        reference_number: 'ABC',
        sample_number: 'ABC',
        ph_level: 1,
        num_active_ingredients: 1,
        max_num_chemicals_passed: false,
        mrl_sample_passed: false,
        pre_harvest_result: false,
        post_harvest_result: false,
        fruit_received_at: '2010-01-01 12:00',
        sample_submitted_at: '2010-01-01 12:00',
        result_received_at: '2010-01-01 12:00',
        active: true
      }
    end

    def fake_mrl_result(overrides = {})
      MrlResult.new(mrl_result_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= MrlResultInteractor.new(current_user, {}, {}, {})
    end
  end
end
