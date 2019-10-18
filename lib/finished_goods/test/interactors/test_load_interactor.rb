# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestLoadInteractor < MiniTestWithHooks
    include LoadFactory
    include MasterfilesApp::PartyFactory
    # include VoyageFactory
    # include VoyagePortFactory
    # include MasterfilesApp::PartyFactory
    # include MasterfilesApp::VesselFactory
    # include MasterfilesApp::PortFactory
    # include MasterfilesApp::DepotFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(FinishedGoodsApp::LoadRepo)
    end

    def test_load
      FinishedGoodsApp::LoadRepo.any_instance.stubs(:find_load).returns(fake_load)
      entity = interactor.send(:load, 1)
      assert entity.is_a?(Load)
    end

    def test_create_load
      attrs = fake_load.to_h.reject { |k, _| k == :id }
      res = interactor.create_load(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Load, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_load_fail
      attrs = fake_load.to_h.reject { |k, _| %i[id order_number].include?(k) }
      res = interactor.create_load(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['is missing'], res.errors[:order_number]
    end

    def test_update_load
      id = create_load
      attrs = interactor.send(:repo).find_hash(:loads, id).reject { |k, _| %i[id shipped_date].include?(k) }
      value = attrs[:order_number]
      attrs[:order_number] = 'a_change'
      res = interactor.update_load(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Load, res.instance)
      assert_equal 'a_change', res.instance.order_number
      refute_equal value, res.instance.order_number
    end

    def test_update_load_fail
      id = create_load
      attrs = interactor.send(:repo).find_hash(:loads, id).reject { |k, _| %i[id order_number].include?(k) }
      res = interactor.update_load(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:order_number]
    end

    def test_delete_load
      id = create_load
      assert_count_changed(:loads, -1) do
        res = interactor.delete_load(id)
        assert res.success, res.message
      end
    end

    private

    def load_attrs
      customer_party_role_id = create_party_role[:id]
      consignee_party_role_id = create_party_role[:id]
      billing_client_party_role_id = create_party_role[:id]
      exporter_party_role_id = create_party_role[:id]
      final_receiver_party_role_id = create_party_role[:id]
      destination_city_id = create_destination_city
      depot_id = create_depot
      pol_voyage_port_id = create_voyage_port
      pod_voyage_port_id = create_voyage_port

      {
        id: 1,
        customer_party_role_id: customer_party_role_id,
        consignee_party_role_id: consignee_party_role_id,
        billing_client_party_role_id: billing_client_party_role_id,
        exporter_party_role_id: exporter_party_role_id,
        final_receiver_party_role_id: final_receiver_party_role_id,
        final_destination_id: destination_city_id,
        depot_id: depot_id,
        pol_voyage_port_id: pol_voyage_port_id,
        pod_voyage_port_id: pod_voyage_port_id,
        order_number: Faker::Lorem.unique.word,
        edi_file_name: 'ABC',
        customer_order_number: 'ABC',
        customer_reference: 'ABC',
        exporter_certificate_code: 'ABC',
        shipped_date: '2010-01-01',
        shipped: false,
        transfer_load: false,
        active: true
      }
    end

    def fake_load(overrides = {})
      Load.new(load_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= LoadInteractor.new(current_user, {}, {}, {})
    end
  end
end
