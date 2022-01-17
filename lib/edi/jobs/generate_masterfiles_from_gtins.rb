# frozen_string_literal: true

module EdiApp
  module Job
    class GenerateMasterfilesFromGtins < BaseQueJob
      attr_reader :repo, :party_repo, :edi_in_repo

      def run
        @repo = NsgtinInRepo.new
        @party_repo = MasterfilesApp::PartyRepo.new
        @edi_in_repo = EdiInRepo.new

        # import_commodities --> Cannot do this because we have no way of knowing the correct commodity group.
        import_marks
        import_grades
        import_standard_pack_codes
        import_inventory_codes
        import_marketing_varieties
        import_marketing_orgs
        import_size_refs
        # import_actual_counts # DO THIS ONLY for GHS-type client where std count == actual count...

        finish
      end

      private

      def import_marks
        repo.transaction do
          recs = repo.missing_gtin_marks
          recs.each do |code|
            id = repo.get_id(:marks, mark_code: code)
            id = repo.create(:marks, mark_code: code) if id.nil?
            repo.update_gtin_marks(code, id)
          end
        end
      end

      def import_grades
        repo.transaction do
          recs = repo.missing_gtin_grades
          recs.each do |code|
            id = repo.get_id(:grades, grade_code: code)
            id = repo.create(:grades, grade_code: code) if id.nil?
            repo.update_gtin_grades(code, id)
          end
        end
      end

      def import_standard_pack_codes # rubocop:disable Metrics/AbcSize
        repo.transaction do
          recs = repo.missing_gtin_standard_pack_codes
          recs.each do |code|
            id = repo.get_id(:standard_pack_codes, standard_pack_code: code)
            unless id.nil?
              repo.update_gtin_standard_pack_codes(code, id)
              next
            end

            id = repo.create(:standard_pack_codes, standard_pack_code: code, material_mass: 1)
            b_id = repo.get_id(:basic_pack_codes, basic_pack_code: code)
            b_id = repo.create(:basic_pack_codes, basic_pack_code: code) if b_id.nil?
            repo.create(:basic_packs_standard_packs, basic_pack_id: b_id, standard_pack_id: id)
            repo.update_gtin_standard_pack_codes(code, id)
          end
        end
      end

      def import_marketing_varieties # rubocop:disable Metrics/AbcSize
        repo.transaction do
          recs = repo.missing_gtin_marketing_varieties
          recs.each do |commodity_code, code|
            id = repo.get_id(:marketing_varieties, marketing_variety_code: code)
            unless id.nil?
              repo.update_gtin_marketing_varieties(commodity_code, code, id)
              next
            end

            group_id = repo.get_id(:cultivar_groups, cultivar_group_code: commodity_code)
            if group_id.nil?
              commodity_id = repo.get_id(:commodities, code: commodity_code)
              raise Crossbeams::InfoError, "There is no commodity with code #{commodity_code}" if commodity_id.nil?

              group_id = repo.create(:cultivar_groups, cultivar_group_code: commodity_code, commodity_id: commodity_id)
            end
            cultivar_id = repo.get_id(:cultivars, cultivar_name: code)
            cultivar_id = repo.create(:cultivars, cultivar_name: code, cultivar_code: code, cultivar_group_id: group_id) if cultivar_id.nil?
            id = repo.create(:marketing_varieties, marketing_variety_code: code)
            repo.create(:marketing_varieties_for_cultivars, cultivar_id: cultivar_id, marketing_variety_id: id)
            repo.update_gtin_marketing_varieties(commodity_code, code, id)
          end
        end
      end

      def import_marketing_orgs # rubocop:disable Metrics/AbcSize
        repo.transaction do
          recs = repo.missing_gtin_marketing_orgs
          recs.each do |code|
            id = party_repo.find_party_role_from_party_name_for_role(code, AppConst::ROLE_MARKETER)
            unless id.nil?
              repo.update_gtin_marketing_orgs(code, res.instance.party_role_id)
              next
            end

            org_id = repo.get_id(:organizations, short_description: code)
            params = { short_description: code,
                       medium_description: code,
                       long_description: code,
                       vat_number: nil,
                       company_reg_no: nil }
            params[:pr_id] = if org_id.nil?
                               'Create New Organization'
                             else
                               org_id
                             end
            res = MasterfilesApp::CreatePartyRole.call(AppConst::ROLE_MARKETER, params, 'GTIN import', column_name: :pr_id)
            raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

            repo.update_gtin_marketing_orgs(code, res.instance.party_role_id)
          end
        end
      end

      def import_size_refs
        repo.transaction do
          recs = repo.missing_gtin_size_refs
          recs.each do |code|
            id = repo.get_id(:fruit_size_references, size_reference: code)
            id = repo.create(:fruit_size_references, size_reference: code) if id.nil?
            repo.update_gtin_fruit_size_references(code, id)
          end
        end
      end

      # def import_actual_counts
      #   repo.transaction do
      #     recs = repo.missing_gtin_actual_counts
      #     recs.each do |commodity_code, standard_pack_code, code|
      #       standard_pack_code_id = get_masterfile_match_or_variant(:standard_pack_codes, standard_pack_code: standard_pack_code)
      #       basic_pack_code_id = repo.find_basic_pack_id(standard_pack_code_id)
      #       next if basic_pack_code_id.nil?
      #
      #       # basic pack - which is standard for each commodity.
      #       commodity_id = repo.get_id(:commodities, code: commodity_code)
      #       id = find_actual_count_id(basic_pack_code_id, commodity_id, code)
      #
      #       if id.nil?
      #         # IF this count is a standard count, we can add it...
      #         # std_fruit_size_count_id = repo.get_id(:std_fruit_size_counts, size_count_value: code, commodity_id: commodity_id) # GHS ok, not CFG..
      #         # next if std_fruit_size_count_id.nil? # CREATE... at GHS, not CFG - client rule to come..
      #
      #         std_id = repo.first_std_count
      #         # Create inactive pointing to 1st std id
      #         id = repo.create(:fruit_actual_counts_for_packs,
      #                          basic_pack_code_id: basic_pack_code_id,
      #                          std_fruit_size_count_id: std_id,
      #                          standard_pack_code_ids: [standard_pack_code_id],
      #                          actual_count_for_pack: code)
      #       end
      #
      #       repo.update_gtin_fruit_actual_counts_for_packs(commodity_code, standard_pack_code, code, id)
      #     end
      #   end
      # end
      #
      # def find_actual_count_id(basic_pack_code_id, commodity_id, size_count_code)
      #   repo.fruit_actual_counts_for_pack_via_std_commodity(basic_pack_code_id, size_count_code, commodity_id)
      # end

      def import_inventory_codes
        repo.transaction do
          recs = repo.missing_gtin_inventory_codes
          recs.each do |code|
            id = repo.get_id(:inventory_codes, inventory_code: code)
            id = repo.create(:inventory_codes, inventory_code: code) if id.nil?
            repo.update_gtin_inventory_codes(code, id)
          end
        end
      end

      def get_masterfile_match_or_variant(table_name, args)
        id = edi_in_repo.get_case_insensitive_match(table_name, args)
        return id unless id.nil?

        _col, val = args.first
        edi_in_repo.get_variant_id(table_name, val)
      end
    end
  end
end
