# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestVoyageTypeInteractor < MiniTestWithHooks
    include VoyageTypeFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::VoyageTypeRepo)
    end

    def test_voyage_type
      MasterfilesApp::VoyageTypeRepo.any_instance.stubs(:find_voyage_type).returns(fake_voyage_type)
      entity = interactor.send(:voyage_type, 1)
      assert entity.is_a?(VoyageType)
    end

    def test_create_voyage_type
      attrs = fake_voyage_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_voyage_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(VoyageType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_voyage_type_fail
      attrs = fake_voyage_type(voyage_type_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_voyage_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:voyage_type_code]
    end

    def test_update_voyage_type
      id = create_voyage_type
      attrs = interactor.send(:repo).find_hash(:voyage_types, id).reject { |k, _| k == :id }
      value = attrs[:voyage_type_code]
      attrs[:voyage_type_code] = 'a_change'
      res = interactor.update_voyage_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(VoyageType, res.instance)
      assert_equal 'a_change', res.instance.voyage_type_code
      refute_equal value, res.instance.voyage_type_code
    end

    def test_update_voyage_type_fail
      id = create_voyage_type
      attrs = interactor.send(:repo).find_hash(:voyage_types, id).reject { |k, _| %i[id voyage_type_code].include?(k) }
      res = interactor.update_voyage_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:voyage_type_code]
    end

    def test_delete_voyage_type
      id = create_voyage_type
      assert_count_changed(:voyage_types, -1) do
        res = interactor.delete_voyage_type(id)
        assert res.success, res.message
      end
    end

    private

    def voyage_type_attrs
      {
        id: 1,
        voyage_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
    end

    def fake_voyage_type(overrides = {})
      VoyageType.new(voyage_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= VoyageTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
