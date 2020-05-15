# frozen_string_literal: true

module EdiApp
  class LiIn < BaseEdiInService # rubocop:disable Metrics/ClassLength
    attr_accessor :attrs, :load_id, :pallet_numbers, :missing_masterfiles
    attr_reader :org_code, :po_repo, :tot_cartons, :records, :user

    def initialize(edi_in_transaction_id, file_path, logger, edi_in_result)
      super(edi_in_transaction_id, file_path, logger, edi_in_result)
      @attrs = {}
      @pallet_numbers = []
      @user = OpenStruct.new(user_name: 'Edi_Li_In')
      @missing_masterfiles = []
    end

    def call # rubocop:disable Metrics/AbcSize
      parse_voyage_edi
      parse_load_edi
      parse_pallets_edi

      missing_masterfiles_detected(missing_masterfiles.join(" \n")) unless missing_masterfiles.empty?

      res = find_load
      raise Crossbeams::InfoError, res.message unless res.success

      repo.transaction do
        res = create_load
        raise Crossbeams::InfoError, res.message unless res.success

        res = update_voyage
        raise Crossbeams::InfoError, res.message unless res.success

        res = allocate_pallets
        raise Crossbeams::InfoError, res.message unless res.success
      end
      success_response('LI processed')
    end

    private

    def allocate_pallets # rubocop:disable Metrics/AbcSize
      current_pallet_numbers = repo.select_values(:pallets, :pallet_number, load_id: load_id)
      new_pallet_numbers = pallet_numbers

      allocate_pallet_numbers   = new_pallet_numbers - current_pallet_numbers
      unallocate_pallet_numbers = current_pallet_numbers - new_pallet_numbers

      unless unallocate_pallet_numbers.empty?
        load_validator.validate_pallets(:not_shipped, unallocate_pallet_numbers)
        FinishedGoodsApp::UnallocatePallets.call(load_id, unallocate_pallet_numbers, user)
      end
      unless allocate_pallet_numbers.empty?
        load_validator.validate_allocate_list(load_id, allocate_pallet_numbers)
        FinishedGoodsApp::AllocatePallets.call(load_id, allocate_pallet_numbers, user)
      end
      success_response("Allocation applied to load: #{load_id}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_voyage
      instance = FinishedGoodsApp::LoadRepo.new.find_load_flat(load_id)
      voyage_id = instance.voyage_id
      pol_voyage_port_id = repo.get_id(:voyage_ports, port_id: attrs[:pol_port_id], voyage_id: voyage_id)
      repo.get(:voyage_ports, pol_voyage_port_id, [:atd, :etd] )
      # repo.update(:voyage_ports, pol_voyage_port_id, atd: attrs[:atd], etd: attrs[:etd])

      pod_voyage_port_id = repo.get_id(:voyage_ports, port_id: attrs[:pod_port_id], voyage_id: voyage_id)
      repo.get(:voyage_ports, pod_voyage_port_id, [:ata, :eta])
      # repo.update(:voyage_ports, pod_voyage_port_id, ata: attrs[:ata], eta: attrs[:eta])
    end

    def create_load # rubocop:disable Metrics/AbcSize
      return ok_response unless load_id.nil?

      res = FinishedGoodsApp::LoadServiceSchema.call(attrs)
      return validation_failed_response(res) unless res.messages.empty?

      load_res = FinishedGoodsApp::CreateLoad.call(res, user)
      return failed_response(load_res.message) unless load_res.success

      @load_id = load_res.instance.id
      ok_response
    end

    def find_load # rubocop:disable Metrics/AbcSize
      load_ids = repo.select_values(:pallets, :load_id, pallet_number: pallet_numbers).uniq
      return failed_response("Pallets allocated to multiple loads #{load_ids.join(', ')}") if load_ids.length > 1

      load_id = load_ids.first
      return ok_response if load_id.nil?

      instance = FinishedGoodsApp::LoadRepo.new.find_load_flat(load_id).to_h

      check = %i[exporter_party_role_id
                 consignee_party_role_id
                 final_receiver_party_role_id
                 exporter_party_role_id
                 billing_client_party_role_id
                 voyage_number]

      check.each do |k|
        return failed_response("Load mismatch on #{k}") unless instance[k] == attrs[k]
      end

      @load_id = load_id
      ok_response
    end

    def parse_voyage_edi # rubocop:disable Metrics/AbcSize
      voyage = @edi_records['load_instruction']['voyage']
      attrs[:shipper_party_role_id] = get_party_role_id(voyage['shipper'], AppConst::ROLE_SHIPPER)
      attrs[:booking_reference] = voyage['booking_reference']
      attrs[:vessel_id] = repo.get_case_insensitive_match(:vessels, vessel_code: voyage['vessel_code'])
      attrs[:vessel_type_id] = repo.get(:vessels,  attrs[:vessel_id], :vessel_type_id)
      attrs[:voyage_type_id] = repo.get(:vessel_types, attrs[:vessel_type_id], :voyage_type_id)

      args = { voyage_code: voyage['voyage_code'],
               vessel_id: attrs[:vessel_id],
               completed: false }
      attrs[:voyage_id] = repo.get_case_insensitive_match(:voyages, args)
      attrs[:voyage_number] = voyage['voyage_number']
      attrs[:year] = voyage['year']

      attrs[:pol_port_id] = repo.get_case_insensitive_match(:ports, port_code: voyage['pol']['port_code'])
      missing_masterfiles << ["pol_port_id << '#{voyage['pol']['port_code']}'"] if attrs[:pol_port_id].nil?
      attrs[:atd] = voyage['pol']['atd']
      attrs[:etd] = voyage['pol']['etd']

      attrs[:pod_port_id] = repo.get_case_insensitive_match(:ports, port_code: voyage['pod']['port_code'])
      missing_masterfiles << ["pod_port_id << '#{voyage['pod']['port_code']}'"] if attrs[:pod_port_id].nil?
      attrs[:ata] = voyage['pod']['ata']
      attrs[:eta] = voyage['pod']['eta']

      mappings = { shipper_party_role_id: 'shipper',
                   vessel_id: 'vessel_code' }
      mappings.each do |k, v|
        missing_masterfiles << ["#{k} << '#{voyage[v]}'"] if attrs[k].nil?
      end
    end

    def parse_load_edi # rubocop:disable Metrics/AbcSize
      load = @edi_records['load_instruction']['load']
      attrs[:exporter_party_role_id] = get_party_role_id(load['exporter'], AppConst::ROLE_EXPORTER)
      attrs[:billing_client_party_role_id] = get_party_role_id(load['exporter'], AppConst::ROLE_BILLING_CLIENT)
      attrs[:consignee_party_role_id] = get_party_role_id(load['consignee'], AppConst::ROLE_CONSIGNEE)
      attrs[:customer_party_role_id] = get_party_role_id(load['customer'], AppConst::ROLE_CUSTOMER)
      attrs[:final_receiver_party_role_id] = get_party_role_id(load['final_receiver'], AppConst::ROLE_FINAL_RECEIVER)
      final_destination_port = repo.get_case_insensitive_match(:ports, port_code: load['final_destination'])
      attrs[:final_destination_id] = repo.get(:ports, final_destination_port, :city_id)
      attrs[:depot_id] = repo.get_case_insensitive_match(:depots, depot_code: load['depot_code'])
      attrs[:transfer_load] = false
      attrs[:customer_order_number] = load['customer_order_number']

      mappings = { exporter_party_role_id: 'exporter',
                   billing_client_party_role_id: 'exporter',
                   consignee_party_role_id: 'consignee',
                   customer_party_role_id: 'customer',
                   final_receiver_party_role_id: 'final_receiver',
                   final_destination_id: 'final_destination',
                   depot_id: 'depot_code' }
      mappings.each do |k, v|
        missing_masterfiles << ["#{k} << '#{load[v]}'"] if attrs[k].nil?
      end
    end

    def parse_pallets_edi
      pallets = @edi_records['load_instruction']['load']['pallets'] || []
      pallets.each do |hash|
        pallet_numbers << hash['pallet_number']
      end
    end

    def get_party_role_id(party_role_name, role_name)
      role_id = repo.get_id(:roles, name: role_name)
      raise Crossbeams::InfoError, "There is no role named #{role_name}" if role_id.nil?

      org_id = repo.get_case_insensitive_match(:organizations, medium_description: party_role_name)
      repo.get_id(:party_roles, role_id: role_id, organization_id: org_id)
    end

    def load_validator
      @load_validator ||= FinishedGoodsApp::LoadValidator.new
    end

    def repo
      @repo ||= EdiInRepo.new
    end
  end
end
