# frozen_string_literal: true

module ProductionApp
  class RepackPalletsOrBins < BaseService
    attr_reader :repo, :user_name, :pallet_numbers, :gross_weight, :basic_pack_id, :standard_pack_id, :grade_id, :pallet_id, :dest_pallet

    def initialize(user_name, params,  pallet_numbers)
      @repo = ProductionApp::ProductionRunRepo.new
      @pallet_numbers = pallet_numbers
      @gross_weight = params[:gross_weight]
      @basic_pack_id = params[:basic_pack_id]
      @standard_pack_id = params[:standard_pack_id]
      @grade_id = params[:grade_id]
      @user_name = user_name
    end

    def call # rubocop:disable Metrics/AbcSize
      res = validate
      return res unless res.success

      res = create_dest_pallet
      return res unless res.success

      @dest_pallet = repo.find_hash(:pallets, pallet_id)

      pallet_numbers.keys.sort.each do |p|
        res = create_dest_pallet_sequences(pallet_numbers[p])
        return res unless res.success
      end

      res = scrap_src_pallets(pallet_numbers.values)
      return res unless res.success

      success_response('Pallets Repacked successfully', pallet_id: pallet_id)
    end

    private

    def validate
      MesscadaApp::TaskPermissionCheck::Pallets.call(%i[exists not_shipped not_inspected], pallet_numbers.values)
    end

    def scrap_src_pallets(pallet_numbers)
      attrs = { scrapped: true, scrapped_at: Time.now, exit_ref: AppConst::PALLET_EXIT_REF_SCRAPPED }
      reworks_run_booleans = { scrap_pallets: true }
      ProductionApp::ReworksRepo.new.scrapping_reworks_run(pallet_numbers, attrs, reworks_run_booleans, user_name)

      ok_response
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_dest_pallet # rubocop:disable Metrics/AbcSize
      src_palllet = repo.find_pallet_by_pallet_number(pallet_numbers[:pallet_number1])
      pallet_rejected_fields = %i[id pallet_number]
      attrs = src_palllet.reject { |k, _| pallet_rejected_fields.include?(k) }
      attrs.merge!(repacked: true, repacked_at: Time.now, nett_weight_externally_calculated: true, gross_weight: gross_weight)
      @pallet_id = MesscadaApp::MesscadaRepo.new.create_pallet(user_name, attrs)

      ok_response
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_dest_pallet_sequences(pallet_number) # rubocop:disable Metrics/AbcSize
      repo.find_pallets_sequences(pallet_number).each do |s|
        seq_rejected_fields = %i[id pallet_number pallet_sequence_number]
        attrs = s.reject { |k, _| seq_rejected_fields.include?(k) }
        attrs[:repacked_from_pallet_id] = repo.get_value(:pallets, :id, pallet_number: pallet_number)
        attrs[:pallet_number] = dest_pallet[:pallet_number]
        attrs[:pallet_id] = dest_pallet[:pallet_id]
        attrs[:basic_pack_code_id] = basic_pack_id if basic_pack_id
        attrs[:standard_pack_code_id] = standard_pack_id
        attrs[:grade_id] = grade_id

        MesscadaApp::MesscadaRepo.new.create_sequences(attrs, pallet_id)
      end

      ok_response
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end
  end
end
