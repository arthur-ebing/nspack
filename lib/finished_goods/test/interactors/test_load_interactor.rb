# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestLoadInteractor < MiniTestWithHooks
    include LoadFactory
    include MasterfilesApp::PartyFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(FinishedGoodsApp::LoadRepo)
    end

    def test_load
      FinishedGoodsApp::LoadRepo.any_instance.stubs(:find_load_flat).returns(fake_load)
      entity = interactor.send(:load_entity, 1)
      assert entity.is_a?(LoadFlat)
    end

    def test_create_load
      attrs = fake_load.to_h.reject { |k, _| k == :id }
      res = interactor.create_load(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(LoadFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_load_fail
      attrs = fake_load.to_h.reject { |k, _| %i[id depot_id].include?(k) }
      res = interactor.create_load(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['is missing'], res.errors[:depot_id]
    end

    def test_update_load
      id = create_load
      attrs = interactor.send(:repo).find_load_flat(id).to_h.reject { |k, _| %i[id shipped_at].include?(k) }
      value = attrs[:order_number]
      attrs[:order_number] = 'a_change'
      res = interactor.update_load(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(LoadFlat, res.instance)
      assert_equal 'a_change', res.instance.order_number
      refute_equal value, res.instance.order_number
    end

    def test_update_load_fail
      id = create_load
      attrs = interactor.send(:repo).find_hash(:loads, id).reject { |k, _| %i[id depot_id].include?(k) }
      res = interactor.update_load(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:depot_id]
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
      party_role_id = create_party_role[:id]
      destination_city_id = create_destination_city
      depot_id = create_depot
      voyage_port_id = create_voyage_port
      port_id = create_port
      voyage_type_id = create_voyage_type
      vessel_id = create_vessel
      {
        id: 1,
        customer_party_role_id: party_role_id,
        consignee_party_role_id: party_role_id,
        billing_client_party_role_id: party_role_id,
        exporter_party_role_id: party_role_id,
        final_receiver_party_role_id: party_role_id,
        final_destination_id: destination_city_id,
        depot_id: depot_id,
        pol_voyage_port_id: voyage_port_id,
        pod_voyage_port_id: voyage_port_id,
        order_number: Faker::Lorem.unique.word,
        edi_file_name: 'ABC',
        customer_order_number: 'ABC',
        customer_reference: 'ABC',
        exporter_certificate_code: 'ABC',
        shipped_at: '2010-01-01',
        shipped: false,
        allocated_at: '2010-01-01',
        allocated: false,
        transfer_load: false,
        active: true,
        voyage_type_id: voyage_type_id,
        vessel_id: vessel_id,
        voyage_number: Faker::Number.number(4),
        voyage_code: Faker::Lorem.unique.word,
        year: 2019,
        pol_port_id: port_id,
        pod_port_id: port_id,
        shipping_line_party_role_id: party_role_id,
        shipper_party_role_id: party_role_id,
        booking_reference: Faker::Lorem.word,
        memo_pad: Faker::Lorem.word,
        vehicle_number: Faker::Lorem.word,
        container_code: Faker::Lorem.word
      }
    end

    def fake_load(overrides = {})
      LoadFlat.new(load_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= LoadInteractor.new(current_user, {}, {}, {})
    end
  end
end
