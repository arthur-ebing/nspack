# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestInspectorInteractor < MiniTestWithHooks
    include InspectorFactory
    include MasterfilesApp::PartyFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::InspectorRepo)
    end

    def test_inspector
      MasterfilesApp::InspectorRepo.any_instance.stubs(:find_inspector_flat).returns(fake_inspector)
      entity = interactor.send(:inspector, 1)
      assert entity.is_a?(InspectorFlat)
    end

    def test_create_inspector
      attrs = fake_inspector.to_h.reject { |k, _| k == :id }
      res = interactor.create_inspector(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(InspectorFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_inspector_fail
      attrs = fake_inspector(tablet_ip_address: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_inspector(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:tablet_ip_address]
    end

    def test_update_inspector
      id = create_inspector
      attrs = interactor.send(:repo).find_inspector_flat(id).to_h.reject { |k, _| k == :id }
      value = attrs[:tablet_ip_address]
      attrs[:tablet_ip_address] = 'a_change'
      res = interactor.update_inspector(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(InspectorFlat, res.instance)
      assert_equal 'a_change', res.instance.tablet_ip_address
      refute_equal value, res.instance.tablet_ip_address
    end

    def test_update_inspector_fail
      id = create_inspector
      attrs = interactor.send(:repo).find_hash(:inspectors, id).reject { |k, _| %i[id inspector_code].include?(k) }
      res = interactor.update_inspector(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:inspector_code]
    end

    def test_delete_inspector
      id = create_inspector
      assert_count_changed(:inspectors, -1) do
        res = interactor.delete_inspector(id)
        assert res.success, res.message
      end
    end

    private

    def inspector_attrs
      party_role_id = create_party_role('P', AppConst::ROLE_INSPECTOR)
      role_id = create_role
      {
        id: 1,
        surname: Faker::Lorem.unique.word,
        first_name: Faker::Lorem.unique.word,
        title: Faker::Lorem.unique.word,
        vat_number: '1234567890',
        role_ids: [role_id],
        inspector_party_role_id: party_role_id,
        inspector: Faker::Lorem.unique.word,
        inspector_code: Faker::Lorem.unique.word,
        tablet_ip_address: Faker::Lorem.unique.word,
        tablet_port_number: 1,
        active: true
      }
    end

    def fake_inspector(overrides = {})
      InspectorFlat.new(inspector_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= InspectorInteractor.new(current_user, {}, {}, {})
    end
  end
end
