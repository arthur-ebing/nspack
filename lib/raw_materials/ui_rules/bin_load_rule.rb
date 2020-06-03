# frozen_string_literal: true

module UiRules
  class BinLoadRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      set_repo
      make_form_object
      make_progress_step
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'bin_load'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:id] = { renderer: :label, with_value: @form_object.id, caption: 'Bin Load' }
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
        id: { renderer: :label,
              with_value: @form_object.id,
              caption: 'Bin Load' },
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
                    maxvalue: AppConst::MAX_BINS_ON_LOAD,
                    minvalue: 1,
                    required: true },
        shipped_at: { renderer: :label, format: :without_timezone_or_seconds },
        shipped: { renderer: :label, as_boolean: true },
        completed_at: { renderer: :label, format: :without_timezone_or_seconds },
        completed: { renderer: :label, as_boolean: true }
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

    def make_progress_step # rubocop:disable Metrics/AbcSize
      id = @options[:id]
      steps = ['Add Products', 'Complete', 'Allocate Bins', 'Ship', 'Finished']

      actions = ['/list/bin_loads',
                 "/raw_materials/dispatch/bin_loads/#{id}/complete",
                 '/list/bin_loads',
                 "/raw_materials/dispatch/bin_loads/#{id}/ship",
                 '/list/bin_loads']
      captions = %w[Close Complete Close Ship Close]

      back_actions = ["/raw_materials/dispatch/bin_loads/#{id}/edit",
                      "/raw_materials/dispatch/bin_loads/#{id}/edit",
                      "/raw_materials/dispatch/bin_loads/#{id}/reopen",
                      "/raw_materials/dispatch/bin_loads/#{id}/unallocate",
                      "/raw_materials/dispatch/bin_loads/#{id}/unship"]
      back_captions = %w[Edit Edit Reopen Unallocate Unship]

      step = 0
      step = 1 if @form_object.products
      step = 2 if @form_object.completed
      step = 3 if @form_object.allocated
      step = 4 if @form_object.shipped

      form_object = @form_object.to_h.merge(steps: steps,
                                            step: step,
                                            action: actions[step],
                                            caption: captions[step],
                                            back_action: back_actions[step],
                                            back_caption: back_captions[step])
      @form_object = OpenStruct.new(form_object)
    end

    def set_repo
      @repo = RawMaterialsApp::BinLoadRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      @depot_repo = MasterfilesApp::DepotRepo.new
    end
  end
end
