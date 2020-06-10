# frozen_string_literal: true

module EdiApp
  class LiIn < BaseEdiInService # rubocop:disable Metrics/ClassLength
    attr_accessor :attrs, :load_id, :pallet_numbers, :missing_masterfiles, :match_data
    attr_reader :org_code, :po_repo, :tot_cartons, :records, :user, :repo, :load_repo

    def initialize(edi_in_transaction_id, file_path, logger, edi_in_result)
      super(edi_in_transaction_id, file_path, logger, edi_in_result)
      @attrs = {}
      @pallet_numbers = []
      @user = OpenStruct.new(user_name: 'System')
      @missing_masterfiles = []
      @repo = EdiApp::EdiInRepo.new
      @load_repo = FinishedGoodsApp::LoadRepo.new
    end

    def call # rubocop:disable Metrics/AbcSize
      parse_voyage_edi
      parse_load_edi
      parse_pallets_edi

      match_data_on(match_data)

      unless missing_masterfiles.empty?
        notes = missing_masterfiles.join(" \n")
        missing_masterfiles_detected(notes)
        return failed_response('Missing masterfiles', notes)
      end

      business_validation_passed

      repo.transaction do
        find_load

        update_voyage

        allocate_pallets
      end
      log('LI IN processed')

      success_response('ok')
    rescue Crossbeams::InfoError => e
      discrepancies_detected(e.message)
      failed_response(e.message)
    end

    private

    def allocate_pallets # rubocop:disable Metrics/AbcSize
      current_pallet_numbers = repo.select_values(:pallets, :pallet_number, load_id: load_id)
      new_pallet_numbers = pallet_numbers

      allocate_pallet_numbers   = new_pallet_numbers - current_pallet_numbers
      unallocate_pallet_numbers = current_pallet_numbers - new_pallet_numbers

      unless unallocate_pallet_numbers.empty?
        check_pallets(:not_shipped, unallocate_pallet_numbers)
        unallocate_ids = repo.select_values(:pallets, :id, pallets_number: unallocate_pallet_numbers)
        load_repo.unallocate_pallets(unallocate_ids, @user)
      end

      unless allocate_pallet_numbers.empty?
        check_pallets(:allocate, pallet_numbers, load_id)
        allocate_ids = repo.select_values(:pallets, :id, pallets_number: allocate_pallet_numbers)
        load_repo.allocate_pallets(load_id, allocate_ids, @user)
      end
      success_response("Allocation applied to load: #{load_id}")
    end

    def update_voyage
      # instance = load_repo.find_load_flat(load_id)
      # voyage_id = instance.voyage_id
      # pol_voyage_port_id = repo.get_id(:voyage_ports, port_id: attrs[:pol_port_id], voyage_id: voyage_id)
      # repo.get(:voyage_ports, pol_voyage_port_id, [:atd, :etd] )
      # # repo.update(:voyage_ports, pol_voyage_port_id, atd: attrs[:atd], etd: attrs[:etd])
      #
      # pod_voyage_port_id = repo.get_id(:voyage_ports, port_id: attrs[:pod_port_id], voyage_id: voyage_id)
      # repo.get(:voyage_ports, pod_voyage_port_id, [:ata, :eta])
      # # repo.update(:voyage_ports, pod_voyage_port_id, ata: attrs[:ata], eta: attrs[:eta])
    end

    def create_load
      res = FinishedGoodsApp::LoadServiceSchema.call(attrs)
      raise Crossbeams::InfoError, res.messages unless res.messages.empty?

      load_res = FinishedGoodsApp::CreateLoad.call(res, user)
      raise Crossbeams::InfoError, load_res.message unless load_res.success

      @load_id = load_res.instance.id
    end

    def find_load # rubocop:disable Metrics/AbcSize
      # find load by pallet_numbers
      load_ids = repo.select_values(:pallets, :load_id, pallet_number: pallet_numbers).uniq
      raise Crossbeams::InfoError, "Pallets allocated to multiple loads #{load_ids.join(', ')}"  if load_ids.length > 1

      @load_id = load_ids.first
      return create_load if load_id.nil?

      instance = load_repo.find_load_flat(load_id).to_h
      check = %i[exporter_party_role_id
                 consignee_party_role_id
                 final_receiver_party_role_id
                 exporter_party_role_id
                 billing_client_party_role_id
                 voyage_number]
      check.each do |k|
        raise Crossbeams::InfoError, "Load mismatch on #{k}" unless instance[k] == attrs[k]
      end
      return unless load_id.nil?

      create_load
    end

    def parse_voyage_edi # rubocop:disable Metrics/AbcSize
      voyage = @edi_records['load_instruction']['voyage']
      attrs[:shipper_party_role_id] = get_party_role_id(voyage['shipper'], AppConst::ROLE_SHIPPER)
      attrs[:booking_reference] = voyage['booking_reference']
      attrs[:vessel_id] = get_case_insensitive_match_or_variant(:vessels, vessel_code: voyage['vessel_code'])
      attrs[:vessel_type_id] = repo.get(:vessels,  attrs[:vessel_id], :vessel_type_id)
      attrs[:voyage_type_id] = repo.get(:vessel_types, attrs[:vessel_type_id], :voyage_type_id)

      args = { voyage_code: voyage['voyage_code'],
               vessel_id: attrs[:vessel_id],
               completed: false }
      attrs[:voyage_id] = get_case_insensitive_match_or_variant(:voyages, args)
      attrs[:voyage_number] = voyage['voyage_number']
      attrs[:year] = voyage['year']

      attrs[:pol_port_id] = get_case_insensitive_match_or_variant(:ports, port_code: voyage['pol']['port_code'])
      attrs[:atd] = voyage['pol']['atd']
      attrs[:etd] = voyage['pol']['etd']

      attrs[:pod_port_id] = get_case_insensitive_match_or_variant(:ports, port_code: voyage['pod']['port_code'])
      attrs[:ata] = voyage['pod']['ata']
      attrs[:eta] = voyage['pod']['eta']
    end

    def parse_load_edi # rubocop:disable Metrics/AbcSize
      load = @edi_records['load_instruction']['load']
      attrs[:exporter_party_role_id] = get_party_role_id(load['exporter'], AppConst::ROLE_EXPORTER)
      attrs[:billing_client_party_role_id] = get_party_role_id(load['exporter'], AppConst::ROLE_BILLING_CLIENT)
      attrs[:consignee_party_role_id] = get_party_role_id(load['consignee'], AppConst::ROLE_CONSIGNEE)
      attrs[:customer_party_role_id] = get_party_role_id(load['customer'], AppConst::ROLE_CUSTOMER)
      attrs[:final_receiver_party_role_id] = get_party_role_id(load['final_receiver'], AppConst::ROLE_FINAL_RECEIVER)
      final_destination_id = get_case_insensitive_match_or_variant(:ports, port_code: load['final_destination'])
      attrs[:final_destination_id] = repo.get(:ports, final_destination_id, :city_id)
      attrs[:depot_id] = get_case_insensitive_match_or_variant(:depots, depot_code: load['depot_code'])
      attrs[:transfer_load] = false
      attrs[:customer_order_number] = load['customer_order_number']
      @match_data = load['load_instruction_code']
    end

    def parse_pallets_edi
      pallets = @edi_records['load_instruction']['load']['pallets'] || []
      pallets.each do |hash|
        pallet_numbers << hash['pallet_number']
      end
    end

    def get_party_role_id(party_role_name, role_name) # rubocop:disable Metrics/AbcSize
      role_id = repo.get_id(:roles, name: role_name)
      raise Crossbeams::InfoError, "There is no role #{role_name}" if role_id.nil?

      org_id ||= repo.get_case_insensitive_match(:organizations, medium_description: party_role_name)
      org_id ||= repo.get_case_insensitive_match(:organizations, long_description: party_role_name)
      org_id ||= repo.get_id(:organizations, Sequel.lit("'#{party_role_name}' ilike ANY(variants)"))

      id = repo.get_id(:party_roles, role_id: role_id, organization_id: org_id)
      return id unless id.nil?

      missing_masterfiles << ["#{role_name}: #{party_role_name}"] if id.nil?
      nil
    end

    def get_case_insensitive_match_or_variant(table_name, args)
      id = repo.get_case_insensitive_match(table_name, args)
      return id unless id.nil?

      arg = args.first
      id = repo.get_variant_id(table_name, arg[1])
      missing_masterfiles << ["#{arg[0]}: #{arg[1]}"] if id.nil?
      nil
    end

    def check_pallets(check, pallet_numbers, load_id = nil)
      res = MesscadaApp::TaskPermissionCheck::Pallets.call(check, pallet_numbers, load_id)
      raise Crossbeams::InfoError, res.messsage unless res.success
    end
  end
end
