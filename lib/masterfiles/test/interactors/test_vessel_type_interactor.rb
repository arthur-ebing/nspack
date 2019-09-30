# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestVesselTypeInteractor < MiniTestWithHooks
    include VesselTypeFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::VesselTypeRepo)
    end

    def test_vessel_type
      MasterfilesApp::VesselTypeRepo.any_instance.stubs(:find_vessel_type_flat).returns(fake_vessel_type)
      entity = interactor.send(:vessel_type, 1)
      assert entity.is_a?(VesselType)
    end

    def test_create_vessel_type
      attrs = fake_vessel_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_vessel_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(VesselTypeFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_vessel_type_fail
      attrs = fake_vessel_type(vessel_type_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_vessel_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:vessel_type_code]
    end

    def test_update_vessel_type
      id = create_vessel_type
      attrs = interactor.send(:repo).find_hash(:vessel_types, id).reject { |k, _| k == :id }
      value = attrs[:vessel_type_code]
      attrs[:vessel_type_code] = 'a_change'
      res = interactor.update_vessel_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(VesselTypeFlat, res.instance)
      assert_equal 'a_change', res.instance.vessel_type_code
      refute_equal value, res.instance.vessel_type_code
    end

    def test_update_vessel_type_fail
      id = create_vessel_type
      attrs = interactor.send(:repo).find_hash(:vessel_types, id).reject { |k, _| %i[id vessel_type_code].include?(k) }
      res = interactor.update_vessel_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:vessel_type_code]
    end

    def test_delete_vessel_type
      id = create_vessel_type
      assert_count_changed(:vessel_types, -1) do
        res = interactor.delete_vessel_type(id)
        assert res.success, res.message
      end
    end

    private

    def vessel_type_attrs
      voyage_type_id = create_voyage_type

      {
        id: 1,
        voyage_type_id: voyage_type_id,
        vessel_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
    end

    def fake_vessel_type(overrides = {})
      VesselType.new(vessel_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= VesselTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
