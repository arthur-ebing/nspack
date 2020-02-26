# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestDepotInteractor < MiniTestWithHooks
    include DepotFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::DepotRepo)
    end

    def test_depot
      MasterfilesApp::DepotRepo.any_instance.stubs(:find_depot_flat).returns(fake_depot)
      entity = interactor.send(:depot, 1)
      assert entity.is_a?(Depot)
    end

    def test_create_depot
      attrs = fake_depot.to_h.reject { |k, _| k == :id }
      res = interactor.create_depot(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(DepotFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_depot_fail
      attrs = fake_depot(depot_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_depot(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:depot_code]
    end

    def test_update_depot
      id = create_depot
      attrs = interactor.send(:repo).find_hash(:depots, id).reject { |k, _| k == :id }
      value = attrs[:depot_code]
      attrs[:depot_code] = 'a_change'
      res = interactor.update_depot(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(DepotFlat, res.instance)
      assert_equal 'a_change', res.instance.depot_code
      refute_equal value, res.instance.depot_code
    end

    def test_update_depot_fail
      id = create_depot
      attrs = interactor.send(:repo).find_hash(:depots, id).reject { |k, _| %i[id depot_code].include?(k) }
      res = interactor.update_depot(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:depot_code]
    end

    def test_delete_depot
      id = create_depot
      assert_count_changed(:depots, -1) do
        res = interactor.delete_depot(id)
        assert res.success, res.message
      end
    end

    private

    def depot_attrs
      destination_city_id = create_destination_city

      {
        id: 1,
        city_id: destination_city_id,
        depot_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
    end

    def fake_depot(overrides = {})
      Depot.new(depot_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= DepotInteractor.new(current_user, {}, {}, {})
    end
  end
end
