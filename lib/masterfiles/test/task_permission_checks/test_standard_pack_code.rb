# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestStandardPackCodePermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        standard_pack_code: Faker::Lorem.unique.word,
        description: 'ABC',
        std_pack_label_code: 'ABC',
        material_mass: 1.0,
        plant_resource_button_indicator: 'ABC',
        basic_pack_code_id: 1,
        use_size_ref_for_edi: false,
        palletizer_incentive_rate: 1.0,
        bin: false,
        rmt_container_type_id: nil,
        rmt_container_material_type_id: nil,
        active: true

      }
      MasterfilesApp::StandardPackCode.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::StandardPackCode.call(:create)
      assert res.success, 'Should always be able to create a standard_pack_code'
    end

    def test_edit
      MasterfilesApp::FruitSizeRepo.any_instance.stubs(:find_standard_pack_code).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::StandardPackCode.call(:edit, 1)
      assert res.success, 'Should be able to edit a standard_pack_code'
    end

    def test_delete
      MasterfilesApp::FruitSizeRepo.any_instance.stubs(:find_standard_pack_code).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::StandardPackCode.call(:delete, 1)
      assert res.success, 'Should be able to delete a standard_pack_code'
    end
  end
end
