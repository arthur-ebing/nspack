# frozen_string_literal: true

module Crossbeams
  class ClientProductionRules < BaseClientRules # rubocop:disable Metrics/ClassLength
    include Crossbeams::AutoDocumentation

    CLIENT_SETTINGS = {
      hb: { run_allocations: false,
            pallet_label_seqs_sql: 'SELECT ps.production_run_id, o.orchard_code, c.cultivar_code, ps.nett_weight FROM pallet_sequences ps JOIN orchards o ON o.id = ps.orchard_id JOIN cultivars c ON c.id = ps.cultivar_id WHERE ps.pallet_id = ? ORDER BY ps.pallet_sequence_number',
            use_gtins: false,
            print_from_line_scanning: false,
            allow_cultivar_group_mix: true },
      hl: { run_allocations: true,
            pallet_label_seqs_sql: nil,
            use_gtins: false,
            print_from_line_scanning: false,
            allow_cultivar_group_mix: true },
      kr: { run_allocations: true,
            pallet_label_seqs_sql: 'SELECT p.puc_code, p.gap_code, ps.gtin_code, ps.carton_quantity FROM pallet_sequences ps JOIN pucs p ON p.id = ps.puc_id WHERE ps.pallet_id = ? ORDER BY ps.pallet_sequence_number',
            use_gtins: true,
            print_from_line_scanning: true,
            allow_cultivar_group_mix: false },
      um: { run_allocations: true,
            pallet_label_seqs_sql: 'SELECT o.orchard_code, m.marketing_variety_code, s.size_reference, ps.carton_quantity FROM pallet_sequences ps JOIN orchards o ON o.id = ps.orchard_id JOIN marketing_varieties m ON m.id = ps.marketing_variety_id JOIN fruit_size_references s ON s.id = ps.fruit_size_reference_id WHERE ps.pallet_id = ? ORDER BY ps.pallet_sequence_number',
            use_gtins: false,
            print_from_line_scanning: false,
            allow_cultivar_group_mix: false },
      ud: { run_allocations: true,
            pallet_label_seqs_sql: nil,
            use_gtins: false,
            print_from_line_scanning: false,
            allow_cultivar_group_mix: true },
      sr: { run_allocations: true,
            pallet_label_seqs_sql: nil,
            use_gtins: false,
            print_from_line_scanning: true,   # TEMP TEST...
            allow_cultivar_group_mix: false },
      sr2: { run_allocations: true }
    }.freeze
    # ALLOW_OVERFULL_REWORKS_PALLETIZING
    # BASE_PACK_EQUALS_STD_PACK
    # BYPASS_QUALITY_TEST_LOAD_CHECK
    # BYPASS_QUALITY_TEST_PRE_RUN_CHECK
    # CAPTURE_PALLET_WEIGHT_AT_VERIFICATION
    # CARTON_EQUALS_PALLET
    # CARTON_VERIFICATION_REQUIRED
    # CLM_BUTTON_CAPTION_FORMAT
    # COMBINE_CARTON_AND_PALLET_VERIFICATION
    # DEFAULT_FG_PACKAGING_TYPE
    # DEFAULT_MARKETING_ORG
    # DEFAULT_PACKING_METHOD
    # DEFAULT_PALLET_LABEL_NAME
    # NO_RUN_ALLOCATION
    # PALLET_IS_IN_STOCK_WHEN_VERIFIED
    # PALLET_MIX_RULES_SCOPE
    # PRINT_PALLET_LABEL_AT_PALLET_VERIFICATION
    # PROVIDE_PACK_TYPE_AT_VERIFICATION
    # REQUIRE_EXTENDED_PACKAGING
    # REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION
    # REQUIRE_PACKAGING_BOM
    # ROBOT_DISPLAY_LINES
    # USE_CARTON_PALLETIZING

    PALLET_LBL_PSEQ_HEADS = {
      puc_code: 'PUC',
      gap_code: 'Gap code',
      gtin_code: 'GTIN',
      carton_quantity: 'Quantity',
      production_run_id: 'Run id',
      orchard_code: 'Orchard',
      cultivar_code: 'Cultivar',
      marketing_variety_code: 'Var',
      size_reference: 'Count'
    }.freeze

    def initialize(client_code)
      super()
      @settings = CLIENT_SETTINGS.fetch(client_code.to_sym)
    end

    def no_run_allocations?(explain: false)
      return 'Does this client not do allocation of product setup to resource?' if explain

      !setting(:run_allocations)
    end

    def can_mix_cultivar_groups?(explain: false)
      return 'Can culivar groups be mixed in a production run?' if explain

      setting(:allow_cultivar_group_mix)
    end

    def use_gtins?(explain: false)
      return 'Use masterfile codes and/or variants to lookup a gtin_code to store on setups, cartons and sequences.' if explain

      setting(:use_gtins)
    end

    def sequences_label_variable_for_pallet(pallet_id) # rubocop:disable Metrics/AbcSize
      query = setting(:pallet_label_seqs_sql)
      return [] unless query

      recs = DB[query, pallet_id].all
      heads = calculate_col_widths_and_headings(recs)

      out = []
      line = make_line(heads)
      out << line
      cols = heads.map { |_, value| " #{value[:head].ljust(value[:width])} |" }
      out << "|#{cols.join}"
      out << line
      recs.each do |rec|
        cols = rec.map do |key, value|
          v = case key
              when :nett_weight
                UtilityFunction.delimited_number(value).rjust(heads[key][:width])
              when :carton_quantity
                value.to_s.rjust(heads[key][:width])
              else
                value.to_s.ljust(heads[key][:width])
              end
          " #{v} |"
        end
        out << "|#{cols.join}"
      end
      out << line
      out
    end

    def calculate_col_widths_and_headings(recs)
      heads = col_headings(recs)

      recs.each do |rec|
        rec.each do |key, val|
          v = case key
              when :nett_weight
                UtilityFunction.delimited_number(val)
              when :carton_quantity
                val.to_s
              else
                val.to_s
              end
          heads[key][:width] = v.length if v.length > heads[key][:width]
        end
      end
      heads
    end

    def col_headings(recs)
      heads = {}
      recs.first.each_key do |col|
        heads[col] = {
          head: PALLET_LBL_PSEQ_HEADS[col] || col.capitalize.gsub('_', ' '),
          width: (PALLET_LBL_PSEQ_HEADS[col] || col).length
        }
      end
      heads
    end

    def make_line(heads)
      headline = ['+']
      heads.each { |_, value| headline << "-#{'-' * value[:width]}-+" }
      headline.join
    end
  end
end
