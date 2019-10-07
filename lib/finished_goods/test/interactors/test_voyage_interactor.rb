# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestVoyageInteractor < MiniTestWithHooks
    include VoyageFactory
    include MasterfilesApp::VesselFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(FinishedGoodsApp::VoyageRepo)
    end

    def test_voyage
      FinishedGoodsApp::VoyageRepo.any_instance.stubs(:find_voyage_flat).returns(fake_voyage)
      entity = interactor.send(:voyage, 1)
      assert entity.is_a?(Voyage)
    end

    def test_create_voyage
      attrs = fake_voyage.to_h.reject { |k, _| k == :id }
      res = interactor.create_voyage(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(VoyageFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_voyage_fail
      attrs = fake_voyage(voyage_number: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_voyage(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:voyage_number]
    end

    def test_update_voyage
      id = create_voyage
      attrs = interactor.send(:repo).find_hash(:voyages, id).reject { |k, _| k == :id }
      value = attrs[:voyage_number]
      attrs[:voyage_number] = 'a_change'
      res = interactor.update_voyage(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(VoyageFlat, res.instance)
      assert_equal 'a_change', res.instance.voyage_number
      refute_equal value, res.instance.voyage_number
    end

    def test_update_voyage_fail
      id = create_voyage
      attrs = interactor.send(:repo).find_hash(:voyages, id).reject { |k, _| %i[id vessel_id].include?(k) }
      res = interactor.update_voyage(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:vessel_id]
    end

    def test_delete_voyage
      id = create_voyage
      assert_count_changed(:voyages, -1) do
        res = interactor.delete_voyage(id)
        assert res.success, res.message
      end
    end

    private

    def voyage_attrs
      vessel_id = create_vessel
      voyage_type_id = create_voyage_type
      {
        id: 1,
        vessel_id: vessel_id,
        voyage_type_id: voyage_type_id,
        voyage_number: Faker::Lorem.unique.word,
        voyage_code: 'ABC',
        year: 1,
        completed: false,
        completed_at: '2010-01-01 12:00',
        active: true
      }
    end

    def fake_voyage(overrides = {})
      Voyage.new(voyage_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= VoyageInteractor.new(current_user, {}, {}, {})
    end
  end
end
