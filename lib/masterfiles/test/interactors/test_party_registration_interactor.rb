# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestRegistrationInteractor < MiniTestWithHooks
    include PartyFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::PartyRepo)
    end

    def test_registration
      MasterfilesApp::PartyRepo.any_instance.stubs(:find_registration).returns(fake_registration)
      entity = interactor.send(:registration, 1)
      assert entity.is_a?(Registration)
    end

    def test_create_registration
      attrs = fake_registration.to_h.reject { |k, _| k == :id }
      res = interactor.create_registration(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Registration, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_registration_fail
      attrs = fake_registration(registration_type: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_registration(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:registration_type]
    end

    def test_update_registration
      id = create_registration
      attrs = interactor.send(:repo).find_hash(:registrations, id).reject { |k, _| k == :id }
      value = attrs[:registration_type]
      attrs[:registration_type] = 'a_change'
      res = interactor.update_registration(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Registration, res.instance)
      assert_equal 'a_change', res.instance.registration_type
      refute_equal value, res.instance.registration_type
    end

    def test_update_registration_fail
      id = create_registration
      attrs = interactor.send(:repo).find_hash(:registrations, id).reject { |k, _| %i[id registration_type].include?(k) }
      res = interactor.update_registration(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:registration_type]
    end

    def test_delete_registration
      id = create_registration
      assert_count_changed(:registrations, -1) do
        res = interactor.delete_registration(id)
        assert res.success, res.message
      end
    end

    private

    def registration_attrs
      party_role_id = create_party_role

      {
        id: 1,
        party_role_id: party_role_id,
        registration_type: Faker::Lorem.unique.word,
        registration_code: 'ABC',
        role_name: 'ABC',
        party_name: 'ABC'
      }
    end

    def fake_registration(overrides = {})
      Registration.new(registration_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= RegistrationInteractor.new(current_user, {}, {}, {})
    end
  end
end
