# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestVesselInteractor < MiniTestWithHooks
    include VesselFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::VesselRepo)
    end

    def test_vessel
      MasterfilesApp::VesselRepo.any_instance.stubs(:find_vessel_flat).returns(fake_vessel)
      entity = interactor.send(:vessel, 1)
      assert entity.is_a?(Vessel)
    end

    def test_create_vessel
      attrs = fake_vessel.to_h.reject { |k, _| k == :id }
      res = interactor.create_vessel(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(VesselFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_vessel_fail
      attrs = fake_vessel(vessel_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_vessel(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:vessel_code]
    end

    def test_update_vessel
      id = create_vessel
      attrs = interactor.send(:repo).find_hash(:vessels, id).reject { |k, _| k == :id }
      value = attrs[:vessel_code]
      attrs[:vessel_code] = 'a_change'
      res = interactor.update_vessel(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(VesselFlat, res.instance)
      assert_equal 'a_change', res.instance.vessel_code
      refute_equal value, res.instance.vessel_code
    end

    def test_update_vessel_fail
      id = create_vessel
      attrs = interactor.send(:repo).find_hash(:vessels, id).reject { |k, _| %i[id vessel_code].include?(k) }
      res = interactor.update_vessel(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:vessel_code]
    end

    def test_delete_vessel
      id = create_vessel
      assert_count_changed(:vessels, -1) do
        res = interactor.delete_vessel(id)
        assert res.success, res.message
      end
    end

    private

    def vessel_attrs
      vessel_type_id = create_vessel_type

      {
        id: 1,
        vessel_type_id: vessel_type_id,
        vessel_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
    end

    def fake_vessel(overrides = {})
      Vessel.new(vessel_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= VesselInteractor.new(current_user, {}, {}, {})
    end
  end
end
