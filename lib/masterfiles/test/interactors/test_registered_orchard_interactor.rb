# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestRegisteredOrchardInteractor < MiniTestWithHooks
    include FarmFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FarmRepo)
    end

    def test_registered_orchard
      MasterfilesApp::FarmRepo.any_instance.stubs(:find_registered_orchard).returns(fake_registered_orchard)
      entity = interactor.send(:registered_orchard, 1)
      assert entity.is_a?(RegisteredOrchard)
    end

    def test_create_registered_orchard
      attrs = fake_registered_orchard.to_h.reject { |k, _| k == :id }
      res = interactor.create_registered_orchard(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(RegisteredOrchard, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_registered_orchard_fail
      attrs = fake_registered_orchard(orchard_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_registered_orchard(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:orchard_code]
    end

    def test_update_registered_orchard
      id = create_registered_orchard
      attrs = interactor.send(:repo).find_hash(:registered_orchards, id).reject { |k, _| k == :id }
      value = attrs[:orchard_code]
      attrs[:orchard_code] = 'a_change'
      res = interactor.update_registered_orchard(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(RegisteredOrchard, res.instance)
      assert_equal 'a_change', res.instance.orchard_code
      refute_equal value, res.instance.orchard_code
    end

    def test_update_registered_orchard_fail
      id = create_registered_orchard
      attrs = interactor.send(:repo).find_hash(:registered_orchards, id).reject { |k, _| %i[id orchard_code].include?(k) }
      res = interactor.update_registered_orchard(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:orchard_code]
    end

    def test_delete_registered_orchard
      id = create_registered_orchard
      assert_count_changed(:registered_orchards, -1) do
        res = interactor.delete_registered_orchard(id)
        assert res.success, res.message
      end
    end

    private

    def registered_orchard_attrs
      {
        id: 1,
        orchard_code: Faker::Lorem.unique.word,
        cultivar_code: 'ABC',
        puc_code: 'ABC',
        description: 'ABC',
        marketing_orchard: false,
        active: true
      }
    end

    def fake_registered_orchard(overrides = {})
      RegisteredOrchard.new(registered_orchard_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= RegisteredOrchardInteractor.new(current_user, {}, {}, {})
    end
  end
end
