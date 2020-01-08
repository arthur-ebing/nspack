# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestLoadVoyageInteractor < MiniTestWithHooks
    include LoadFactory
    include VoyageFactory
    include VoyagePortFactory
    include LoadVoyageFactory
    include MasterfilesApp::DepotFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::VesselFactory
    include MasterfilesApp::PortFactory
    include MasterfilesApp::PortTypeFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(FinishedGoodsApp::LoadVoyageRepo)
    end

    def test_load_voyage
      FinishedGoodsApp::LoadVoyageRepo.any_instance.stubs(:find_load_voyage).returns(fake_load_voyage)
      entity = interactor.send(:load_voyage, 1)
      assert entity.is_a?(LoadVoyage)
    end

    def test_create_load_voyage
      attrs = fake_load_voyage.to_h.reject { |k, _| k == :id }
      res = interactor.create_load_voyage(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(LoadVoyage, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_load_voyage_fail
      attrs = fake_load_voyage(voyage_id: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_load_voyage(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:voyage_id]
    end

    def test_update_load_voyage
      id = create_load_voyage
      attrs = interactor.send(:repo).find_hash(:load_voyages, id).reject { |k, _| k == :id }
      value = attrs[:booking_reference]
      attrs[:booking_reference] = 'a_change'
      res = interactor.update_load_voyage(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(LoadVoyage, res.instance)
      assert_equal 'a_change', res.instance.booking_reference
      refute_equal value, res.instance.booking_reference
    end

    def test_update_load_voyage_fail
      id = create_load_voyage
      attrs = interactor.send(:repo).find_hash(:load_voyages, id).reject { |k, _| %i[id voyage_id].include?(k) }
      res = interactor.update_load_voyage(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:voyage_id]
    end

    def test_delete_load_voyage
      id = create_load_voyage
      assert_count_changed(:load_voyages, -1) do
        res = interactor.delete_load_voyage(id)
        assert res.success, res.message
      end
    end

    private

    def load_voyage_attrs
      load_id = create_load
      voyage_id = create_voyage
      shipping_line_party_role_id = create_party_role[:id]
      shipper_party_role_id = create_party_role[:id]

      {
        id: 1,
        load_id: load_id,
        voyage_id: voyage_id,
        shipping_line_party_role_id: shipping_line_party_role_id,
        shipper_party_role_id: shipper_party_role_id,
        booking_reference: Faker::Lorem.unique.word,
        memo_pad: 'ABC',
        active: true
      }
    end

    def fake_load_voyage(overrides = {})
      LoadVoyage.new(load_voyage_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= LoadVoyageInteractor.new(current_user, {}, {}, {})
    end
  end
end
