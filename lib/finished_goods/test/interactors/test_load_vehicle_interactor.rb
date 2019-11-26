# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestLoadVehicleInteractor < MiniTestWithHooks
    include LoadVehicleFactory
    include LoadFactory
    include MasterfilesApp::PartyFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(FinishedGoodsApp::LoadVehicleRepo)
    end

    def test_load_vehicle
      FinishedGoodsApp::LoadVehicleRepo.any_instance.stubs(:find_load_vehicle).returns(fake_load_vehicle)
      entity = interactor.send(:load_vehicle, 1)
      assert entity.is_a?(LoadVehicle)
    end

    def test_create_load_vehicle
      attrs = fake_load_vehicle.to_h.reject { |k, _| k == :id }
      res = interactor.create_load_vehicle(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(LoadVehicle, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_load_vehicle_fail
      attrs = fake_load_vehicle(vehicle_number: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_load_vehicle(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:vehicle_number]
    end

    def test_update_load_vehicle
      id = create_load_vehicle
      attrs = interactor.send(:repo).find_hash(:load_vehicles, id).reject { |k, _| k == :id }
      value = attrs[:vehicle_number]
      attrs[:vehicle_number] = 'a_change'
      res = interactor.update_load_vehicle(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(LoadVehicle, res.instance)
      assert_equal 'a_change', res.instance.vehicle_number
      refute_equal value, res.instance.vehicle_number
    end

    def test_update_load_vehicle_fail
      id = create_load_vehicle
      attrs = interactor.send(:repo).find_hash(:load_vehicles, id).reject { |k, _| %i[id vehicle_number].include?(k) }
      res = interactor.update_load_vehicle(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:vehicle_number]
    end

    def test_delete_load_vehicle
      id = create_load_vehicle
      assert_count_changed(:load_vehicles, -1) do
        res = interactor.delete_load_vehicle(id)
        assert res.success, res.message
      end
    end

    private

    def load_vehicle_attrs
      load_id = create_load
      vehicle_type_id = create_vehicle_type
      party_role_id = create_party_role[:id]

      {
        id: 1,
        load_id: load_id,
        vehicle_type_id: vehicle_type_id,
        haulier_party_role_id: party_role_id,
        vehicle_number: Faker::Lorem.unique.word,
        vehicle_weight_out: 1.0,
        dispatch_consignment_note_number: 'ABC',
        driver_name: Faker::Lorem.word,
        driver_cell_number: Faker::Lorem.word,
        active: true
      }
    end

    def fake_load_vehicle(overrides = {})
      LoadVehicle.new(load_vehicle_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= LoadVehicleInteractor.new(current_user, {}, {}, {})
    end
  end
end
