# frozen_string_literal: true

module FinishedGoodsApp
  class EdiCreateLoad < BaseService
    attr_accessor :attrs, :payload, :load_id, :pallet_numbers
    attr_reader :repo, :user

    def initialize(payload = {})
      @payload = payload
      @attrs = {}
      @pallet_numbers = []
      @repo = LoadRepo.new
      @user = OpenStruct.new(user_name: 'EDI_Create_Load')
    end

    def call
      parse_voyage_edi
      parse_load_edi
      parse_pallets_edi

      res = find_or_create_load
      return res unless res.success

      allocate_pallets
    end

    private

    def allocate_pallets # rubocop:disable Metrics/AbcSize
      res = validate_allocate_list(load_id, pallet_numbers)
      return validation_failed_response(messages: { pallets: [res.message] }) unless res.success

      current_allocation = repo.select_values(:pallets, :id, load_id: load_id)
      new_allocation = repo.select_values(:pallets, :id, pallet_number: pallet_numbers)

      allocate = new_allocation - current_allocation
      unallocate = current_allocation - new_allocation

      unless unallocate.empty?
        not_shipped = repo.select_values(:pallets, :pallet_number, id: unallocate, shipped: false)
        return validation_failed_response(messages: { pallets: ["Pallets: #{not_shipped} not shipped"] }) unless not_shipped.empty?

        repo.unallocate_pallets(unallocate, user.user_name)
      end

      repo.allocate_pallets(load_id, allocate, user.user_name)

      success_response("Allocation applied to load: #{load_id}")
    end

    def find_or_create_load # rubocop:disable Metrics/AbcSize
      res = LoadServiceSchema.call(attrs)
      return validation_failed_response(res) unless res.messages.empty?

      @load_id = repo.get_id(:loads, customer_order_number: res.to_h[:customer_order_number])
      if load_id.nil?
        load_res = FinishedGoodsApp::CreateLoad.call(res, user)
        raise Crossbeams::InfoError, load_res.message unless load_res.success

        @load_id = load_res.instance.id
      end

      ok_response
    end

    def parse_voyage_edi # rubocop:disable Metrics/AbcSize
      voyage = payload['load_instruction']['voyage']

      attrs[:shipper_party_role_id] = get_party_role_id(voyage['shipper'], AppConst::ROLE_SHIPPER)
      attrs[:booking_reference] = voyage['booking_reference']

      attrs[:vessel_id], attrs[:vessel_type_id] = repo.get_value(:vessels, %i[id vessel_type_id], vessel_code: voyage['vessel_code'])
      attrs[:voyage_type_id] = repo.get_id(:vessel_types, id: attrs[:vessel_type_id])

      args = { voyage_code: voyage['voyage_code'],
               voyage_number: voyage['voyage_number'],
               year: voyage['years'],
               vessel_id: attrs[:vessel_id],
               completed: false }
      attrs[:voyage_id] = repo.get_id(:voyages, args)
      attrs[:voyage_number] = voyage['voyage_number']
      attrs[:year] = voyage['year']
      attrs[:pol_port_id] = repo.get_id(:ports, port_code: voyage['pol']['port_code'])
      attrs[:pod_port_id] = repo.get_id(:ports, port_code: voyage['pod']['port_code'])
    end

    def parse_load_edi # rubocop:disable Metrics/AbcSize
      load = payload['load_instruction']['load']

      attrs[:exporter_party_role_id] = get_party_role_id(load['exporter'], AppConst::ROLE_EXPORTER)
      attrs[:billing_client_party_role_id] = attrs[:exporter_party_role_id]

      attrs[:consignee_party_role_id] = get_party_role_id(load['consignee'], AppConst::ROLE_CONSIGNEE)
      attrs[:customer_party_role_id] = get_party_role_id(load['customer'], AppConst::ROLE_CUSTOMER)
      attrs[:final_receiver_party_role_id] = get_party_role_id(load['final_receiver'], AppConst::ROLE_FINAL_RECEIVER)
      attrs[:final_destination_id] = repo.get_value(:ports, :city_id, port_code: load['final_destination'])

      attrs[:depot_id] = repo.get_id(:depots, depot_code: load['depot_code'])
      attrs[:transfer_load] = false
      attrs[:customer_order_number] = load['customer_order_number']
    end

    def parse_pallets_edi
      pallets = payload['load_instruction']['load']['pallets'] || []
      pallets.each do |hash|
        pallet_numbers << hash['pallet_number']
      end
    end

    def validate_allocate_list(load_id, pallet_numbers)
      check_pallets(:not_on_load, pallet_numbers, load_id)
      check_pallets(:not_shipped, pallet_numbers)
      check_pallets(:in_stock, pallet_numbers)
      check_pallets(:not_failed_otmc, pallet_numbers)

      success_response('ok')
    rescue Crossbeams::TaskNotPermittedError => e
      failed_response(e.message)
    end

    def check_pallets(check, pallet_numbers, load_id = nil)
      MesscadaApp::TaskPermissionCheck::Pallets.call(check, pallet_numbers, load_id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def get_party_role_id(party_role_name, role_name)
      MasterfilesApp::PartyRepo.new.find_party_role_from_party_name_for_role(party_role_name, role_name)
    end
  end
end
