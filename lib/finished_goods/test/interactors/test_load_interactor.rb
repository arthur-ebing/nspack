# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestLoadInteractor < MiniTestWithHooks
    include LoadFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::DepotFactory
    include MasterfilesApp::VesselFactory
    include MasterfilesApp::PortFactory
    include VoyageFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(FinishedGoodsApp::LoadRepo)
    end

    def test_load
      FinishedGoodsApp::LoadRepo.any_instance.stubs(:find_load).returns(fake_load)
      entity = interactor.send(:load_entity, 1)
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
      attrs = fake_load.to_h.reject { |k, _| %i[id depot_id].include?(k) }
      res = interactor.create_load(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['is missing'], res.errors[:depot_id]
    end

    def test_update_load
      id = create_load
      attrs = interactor.send(:repo).find_load(id).to_h.reject { |k, _| %i[id shipped_at].include?(k) }
      attrs[:load_id] = id
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

    def load_attrs
      repo = BaseRepo.new
      create_port_type(port_type_code: AppConst::PORT_TYPE_POL) if repo.get_id(:port_types, port_type_code: AppConst::PORT_TYPE_POL).nil?
      create_port_type(port_type_code: AppConst::PORT_TYPE_POD) if repo.get_id(:port_types, port_type_code: AppConst::PORT_TYPE_POD).nil?

      customer_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_INSPECTION_BILLING)
      consignee_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_CONSIGNEE)
      billing_client_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_BILLING_CLIENT)
      exporter_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_EXPORTER)
      final_receiver_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_FINAL_RECEIVER)
      shipping_line_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_SHIPPING_LINE)
      shipper_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_SHIPPER)
      destination_city_id = create_destination_city
      depot_id = create_depot
      pol_voyage_port_id = create_voyage_port
      pod_voyage_port_id = create_voyage_port
      voyage_id = create_voyage
      pol_port_id = create_port
      pod_port_id = create_port
      voyage_type_id = create_voyage_type
      vessel_id = create_vessel
      {
        id: 1,
        load_id: 1,
        rmt_load: false,
        truck_must_be_weighed: false,
        customer_party_role_id: customer_party_role_id,
        customer: 'ABC',
        consignee_party_role_id: consignee_party_role_id,
        consignee: 'ABC',
        billing_client_party_role_id: billing_client_party_role_id,
        billing_client: 'ABC',
        exporter_party_role_id: exporter_party_role_id,
        exporter: 'ABC',
        final_receiver_party_role_id: final_receiver_party_role_id,
        final_receiver: 'ABC',
        final_destination_id: destination_city_id,
        destination_city: 'ABC',
        destination_country: 'ABC',
        iso_country_code: 'ZA',
        destination_region: 'ABC',
        depot_id: depot_id,
        depot_code: 'ABC',
        pol_voyage_port_id: pol_voyage_port_id,
        pod_voyage_port_id: pod_voyage_port_id,
        order_number: Faker::Lorem.unique.word,
        edi_file_name: 'ABC',
        order_id: nil,
        customer_order_number: 'ABC',
        customer_reference: 'ABC',
        exporter_certificate_code: 'ABC',
        shipped_at: '2010-01-01',
        shipped: false,
        allocated_at: '2010-01-01',
        allocated: false,
        transfer_load: false,
        loaded: false,
        requires_temp_tail: false,
        edi: false,
        active: true,
        status: Faker::Lorem.word,

        # voyage
        voyage_type_id: voyage_type_id,
        vessel_id: vessel_id,
        vessel_code: 'ABC',
        voyage_id: voyage_id,
        voyage_number: Faker::Lorem.word,
        voyage_code: Faker::Lorem.unique.word,
        year: 2019,
        pol_port_id: pol_port_id,
        pol_port_code: 'ABC',
        eta: '2010-01-01',
        ata: '2010-01-01',
        pod_port_id: pod_port_id,
        pod_port_code: 'ABC',
        etd: '2010-01-01',
        atd: '2010-01-01',

        # load_voyage
        load_voyage_id: 1,
        shipping_line_party_role_id: shipping_line_party_role_id,
        shipping_line: 'ABC',
        shipper_party_role_id: shipper_party_role_id,
        shipper: 'ABC',
        booking_reference: Faker::Lorem.word,
        memo_pad: Faker::Lorem.word,

        # load_vehicle
        vehicle: true,
        load_vehicle_id: 1,
        vehicle_number: Faker::Lorem.word,

        # load_container
        container: true,
        load_container_id: 1,
        verified_gross_weight: 0.1,
        temperature_code: 'ABC',
        container_code: Faker::Lorem.word,

        # pallets
        temp_tail: '123',
        temp_tail_pallet_number: '123',
        pallet_count: 1,
        nett_weight: 1.0,
        packed_tm_group_id: nil,
        marketing_org_party_role_id: nil,
        target_customer_party_role_id: nil,

        # addendum
        addendum: true,
        location_of_issue: '123'
      }
    end

    def fake_load(overrides = {})
      Load.new(load_attrs.merge(overrides))
    end

    private

    def interactor
      @interactor ||= LoadInteractor.new(current_user, {}, {}, {})
    end
  end
end
