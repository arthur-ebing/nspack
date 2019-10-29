# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestCargoTemperatureInteractor < MiniTestWithHooks
    include CargoTemperatureFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::CargoTemperatureRepo)
    end

    def test_cargo_temperature
      MasterfilesApp::CargoTemperatureRepo.any_instance.stubs(:find_cargo_temperature).returns(fake_cargo_temperature)
      entity = interactor.send(:cargo_temperature, 1)
      assert entity.is_a?(CargoTemperature)
    end

    def test_create_cargo_temperature
      attrs = fake_cargo_temperature.to_h.reject { |k, _| k == :id }
      res = interactor.create_cargo_temperature(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(CargoTemperature, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_cargo_temperature_fail
      attrs = fake_cargo_temperature(temperature_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_cargo_temperature(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:temperature_code]
    end

    def test_update_cargo_temperature
      id = create_cargo_temperature
      attrs = interactor.send(:repo).find_hash(:cargo_temperatures, id).reject { |k, _| k == :id }
      value = attrs[:temperature_code]
      attrs[:temperature_code] = 'a_change'
      res = interactor.update_cargo_temperature(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(CargoTemperature, res.instance)
      assert_equal 'a_change', res.instance.temperature_code
      refute_equal value, res.instance.temperature_code
    end

    def test_update_cargo_temperature_fail
      id = create_cargo_temperature
      attrs = interactor.send(:repo).find_hash(:cargo_temperatures, id).reject { |k, _| %i[id temperature_code].include?(k) }
      res = interactor.update_cargo_temperature(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:temperature_code]
    end

    def test_delete_cargo_temperature
      id = create_cargo_temperature
      assert_count_changed(:cargo_temperatures, -1) do
        res = interactor.delete_cargo_temperature(id)
        assert res.success, res.message
      end
    end

    private

    def cargo_temperature_attrs
      {
        id: 1,
        temperature_code: Faker::Lorem.unique.word,
        description: 'ABC',
        set_point_temperature: 1.0,
        load_temperature: 1.0,
        active: true
      }
    end

    def fake_cargo_temperature(overrides = {})
      CargoTemperature.new(cargo_temperature_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= CargoTemperatureInteractor.new(current_user, {}, {}, {})
    end
  end
end
