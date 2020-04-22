# frozen_string_literal: true

module FinishedGoodsApp
  class EdiCreateLoad < BaseService
    include LoadValidator
    attr_accessor :params, :payload, :load_id, :pallet_numbers
    attr_reader :repo, :validator, :user

    def initialize(payload = {})
      # payload = {"load_instruction"=>
      #               {"voyage"=>
      #                    {"shipper"=>"B&L",
      #                     "booking_reference"=>"711048489",
      #                     "voyage_code"=>"2020_124_SANTA RITA",
      #                     "year"=>"2020",
      #                     "voyage_number"=>"201B",
      #                     "shipping_line"=>"SAFMARINE",
      #                     "vessel_code"=>"SANTA RITA",
      #                     "pol"=>{"port_code"=>"ZACPT", "etd"=>"2020-03-24 00:00:00", "atd"=>"2020-03-24 00:00:00"},
      #                     "pod"=>{"port_code"=>"RULED", "eta"=>"2020-04-23 00:00:00", "ata"=>{}}},
      #                "load"=>
      #                    {"load_instruction_code"=>"something",
      #                     "final_destination"=>"RULED",
      #                     "depot_code"=>"ZACPT",
      #                     "consignee"=>"BELL CERES",
      #        >> ADDED             "exporter"=>"BELL CERES",
      #                     "customer_order_number"=>"16876",
      #                     "customer"=>"BELL CERES",
      #                     "final_receiver"=>"TOTAL FRUIT POINT",
      #                     "pallets"=>
      #                         [{"pallet_number"=>"600980218295233884"},
      #                          {"pallet_number"=>"600980218295233877"}]}}}

      @payload = payload
      @params = {}
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

      current_allocation = repo.select_values(:pallets, :pallet_number, load_id: load_id)
      new_allocation = pallet_numbers

      allocate = new_allocation - current_allocation
      unallocate = current_allocation - new_allocation

      unless unallocate.empty?
        res = validate_pallets(:not_shipped, unallocate)
        return res unless res.success

        res = repo.unallocate_pallets(load_id, unallocate, user.user_name)
        raise Crossbeams::InfoError, res.message unless res.success
      end

      res = repo.allocate_pallets(load_id, allocate, user.user_name)
      raise Crossbeams::InfoError, res.message unless res.success

      success_response("Allocation applied to load: #{load_id}")
    end

    def find_or_create_load # rubocop:disable Metrics/AbcSize
      res = validate_load_service_params(params)
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

      params[:shipper_party_role_id] = get_party_role_id(voyage['shipper'], AppConst::ROLE_SHIPPER)
      params[:booking_reference] = voyage['booking_reference']

      params[:vessel_id], params[:vessel_type_id] = repo.get_value(:vessels, %i[id vessel_type_id], vessel_code: voyage['vessel_code'])
      params[:voyage_type_id] = repo.get_id(:vessel_types, id: params[:vessel_type_id])

      args = { voyage_code: voyage['voyage_code'],
               voyage_number: voyage['voyage_number'],
               year: voyage['years'],
               vessel_id: params[:vessel_id],
               completed: false }
      params[:voyage_id] = repo.get_id(:voyages, args)
      params[:voyage_number] = voyage['voyage_number']
      params[:year] = voyage['year']
      params[:pol_port_id] = repo.get_id(:ports, port_code: voyage['pol']['port_code'])
      params[:pod_port_id] = repo.get_id(:ports, port_code: voyage['pod']['port_code'])
    end

    def parse_load_edi # rubocop:disable Metrics/AbcSize
      load = payload['load_instruction']['load']

      params[:exporter_party_role_id] = get_party_role_id(load['exporter'], AppConst::ROLE_EXPORTER)
      params[:billing_client_party_role_id] = params[:exporter_party_role_id]

      params[:consignee_party_role_id] = get_party_role_id(load['consignee'], AppConst::ROLE_CONSIGNEE)
      params[:customer_party_role_id] = get_party_role_id(load['customer'], AppConst::ROLE_CUSTOMER)
      params[:final_receiver_party_role_id] = get_party_role_id(load['final_receiver'], AppConst::ROLE_FINAL_RECEIVER)
      params[:final_destination_id] = repo.get_value(:ports, :city_id, port_code: load['final_destination'])

      params[:depot_id] = repo.get_id(:depots, depot_code: load['depot_code'])
      params[:transfer_load] = false
      params[:customer_order_number] = load['customer_order_number']
    end

    def parse_pallets_edi
      pallets = payload['load_instruction']['load']['pallets'] || []
      pallets.each do |hash|
        pallet_numbers << hash['pallet_number']
      end
    end

    def get_party_role_id(name, role)
      MasterfilesApp::PartyRepo.new.get_party_role_id(name, role)
    end
  end
end
