# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module DevelopmentApp
  class TestAddressTypeInteractor < MiniTestWithHooks
    include AddressTypeFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(DevelopmentApp::AddressTypeRepo)
    end

    def test_address_type
      DevelopmentApp::AddressTypeRepo.any_instance.stubs(:find_address_type).returns(fake_address_type)
      entity = interactor.send(:find_address_type, 1)
      assert entity.is_a?(AddressType)
    end

    def test_create_address_type
      attrs = fake_address_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_address_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(AddressType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_address_type_fail
      attrs = fake_address_type(address_type: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_address_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:address_type]
    end

    def test_update_address_type
      id = create_address_type
      attrs = interactor.send(:repo).find_hash(:address_types, id).reject { |k, _| k == :id }
      value = attrs[:address_type]
      attrs[:address_type] = 'a_change'
      res = interactor.update_address_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(AddressType, res.instance)
      assert_equal 'a_change', res.instance.address_type
      refute_equal value, res.instance.address_type
    end

    def test_update_address_type_fail
      id = create_address_type
      attrs = interactor.send(:repo).find_hash(:address_types, id).reject { |k, _| %i[id address_type].include?(k) }
      res = interactor.update_address_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:address_type]
    end

    def test_delete_address_type
      id = create_address_type
      assert_count_changed(:address_types, -1) do
        res = interactor.delete_address_type(id)
        assert res.success, res.message
      end
    end

    private

    def address_type_attrs
      {
        id: 1,
        address_type: Faker::Lorem.unique.word,
        active: true
      }
    end

    def fake_address_type(overrides = {})
      AddressType.new(address_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= AddressTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
