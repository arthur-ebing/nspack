# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestCargoTemperaturePermission < Minitest::Test
    include Crossbeams::Responses
    include CargoTemperatureFactory

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

      # MasterfilesApp::CargoTemperatureRepo.any_instance.stubs(:find_cargo_temperature).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::CargoTemperature.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed cargo_temperature'
    end

    def test_delete
      MasterfilesApp::CargoTemperatureRepo.any_instance.stubs(:find_cargo_temperature).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::CargoTemperature.call(:delete, 1)
      assert res.success, 'Should be able to delete a cargo_temperature'

      # MasterfilesApp::CargoTemperatureRepo.any_instance.stubs(:find_cargo_temperature).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::CargoTemperature.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed cargo_temperature'
    end

    # def test_complete
    #   MasterfilesApp::CargoTemperatureRepo.any_instance.stubs(:find_cargo_temperature).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::CargoTemperature.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a cargo_temperature'

    #   MasterfilesApp::CargoTemperatureRepo.any_instance.stubs(:find_cargo_temperature).returns(entity(completed: true))
    #   res = MasterfilesApp::TaskPermissionCheck::CargoTemperature.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed cargo_temperature'
    # end

    # def test_approve
    #   MasterfilesApp::CargoTemperatureRepo.any_instance.stubs(:find_cargo_temperature).returns(entity(completed: true, approved: false))
    #   res = MasterfilesApp::TaskPermissionCheck::CargoTemperature.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed cargo_temperature'

    #   MasterfilesApp::CargoTemperatureRepo.any_instance.stubs(:find_cargo_temperature).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::CargoTemperature.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed cargo_temperature'

    #   MasterfilesApp::CargoTemperatureRepo.any_instance.stubs(:find_cargo_temperature).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::CargoTemperature.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved cargo_temperature'
    # end

    # def test_reopen
    #   MasterfilesApp::CargoTemperatureRepo.any_instance.stubs(:find_cargo_temperature).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::CargoTemperature.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a cargo_temperature that has not been approved'

    #   MasterfilesApp::CargoTemperatureRepo.any_instance.stubs(:find_cargo_temperature).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::CargoTemperature.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved cargo_temperature'
    # end
  end
end
