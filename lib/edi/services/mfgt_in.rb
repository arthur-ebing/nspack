# frozen_string_literal: true

module EdiApp
  class MfgtIn < BaseEdiInService
    attr_reader :user, :repo

    def initialize(edi_in_transaction_id, file_path, logger, edi_in_result)
      super(edi_in_transaction_id, file_path, logger, edi_in_result)
      @repo = EdiApp::EdiInRepo.new
      @user = OpenStruct.new(user_name: 'System')
    end

    def call
      missing_required_fields(only_rows: 'masterfile')

      business_validation_passed

      create_mfgt_records

      success_response('MfgtIn processed')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def create_mfgt_records # rubocop:disable Metrics/AbcSize
      repo.transaction do
        @edi_records.each do |params|
          res = EdiMfgtInContract.new.call(resolve_edi_record(params))
          raise Crossbeams::InfoError, validation_failed_response(res) if res.failure?

          attrs = { transaction_number: res[:transaction_number],
                    gtin_code: res[:gtin_code] }

          gtin_id = repo.get_id_or_create_with_status(:gtins, 'MFGT_PROCESSED', attrs)
          repo.update(:gtins, gtin_id, res.to_h)
        end

        ok_response
      end
    end

    def resolve_edi_record(params) # rubocop:disable Metrics/AbcSize
      attrs = {}
      attrs[:transaction_number] = params[:tranno]
      attrs[:gtin_code] = params[:gtin]
      attrs[:date_to] = convert_date_val(params[:date_end])
      attrs[:date_from] = convert_date_val(params[:date_strt])
      attrs[:org_code] = params[:orgzn]
      attrs[:commodity_code] = params[:commodity]
      attrs[:marketing_variety_code] = params[:variety]
      attrs[:standard_pack_code] = params[:pack]
      attrs[:grade_code] = params[:grade]
      attrs[:mark_code] = params[:mark]
      attrs[:size_count_code] = params[:size_count]
      attrs[:inventory_code] = params[:inv_code]
      attrs[:marketing_org_party_role_id] = get_marketing_org_id(params[:orgzn])
      attrs[:commodity_id] = get_masterfile_match_or_variant(:commodities, code: params[:commodity])
      attrs[:marketing_variety_id] = get_masterfile_match_or_variant(:marketing_varieties, marketing_variety_code: params[:variety])
      attrs[:standard_pack_code_id] = get_masterfile_match_or_variant(:standard_pack_codes, standard_pack_code: params[:pack])
      attrs[:mark_id] = get_masterfile_match_or_variant(:marks, mark_code: params[:mark])
      attrs[:grade_id] = get_masterfile_match_or_variant(:grades, grade_code: params[:grade])
      attrs[:inventory_code_id] = get_masterfile_match_or_variant(:inventory_codes, inventory_code: params[:inv_code])
      resolve_size_count_attrs(params, attrs)
    end

    def convert_date_val(val)
      return nil if val.nil_or_empty? || val == '00000000'

      DateTime.parse(val).strftime('%Y-%m-%d %H:%M:%S%z')
    end

    def get_marketing_org_id(marketing_org)
      id = MasterfilesApp::PartyRepo.new.find_party_role_from_org_code_for_role(marketing_org, AppConst::ROLE_MARKETER)
      return id unless id.nil?

      id = repo.get_variant_id(:marketing_party_roles, marketing_org) if id.nil?
      id
    end

    def get_masterfile_match_or_variant(table_name, args)
      id = repo.get_case_insensitive_match(table_name, args)
      return id unless id.nil?

      _col, val = args.first
      id = repo.get_variant_id(table_name, val)
      id
    end

    def resolve_size_count_attrs(params, attrs)
      fruit_actual_counts_for_pack_id = find_fruit_actual_counts_for_pack_id(params, attrs)
      attrs[:fruit_actual_counts_for_pack_id] = fruit_actual_counts_for_pack_id
      return attrs unless fruit_actual_counts_for_pack_id.nil_or_empty?

      attrs[:fruit_size_reference_id] = get_masterfile_match_or_variant(:fruit_size_references, size_reference: params[:size_count])
      attrs
    end

    def find_fruit_actual_counts_for_pack_id(params, attrs)
      basic_pack_code_id = EdiApp::PoInRepo.new.find_basic_pack_id(attrs[:standard_pack_code_id])
      std_fruit_size_count_id = find_std_fruit_size_count_id(params[:size_count], attrs[:commodity_id])
      id = repo.get_id(:fruit_actual_counts_for_packs, { basic_pack_code_id: basic_pack_code_id,
                                                         std_fruit_size_count_id: std_fruit_size_count_id,
                                                         actual_count_for_pack: params[:size_count] })
      return id unless id.nil?

      id = repo.get_variant_id(:fruit_actual_counts_for_packs, params[:size_count]) if id.nil?
      id
    end

    def find_std_fruit_size_count_id(size_count_value, commodity_id)
      id = repo.get_id(:std_fruit_size_counts, { commodity_id: commodity_id, size_count_value: size_count_value.to_i })
      return id unless id.nil?

      id = repo.get_variant_id(:std_fruit_size_counts, size_count_value) if id.nil?
      id
    end
  end
end
