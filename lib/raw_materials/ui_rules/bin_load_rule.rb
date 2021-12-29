# frozen_string_literal: true

module UiRules
  class BinLoadRule < Base
    def generate_rules
      set_repo
      make_form_object
      apply_form_values

      add_progress_step
      add_controls

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
      shipped_at_renderer = @mode == :ship ? { renderer: :datetime } : { renderer: :label }
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
        qty_bins: { renderer: :integer,
                    maxvalue: AppConst::CR_FG.max_bin_count_for_load?,
                    minvalue: 1,
                    required: true },
        shipped_at: shipped_at_renderer.merge(format: :without_timezone_or_seconds),
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

      @form_object = OpenStruct.new(@repo.find_bin_load_flat(@options[:id]).to_h)
      @form_object[:shipped_at] ||= Time.now if @mode == :ship
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

    def add_progress_step
      steps = ['Add Products', 'Complete', 'Allocate Bins', 'Ship', 'Finished']

      step = 0
      step = 1 if @form_object.products
      step = 2 if @form_object.completed
      step = 3 if @form_object.allocated
      step = 4 if @form_object.shipped

      @form_object = OpenStruct.new(@form_object.to_h.merge(steps: steps, step: step))
    end

    def add_controls # rubocop:disable Metrics/AbcSize
      id = @options[:id]
      edit = { control_type: :link,
               style: :action_button,
               text: 'Edit',
               url: "/raw_materials/dispatch/bin_loads/#{id}/edit",
               prompt: 'Are you sure, you want to edit this load?',
               visible: !@form_object.completed,
               icon: :edit }
      delete = { control_type: :link,
                 style: :action_button,
                 text: 'Delete',
                 url: "/raw_materials/dispatch/bin_loads/#{id}/delete",
                 prompt: 'Are you sure, you want to delete this load?',
                 icon: :checkoff }
      product = { control_type: :link,
                  style: :action_button,
                  text: 'Add Product',
                  url: "/raw_materials/dispatch/bin_loads/#{id}/bin_load_products/new",
                  grid_id: 'bin_load_products',
                  icon: :checkon,
                  behaviour: :popup }
      complete = { control_type: :link,
                   style: :action_button,
                   text: 'Complete adding products',
                   url: "/raw_materials/dispatch/bin_loads/#{id}/complete",
                   icon: :checkon }
      reopen = { control_type: :link,
                 style: :action_button,
                 text: 'Reopen',
                 url: "/raw_materials/dispatch/bin_loads/#{id}/reopen",
                 prompt: 'Are you sure, you want to reopen this load?',
                 icon: :back }
      unallocate = { control_type: :link,
                     style: :action_button,
                     text: 'Unallocate',
                     url: "/raw_materials/dispatch/bin_loads/#{id}/unallocate",
                     prompt: 'Are you sure, you want to remove the pallets from this load?',
                     icon: :back }
      ship = { control_type: :link,
               style: :action_button,
               text: 'Ship',
               url: "/raw_materials/dispatch/bin_loads/#{id}/ship",
               icon: :checkon }
      unship = { control_type: :link,
                 style: :action_button,
                 text: 'Unship',
                 url: "/raw_materials/dispatch/bin_loads/#{id}/unship",
                 prompt: 'Are you sure, you want to unship this load?',
                 icon: :back }

      case @form_object.step
      when 0
        progress_controls = [product]
        instance_controls = [edit, delete]
      when 1
        progress_controls = [product, complete]
        instance_controls = [edit]
      when 2
        progress_controls = [reopen]
        instance_controls = [edit]
      when 3
        progress_controls = [unallocate, ship]
        instance_controls = [edit]
      when 4
        progress_controls = [unship]
        instance_controls = [edit]
      else
        progress_controls = []
        instance_controls = []
      end

      @form_object = OpenStruct.new(@form_object.to_h.merge(progress_controls: progress_controls, instance_controls: instance_controls))
    end

    def set_repo
      @repo = RawMaterialsApp::BinLoadRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      @depot_repo = MasterfilesApp::DepotRepo.new
    end
  end
end
