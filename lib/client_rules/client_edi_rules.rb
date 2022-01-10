# frozen_string_literal: true

module Crossbeams
  class ClientEdiRules < BaseClientRules
    include Crossbeams::AutoDocumentation

    CLIENT_SETTINGS = {
      hb: { install_location: 'HABATA',
            install_depot: 'HB',
            sender: 'HB',
            load_id_prefix: '',
            default_edi_in_inv_code: 'UL',
            li_default_pallet_base: 'S',
            li_default_pallet_stack_height: 'S',
            li_receive_restricted_to_orgs: [],
            csv_overrides: {},
            send_hbs_edi: false,
            po_in_force_orchard: false,
            edi_in_default_phc: nil,
            edi_out_account: nil,
            ps_apply_substitutes: false },
      hl: { install_location: 'HABATA',
            install_depot: 'HB',
            sender: 'HB',
            load_id_prefix: '',
            default_edi_in_inv_code: 'UL',
            li_default_pallet_base: 'S',
            li_default_pallet_stack_height: 'S',
            li_receive_restricted_to_orgs: [],
            csv_overrides: {},
            send_hbs_edi: false,
            po_in_force_orchard: false,
            edi_in_default_phc: nil,
            edi_out_account: nil,
            ps_apply_substitutes: false },
      kr: { install_location: 'KROMCO',
            install_depot: 'KROMCO',
            sender: 'KR',
            load_id_prefix: '',
            default_edi_in_inv_code: 'UL',
            li_default_pallet_base: 'BLU',
            li_default_pallet_stack_height: 'S',
            li_receive_restricted_to_orgs: ['TI'],
            csv_overrides: { hbs: { col_sep: '|', force_quotes: true },
                             hcs: { col_sep: '|', force_quotes: true } },
            send_hbs_edi: true,
            po_in_force_orchard: true,
            edi_in_default_phc: 'Unknown',
            edi_out_account: '8385',
            ps_apply_substitutes: false },
      um: { install_location: 'MATCOLD',
            install_depot: 'UM',
            sender: 'UM',
            load_id_prefix: '',
            default_edi_in_inv_code: 'UL',
            li_default_pallet_base: 'S',
            li_default_pallet_stack_height: 'S',
            li_receive_restricted_to_orgs: [],
            csv_overrides: {},
            send_hbs_edi: false,
            po_in_force_orchard: false,
            edi_in_default_phc: nil,
            edi_out_account: nil,
            ps_apply_substitutes: false },
      ud: { install_location: 'UNIFRUT',
            install_depot: 'UD',
            sender: 'UD',
            load_id_prefix: '',
            default_edi_in_inv_code: 'UL',
            li_default_pallet_base: 'S',
            li_default_pallet_stack_height: 'S',
            li_receive_restricted_to_orgs: [],
            csv_overrides: {},
            send_hbs_edi: false,
            po_in_force_orchard: false,
            edi_in_default_phc: nil,
            edi_out_account: nil,
            ps_apply_substitutes: false },
      cfg: { install_location: 'CFG',
             install_depot: 'CFG',
             sender: 'CF',
             load_id_prefix: '',
             default_edi_in_inv_code: 'UL',
             li_default_pallet_base: 'BLU',
             li_default_pallet_stack_height: 'S',
             li_receive_restricted_to_orgs: ['TI'],
             csv_overrides: { hbs: { col_sep: '|', force_quotes: true },
                              hcs: { col_sep: '|', force_quotes: true } },
             send_hbs_edi: false,
             po_in_force_orchard: false,
             edi_in_default_phc: 'Unknown',
             edi_out_account: '0000',
             ps_apply_substitutes: false },
      mc: { install_location: 'MC',
            install_depot: 'MC',
            sender: 'MC',
            load_id_prefix: '',
            default_edi_in_inv_code: 'UL',
            li_default_pallet_base: 'S',
            li_default_pallet_stack_height: 'S',
            li_receive_restricted_to_orgs: [],
            csv_overrides: {},
            send_hbs_edi: false,
            po_in_force_orchard: false,
            edi_in_default_phc: nil,
            edi_out_account: nil,
            ps_apply_substitutes: false },
      sr: { install_location: 'SRKIRKW',
            install_depot: 'SR',
            sender: 'SR',
            load_id_prefix: '',
            default_edi_in_inv_code: 'UL',
            li_default_pallet_base: 'S',
            li_default_pallet_stack_height: 'S',
            li_receive_restricted_to_orgs: [],
            csv_overrides: {},
            send_hbs_edi: false,
            po_in_force_orchard: false,
            edi_in_default_phc: nil,
            edi_out_account: nil,
            ps_apply_substitutes: false },
      sr2: { install_location: 'SRADDO',
             install_depot: 'SR',
             sender: 'SR',
             load_id_prefix: 'A',
             default_edi_in_inv_code: 'UL',
             li_default_pallet_base: 'S',
             li_default_pallet_stack_height: 'S',
             li_receive_restricted_to_orgs: [],
             csv_overrides: {},
             send_hbs_edi: false,
             po_in_force_orchard: false,
             edi_in_default_phc: nil,
             edi_out_account: nil,
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

    def orig_account(explain: false)
      return 'Account to be used in EDI out files. Formatted for SQL.' if explain

      acc = setting(:edi_out_account)
      acc ? "'#{acc}'" : 'NULL'
    end

    def install_depot(explain: false)
      return "This installation's depot code. Used in PO output EDI flows." if explain

      setting(:install_depot)
    end

    def sender(explain: false)
      return "This installation's sender code. Used in PO output EDI flows." if explain

      setting(:sender)
    end

    private

    def validate_settings
      loc = setting(:install_location)
      raise "Install location #{loc} cannot be more than 7 characters in length" if loc.length > 7

      depot = setting(:install_depot)
      raise "Install depot #{depot} cannot be more than 7 characters in length" if depot.length > 7

      sender = setting(:sender)
      raise "Sender #{sender} cannot be more than 2 characters in length" if sender.length > 2
    end
  end
end
