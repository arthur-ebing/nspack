# frozen_string_literal: true

module EdiApp
  class NsrunIn < BaseEdiInService
    attr_reader :user, :repo, :party_repo, :edi_in_repo, :payload

    # def initialize(edi_in_transaction_id, file_path, logger, edi_in_result)
    #   super(edi_in_transaction_id, file_path, logger, edi_in_result)
    # end

    def call
      return success_response('Nothing to do - no input') if @edi_records.empty?

      @payload = { config: { generate_template: true } }
      prepare_header
      prepare_items

      ProductionRunImport.call(payload)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def prepare_header
      rec = clean_up_input(@edi_records.first)
      head = header_values_from(rec)

      payload[:header] = head
    end

    def header_values_from(rec)
      keys = %i[run_batch_number farm_code puc_code packhouse_code line_code
                season_code orchard_code lot_no_date cultivar_group_code cultivar_code
                cold_treatment_code ripeness_treatment_code rmt_code_code rmt_size_code]
      rec.slice(*keys)
    end

    def prepare_items
      items = []
      @edi_records.each do |rec|
        trimmed_rec = clean_up_input(rec)
        head = header_values_from(trimmed_rec)
        raise Crossbeams::InfoError, 'Production run header data is not identical for all input rows' unless head == payload[:header]

        keys = %i[marketing_variety std_fruit_size_count basic_pack_code standard_pack_code actual_count
                  fruit_size_reference marketing_org_code packed_tm_group mark_code inventory_code grade_code
                  target_market_code gtin_code pallet_base pallet_stack_type cartons_per_pallet client_size_reference
                  client_product_code treatment_ids marketing_order_number sell_by_code product_chars rmt_class_code
                  target_customer_code colour_percentage_code carton_label_template rebin]
        item = trimmed_rec.slice(*keys)

        items << item
      end
      payload[:items] = items
    end

    def clean_up_input(rec)
      return rec if rec.nil?

      rec.transform_values { |v| v.nil? ? v : v.strip }.transform_keys(&:to_sym)
    end
  end
end
