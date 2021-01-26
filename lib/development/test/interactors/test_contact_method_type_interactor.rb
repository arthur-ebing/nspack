# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module DevelopmentApp
  class TestContactMethodTypeInteractor < MiniTestWithHooks
    include ContactMethodTypeFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(DevelopmentApp::ContactMethodTypeRepo)
    end

    def test_contact_method_type
      DevelopmentApp::ContactMethodTypeRepo.any_instance.stubs(:find_contact_method_type).returns(fake_contact_method_type)
      entity = interactor.send(:find_contact_method_type, 1)
      assert entity.is_a?(ContactMethodType)
    end

    def test_create_contact_method_type
      attrs = fake_contact_method_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_contact_method_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ContactMethodType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_contact_method_type_fail
      attrs = fake_contact_method_type(contact_method_type: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_contact_method_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:contact_method_type]
    end

    def test_update_contact_method_type
      id = create_contact_method_type
      attrs = interactor.send(:repo).find_hash(:contact_method_types, id).reject { |k, _| k == :id }
      value = attrs[:contact_method_type]
      attrs[:contact_method_type] = 'a_change'
      res = interactor.update_contact_method_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ContactMethodType, res.instance)
      assert_equal 'a_change', res.instance.contact_method_type
      refute_equal value, res.instance.contact_method_type
    end

    def test_update_contact_method_type_fail
      id = create_contact_method_type
      attrs = interactor.send(:repo).find_hash(:contact_method_types, id).reject { |k, _| %i[id contact_method_type].include?(k) }
      res = interactor.update_contact_method_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:contact_method_type]
    end

    def test_delete_contact_method_type
      id = create_contact_method_type
      assert_count_changed(:contact_method_types, -1) do
        res = interactor.delete_contact_method_type(id)
        assert res.success, res.message
      end
    end

    private

    def contact_method_type_attrs
      {
        id: 1,
        contact_method_type: Faker::Lorem.unique.word,
        active: true
      }
    end

    def fake_contact_method_type(overrides = {})
      ContactMethodType.new(contact_method_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= ContactMethodTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
