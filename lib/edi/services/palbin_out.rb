# frozen_string_literal: true

module EdiApp
  class PalbinOut < BaseEdiOutService
    attr_reader :org_code, :repo

    def initialize(edi_out_transaction_id, logger)
      @repo = EdiApp::EdiOutRepo.new
      super(AppConst::EDI_FLOW_PALBIN, edi_out_transaction_id, logger)
    end

    def call # rubocop:disable Metrics/AbcSize
      log('Starting transform...')
      prepare_data
      return success_response('No data for PALBIN') if record_entries.length.zero?

      fname = create_csv_file
      store_edi_filename(fname, record_id)

      log('Ending transform...')
      success_response('PALBIN Out was successful', fname)
    rescue Crossbeams::InfoError => e
      log_palbin_fail(record_id, e.message)
      failed_response(e.message)
    end

    private

    def prepare_data
      palbins = palbin_details(record_id)
      pallet_numbers = []
      palbins.each do |pallet|
        # pallets with multiple sequences should not be allowed on palbin load
        raise Crossbeams::InfoError, "Palbin: #{pallet[:sscc]} has multiple sequences" if pallet_numbers.include?(pallet[:sscc])

        pallet_numbers << pallet[:sscc]
      end

      palbins.each { |row| add_csv_record(row) }
    end

    def palbin_details(load_id)
      query = <<~SQL
        SELECT
            loads.shipped_at,
            depots.depot_code destination,
            '#{AppConst::INSTALL_LOCATION}' AS depot,
            pallets.pallet_number AS sscc,
            farms.farm_code AS farm,
            pucs.puc_code AS puc,
            orchards.orchard_code AS orchard,
            commodities.code AS commodity,
            cultivars.cultivar_name AS cultivar,
            grades.grade_code AS grade,
            standard_pack_codes.standard_pack_code AS pack,
            fruit_size_references.size_reference,
            ROUND(pallets.gross_weight, 2)::text AS gross_weight,
            ROUND(pallet_sequences.nett_weight, 2)::text AS nett_weight

        FROM loads
        JOIN depots ON depots.id = loads.depot_id
        JOIN pallets ON pallets.load_id = loads.id AND NOT scrapped
        JOIN pallet_sequences ON pallet_sequences.pallet_id = pallets.id AND NOT scrapped
        JOIN farms ON farms.id = pallet_sequences.farm_id
        JOIN pucs ON pucs.id = pallet_sequences.puc_id
        JOIN orchards ON orchards.id = pallet_sequences.orchard_id
        JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
        JOIN cultivars ON cultivars.id = pallet_sequences.cultivar_id
        JOIN commodities ON commodities.id = cultivar_groups.commodity_id
        JOIN grades ON grades.id = pallet_sequences.grade_id
        JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
        JOIN fruit_size_references ON fruit_size_references.id = pallet_sequences.fruit_size_reference_id
        LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = pallet_sequences.fruit_actual_counts_for_pack_id

        WHERE loads.rmt_load
        AND loads.id = ?
        ORDER BY pallets.pallet_number
      SQL
      DB[query, load_id].all
    end

    def store_edi_filename(file_name, record_id)
      repo.update(:loads, record_id, edi_file_name: file_name)
      repo.log_status(:loads, record_id, 'PALBIN SENT', user_name: 'System', comment: file_name)
    end

    def log_palbin_fail(record_id, message)
      repo.log_status(:loads, record_id, 'PALBIN SEND FAILURE', user_name: 'System', comment: message)
    end
  end
end
