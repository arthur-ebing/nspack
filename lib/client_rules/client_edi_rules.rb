# frozen_string_literal: true

module Crossbeams
  class ClientEdiRules < BaseClientRules
    include Crossbeams::AutoDocumentation

    CLIENT_SETTINGS = {
      hb: { install_location: 'HABATA',
            load_id_prefix: '',
            csv_overrides: {},
            ps_apply_substitutes: false },
      hl: { install_location: 'HABATA',
            load_id_prefix: '',
            csv_overrides: {},
            ps_apply_substitutes: false },
      kr: { install_location: 'RA_8AND9',
            load_id_prefix: '',
            csv_overrides: { hcs: { col_sep: '|', force_quotes: true } },
            ps_apply_substitutes: false },
      um: { install_location: 'MATCOLD',
            load_id_prefix: '',
            csv_overrides: {},
            ps_apply_substitutes: false },
      ud: { install_location: 'UNIFRUT',
            load_id_prefix: '',
            csv_overrides: {},
            ps_apply_substitutes: false },
      sr: { install_location: 'SRKIRKW',
            load_id_prefix: '',
            csv_overrides: {},
            ps_apply_substitutes: false },
      sr2: { install_location: 'SRADDO',
             load_id_prefix: 'A',
             csv_overrides: {},
             ps_apply_substitutes: false }
    }.freeze

    def initialize(client_code)
      super
      @settings = CLIENT_SETTINGS.fetch(client_code.to_sym)
      validate_settings
    end

    def apply_substitutes_for_ps?(explain: false)
      return 'For PS EDI out, should the system place special values in these columns: original_account, saftbin1, saftbin2 and product_characteristic_code?' if explain

      setting(:ps_apply_substitutes)
    end

    def csv_column_separator(flow_type, explain: false)
      return 'For CSV output files, override the column separator. The default is ",".' if explain

      (setting(:csv_overrides)[flow_type.downcase.to_sym] || {})[:col_sep] || ','
    end

    def csv_force_quotes(flow_type, explain: false)
      return 'For CSV output files, force every column to be quoted. The default is false, which means that only non-numeric columns are quoted (standard behaviour).' if explain

      (setting(:csv_overrides)[flow_type.downcase.to_sym] || {})[:force_quotes] || false
    end

    private

    def validate_settings
      loc = setting(:install_location)
      raise "Install location #{loc} cannot be more than 7 characters in length" if loc.length > 7
    end
  end
end
