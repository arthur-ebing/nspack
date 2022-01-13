# frozen_string_literal: true

module EdiApp
  class NsgtinIn < BaseEdiInService
    # attr_accessor :missing_masterfiles, :match_data, :parsed_bins
    attr_reader :user, :repo

    def initialize(edi_in_transaction_id, file_path, logger, edi_in_result)
      super(edi_in_transaction_id, file_path, logger, edi_in_result)
      @repo = EdiApp::EdiInRepo.new
      @po_repo = EdiApp::PoInRepo.new
      @user = OpenStruct.new(user_name: 'System')
      # @missing_masterfiles = []
      # @match_data = []
    end

    def call
      # Read all records & create GTIN records, fetching ids when possible
      # Afterwards trigger a job to generate masterfiles from gtins where ids are blank... (client setting)
      #
      create_gtin_records
      # parse_palbin_edi
      #
      # match_data_on(prepare_array_for_match(match_data))
      #
      # check_missing_masterfiles
      #
      # business_validation
      #
      # create_records

      # Enqueue a job to work through GTINS without ids...
      success_response('GTINs processed')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def create_gtin_records # rubocop:disable Metrics/AbcSize
      repo.transaction do
        @edi_records.each do |rec|
          trimmed_rec = rec.transform_values { |v| v.nil? ? v : v.strip }
          res = EdiNsgtinInSchema.call(prepare_inputs(trimmed_rec.transform_keys(&:to_sym)))
          raise Crossbeams::InfoError, validation_failed_response(res) if res.failure? # OR collect these?

          attrs = { transaction_number: res[:transaction_number],
                    gtin_code: res[:gtin_code] }

          gtin_id = repo.get_id_or_create_with_status(:gtins, 'NSGTIN_PROCESSED', attrs)
          repo.update(:gtins, gtin_id, res.to_h)
        end

        ok_response
      end
    end

    def prepare_inputs(rec) # rubocop:disable Metrics/AbcSize
      attrs = rec.dup
      attrs[:active] = attrs[:active].nil? ? true : !rec[:active] == 'N'
      attrs[:date_from] = rec[:date_from] || Date.today.strftime('%Y-%m-%d')

      # Lookup ids if they exist...
      attrs[:marketing_org_party_role_id] = get_marketing_org_id(rec[:org_code])
      attrs[:commodity_id] = get_masterfile_match_or_variant(:commodities, code: rec[:commodity_code])
      attrs[:marketing_variety_id] = get_masterfile_match_or_variant(:marketing_varieties, marketing_variety_code: rec[:marketing_variety_code])
      attrs[:standard_pack_code_id] = get_masterfile_match_or_variant(:standard_pack_codes, standard_pack_code: rec[:standard_pack_code])
      attrs[:mark_id] = get_masterfile_match_or_variant(:marks, mark_code: rec[:mark_code])
      attrs[:grade_id] = get_masterfile_match_or_variant(:grades, grade_code: rec[:grade_code])
      attrs[:inventory_code_id] = get_masterfile_match_or_variant(:inventory_codes, inventory_code: rec[:inventory_code])
      resolve_size_count_attrs(rec, attrs)
    end

    # FOLLOWING IS COPIED FROM MFGTIN - move to a repo?
    def get_marketing_org_id(marketing_org)
      id = MasterfilesApp::PartyRepo.new.find_party_role_from_org_code_for_role(marketing_org, AppConst::ROLE_MARKETER)
      return id unless id.nil?

      repo.get_variant_id(:marketing_party_roles, marketing_org)
    end

    def get_masterfile_match_or_variant(table_name, args)
      id = repo.get_case_insensitive_match(table_name, args)
      return id unless id.nil?

      _col, val = args.first
      repo.get_variant_id(table_name, val)
    end

    def resolve_size_count_attrs(params, attrs)
      size = params[:size_count_code]
      if size =~ /\D/
        # log('Looking for size ref')
        attrs[:fruit_size_reference_id] = get_masterfile_match_or_variant(:fruit_size_references, size_reference: params[:size_count_code])
      else
        # log('Looking for count')
        attrs[:fruit_actual_counts_for_pack_id] = find_fruit_actual_counts_for_pack_id(params, attrs)
      end
      attrs
    end

    def find_fruit_actual_counts_for_pack_id(params, attrs)
      basic_pack_code_id = @po_repo.find_basic_pack_id(attrs[:standard_pack_code_id]) # 4
      @po_repo.fruit_actual_counts_for_pack_via_std_commodity(basic_pack_code_id, params[:size_count_code], attrs[:commodity_id])
      # log("Count for #{basic_pack_code_id}, #{params[:size_count_code]}, #{attrs[:commodity_id]} - id: #{id}")
      # id
    end
  end
end
__END__
-- Paltrack query:
SELECT
gtin AS gtin_code,
tran_no AS transaction_number,
orgzn AS org_code,
commodity AS commodity_code,
variety AS marketing_variety_code,
pack AS standard_pack_code,
grade AS grade_code,
mark AS mark_code,
inv_code AS inventory_code,
size_count AS size_count_code,
NULL AS date_from, -- Can be NULL, will be set to today in that case
NULL AS date_to,   -- Can be NULL
CASE WHEN active = 'N' THEN 'N' ELSE NULL END AS active
FROM gtin


-- CMS query
SELECT code AS gtin_code,
transaction_number,
organisation AS org_code,
commodity AS commodity_code,
variety AS marketing_variety_code,
pack AS standard_pack_code,
grade AS grade_code,
mark AS mark_code,
inventory_code,
sizecount AS size_count_code,
NULL AS date_from, -- Can be NULL, will be set to today in that case
NULL AS date_to,   -- Can be NULL
CASE WHEN active = 0 THEN 'N' ELSE NULL END AS active
FROM cs_gtins
