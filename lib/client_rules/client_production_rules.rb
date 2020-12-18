# frozen_string_literal: true

module Crossbeams
  class ClientProductionRules < BaseClientRules
    include Crossbeams::AutoDocumentation

    CLIENT_SETTINGS = {
      hb: { run_allocations: false,
            use_gtins: false,
            allow_cultivar_group_mix: true },
      hl: { run_allocations: true,
            use_gtins: false,
            allow_cultivar_group_mix: true },
      kr: { run_allocations: true,
            use_gtins: true,
            allow_cultivar_group_mix: false },
      um: { run_allocations: true,
            use_gtins: false,
            allow_cultivar_group_mix: false },
      ud: { run_allocations: true,
            use_gtins: false,
            allow_cultivar_group_mix: true },
      sr: { run_allocations: true,
            use_gtins: false,
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
  end
end
