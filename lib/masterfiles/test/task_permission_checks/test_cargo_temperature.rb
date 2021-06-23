# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestCargoTemperaturePermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        temperature_code: Faker::Lorem.unique.word,
        description: 'ABC',
        set_point_temperature: 1.0,
        load_temperature: 1.0,
        active: true
      }
      MasterfilesApp::CargoTemperature.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::CargoTemperature.call(:create)
      assert res.success, 'Should always be able to create a cargo_temperature'
    end

    def test_edit
      MasterfilesApp::CargoTemperatureRepo.any_instance.stubs(:find_cargo_temperature).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::CargoTemperature.call(:edit, 1)
      assert res.success, 'Should be able to edit a cargo_temperature'
    end

    def test_delete
      MasterfilesApp::CargoTemperatureRepo.any_instance.stubs(:find_cargo_temperature).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::CargoTemperature.call(:delete, 1)
      assert res.success, 'Should be able to delete a cargo_temperature'
    end
  end
end
