# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestRmtContainerMaterialTypeInteractor < MiniTestWithHooks
    include RmtContainerMaterialTypeFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::RmtContainerMaterialTypeRepo)
    end

    def test_rmt_container_material_type
      MasterfilesApp::RmtContainerMaterialTypeRepo.any_instance.stubs(:find_rmt_container_material_type).returns(fake_rmt_container_material_type)
      entity = interactor.send(:rmt_container_material_type, 1)
      assert entity.is_a?(RmtContainerMaterialType)
    end

    def test_create_rmt_container_material_type
      attrs = fake_rmt_container_material_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_rmt_container_material_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(RmtContainerMaterialType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_rmt_container_material_type_fail
      attrs = fake_rmt_container_material_type(container_material_type_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_rmt_container_material_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:container_material_type_code]
    end

    def test_update_rmt_container_material_type
      id = create_rmt_container_material_type
      attrs = interactor.send(:repo).find_hash(:rmt_container_material_types, id).reject { |k, _| k == :id }
      value = attrs[:container_material_type_code]
      attrs[:container_material_type_code] = 'a_change'
      res = interactor.update_rmt_container_material_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(RmtContainerMaterialType, res.instance)
      assert_equal 'a_change', res.instance.container_material_type_code
      refute_equal value, res.instance.container_material_type_code
    end

    def test_update_rmt_container_material_type_fail
      id = create_rmt_container_material_type
      attrs = interactor.send(:repo).find_hash(:rmt_container_material_types, id).reject { |k, _| %i[id container_material_type_code].include?(k) }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_rmt_container_material_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:container_material_type_code]
      after = interactor.send(:repo).find_hash(:rmt_container_material_types, id)
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_rmt_container_material_type
      id = create_rmt_container_material_type
      assert_count_changed(:rmt_container_material_types, -1) do
        res = interactor.delete_rmt_container_material_type(id)
        assert res.success, res.message
      end
    end

    private

    def rmt_container_material_type_attrs
      rmt_container_type_id = create_rmt_container_type

      {
        id: 1,
        rmt_container_type_id: rmt_container_type_id,
        container_material_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        tare_weight: 1.0,
        active: true,
        party_role_ids: [],
        container_material_owners: []
      }
    end

    def fake_rmt_container_material_type(overrides = {})
      RmtContainerMaterialType.new(rmt_container_material_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= RmtContainerMaterialTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
