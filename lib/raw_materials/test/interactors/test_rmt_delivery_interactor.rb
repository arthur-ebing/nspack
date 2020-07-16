# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestRmtDeliveryInteractor < MiniTestWithHooks
    include RmtDeliveryFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::FarmsFactory
    include MasterfilesApp::CalendarFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(RawMaterialsApp::RmtDeliveryRepo)
    end

    def test_rmt_delivery
      RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_delivery).returns(fake_rmt_delivery)
      entity = interactor.send(:rmt_delivery, 1)
      assert entity.is_a?(RmtDelivery)
    end

    def test_create_rmt_delivery
      attrs = fake_rmt_delivery.to_h.reject { |k, _| k == :id }
      res = nil
      interactor.stub(:get_rmt_delivery_season, attrs[:season_id]) do
        res = interactor.create_rmt_delivery(attrs)
      end
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(RmtDelivery, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_rmt_delivery_fail
      attrs = fake_rmt_delivery(farm_id: nil).to_h.reject { |k, _| k == :id }
      res = nil
      interactor.stub(:get_rmt_delivery_season, attrs[:season_id]) do
        res = interactor.create_rmt_delivery(attrs)
      end
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:farm_id]
    end

    def test_update_rmt_delivery
      id = create_rmt_delivery
      attrs = interactor.send(:repo).find_hash(:rmt_deliveries, id).reject { |k, _| k == :id }
      value = attrs[:truck_registration_number]
      attrs[:truck_registration_number] = 'a_change'
      res = nil
      interactor.stub(:get_rmt_delivery_season, attrs[:season_id]) do
        res = interactor.update_rmt_delivery(id, attrs)
      end
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(RmtDelivery, res.instance)
      assert_equal 'a_change', res.instance.truck_registration_number
      refute_equal value, res.instance.truck_registration_number
    end

    def test_update_rmt_delivery_fail
      id = create_rmt_delivery
      attrs = interactor.send(:repo).find_hash(:rmt_deliveries, id).reject { |k, _| %i[id farm_id].include?(k) }
      res = interactor.update_rmt_delivery(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:farm_id]
      after = interactor.send(:repo).find_hash(:rmt_deliveries, id)
      refute_equal 99, after[:farm_id]
    end

    def test_delete_rmt_delivery
      id = create_rmt_delivery
      assert_count_changed(:rmt_deliveries, -1) do
        res = interactor.delete_rmt_delivery(id)
        assert res.success, res.message
      end
    end

    private

    def rmt_delivery_attrs
      orchard_id = create_orchard
      cultivar_id = create_cultivar
      rmt_delivery_destination_id = create_rmt_delivery_destination
      season_id = create_season
      farm_id = create_farm
      puc_id = create_puc

      {
        id: 1,
        orchard_id: orchard_id,
        cultivar_id: cultivar_id,
        rmt_delivery_destination_id: rmt_delivery_destination_id,
        season_id: season_id,
        farm_id: farm_id,
        puc_id: puc_id,
        truck_registration_number: Faker::Lorem.unique.word,
        reference_number: Faker::Lorem.unique.word,
        qty_damaged_bins: 1,
        qty_empty_bins: 1,
        delivery_tipped: false,
        date_picked: '2010-01-01',
        intake_date: '2010-01-01 12:00',
        date_delivered: '2010-01-01 12:00',
        tipping_complete_date_time: '2010-01-01 12:00',
        current: false,
        active: true
      }
    end

    def fake_rmt_delivery(overrides = {})
      RmtDelivery.new(rmt_delivery_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= RmtDeliveryInteractor.new(current_user, {}, {}, {})
    end
  end
end
