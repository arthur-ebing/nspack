# frozen_string_literal: true

module UiRules
  class BinLoadRule < Base
    def generate_rules
      set_repo
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show complete].include? @mode

      form_name 'bin_load'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:bin_load_purpose_id] = { renderer: :label, with_value: @form_object.purpose_code, caption: 'Bin Load Purpose' }
      fields[:customer_party_role_id] = { renderer: :label, with_value: @form_object.customer, caption: 'Customer' }
      fields[:transporter_party_role_id] = { renderer: :label, with_value: @form_object.transporter, caption: 'Transporter' }
      fields[:dest_depot_id] = { renderer: :label, with_value: @form_object.dest_depot, caption: 'Dest Depot' }
      fields[:qty_bins] = { renderer: :label }
      fields[:shipped_at] = { renderer: :label, format: :without_timezone_or_seconds }
      fields[:shipped] = { renderer: :label, as_boolean: true }
      fields[:completed_at] = { renderer: :label, format: :without_timezone_or_seconds }
      fields[:completed] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        bin_load_purpose_id: { renderer: :select,
                               options: @repo.for_select_bin_load_purposes,
                               disabled_options: @repo.for_select_inactive_bin_load_purposes,
                               prompt: true,
                               caption: 'Bin Load Purpose' },
        customer_party_role_id: { renderer: :select,
                                  options: @party_repo.for_select_party_roles(AppConst::ROLE_RMT_CUSTOMER),
                                  disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_RMT_CUSTOMER),
                                  caption: 'Customer',
                                  prompt: true,
                                  required: true },
        transporter_party_role_id: { renderer: :select,
                                     options: @party_repo.for_select_party_roles(AppConst::ROLE_TRANSPORTER),
                                     disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_TRANSPORTER),
                                     prompt: true,
                                     caption: 'Transporter' },
        dest_depot_id: { renderer: :select,
                         options: @depot_repo.for_select_depots(where: { bin_depot: true }),
                         disabled_options: @depot_repo.for_select_inactive_depots,
                         prompt: true,
                         caption: 'Destination Depot',
                         required: true },
        qty_bins: { renderer: :numeric,
                    required: true },
        shipped_at: {},
        shipped: { renderer: :checkbox },
        completed_at: {},
        completed: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_bin_load_flat(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(bin_load_purpose_id: nil,
                                    customer_party_role_id: nil,
                                    transporter_party_role_id: nil,
                                    dest_depot_id: nil,
                                    qty_bins: nil,
                                    shipped_at: nil,
                                    shipped: nil,
                                    completed_at: nil,
                                    completed: nil)
    end

    def set_repo
      @repo = RawMaterialsApp::BinLoadRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      @depot_repo = MasterfilesApp::DepotRepo.new
    end
  end
end
