# frozen_string_literal: true

module Crossbeams
  class ClientEdiRules < BaseClientRules # rubocop:disable Metrics/ClassLength
    include Crossbeams::AutoDocumentation

    CLIENT_SETTINGS = {
      hb: { install_location: 'HABATA',
            load_id_prefix: '',
            default_edi_in_inv_code: 'UL',
            li_default_pallet_base: 'S',
            li_default_pallet_stack_height: 'S',
            li_receive_restricted_to_orgs: [],
            csv_overrides: {},
            send_hbs_edi: false,
            po_in_force_orchard: false,
            ps_apply_substitutes: false },
      hl: { install_location: 'HABATA',
            load_id_prefix: '',
            default_edi_in_inv_code: 'UL',
            li_default_pallet_base: 'S',
            li_default_pallet_stack_height: 'S',
            li_receive_restricted_to_orgs: [],
            csv_overrides: {},
            send_hbs_edi: false,
            po_in_force_orchard: false,
            ps_apply_substitutes: false },
      kr: { install_location: 'KROMCO',
            load_id_prefix: '',
            default_edi_in_inv_code: 'UL',
            li_default_pallet_base: 'BLU',
            li_default_pallet_stack_height: 'S',
            li_receive_restricted_to_orgs: ['TI'],
            csv_overrides: { hbs: { col_sep: '|', force_quotes: true },
                             hcs: { col_sep: '|', force_quotes: true } },
            send_hbs_edi: true,
            po_in_force_orchard: true,
            ps_apply_substitutes: false },
      um: { install_location: 'MATCOLD',
            load_id_prefix: '',
            default_edi_in_inv_code: 'UL',
            li_default_pallet_base: 'S',
            li_default_pallet_stack_height: 'S',
            li_receive_restricted_to_orgs: [],
            csv_overrides: {},
            send_hbs_edi: false,
            po_in_force_orchard: false,
            ps_apply_substitutes: false },
      ud: { install_location: 'UNIFRUT',
            load_id_prefix: '',
            default_edi_in_inv_code: 'UL',
            li_default_pallet_base: 'S',
            li_default_pallet_stack_height: 'S',
            li_receive_restricted_to_orgs: [],
            csv_overrides: {},
            send_hbs_edi: false,
            po_in_force_orchard: false,
            ps_apply_substitutes: false },
      sr: { install_location: 'SRKIRKW',
            load_id_prefix: '',
            default_edi_in_inv_code: 'UL',
            li_default_pallet_base: 'S',
            li_default_pallet_stack_height: 'S',
            li_receive_restricted_to_orgs: [],
            csv_overrides: {},
            send_hbs_edi: false,
            po_in_force_orchard: false,
            ps_apply_substitutes: false },
      sr2: { install_location: 'SRADDO',
             load_id_prefix: 'A',
             default_edi_in_inv_code: 'UL',
             li_default_pallet_base: 'S',
             li_default_pallet_stack_height: 'S',
             li_receive_restricted_to_orgs: [],
             csv_overrides: {},
             send_hbs_edi: false,
             po_in_force_orchard: false,
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

    def process_li_for_org?(org_code, explain: false)
      return 'An EDI LI can be restricted to only be received for one or more organizations.' if explain

      setting(:li_receive_restricted_to_orgs).include?(org_code)
    end

    def create_unknown_orchard?(explain: false)
      return 'Should EDI PO in create an orchard if the input value is missing.' if explain

      setting(:po_in_force_orchard)
    end

    private

    def validate_settings
      loc = setting(:install_location)
      raise "Install location #{loc} cannot be more than 7 characters in length" if loc.length > 7
    end
  end
end
