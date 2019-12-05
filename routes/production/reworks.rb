# frozen_string_literal: true

class Nspack < Roda # rubocop:disable ClassLength
  route 'reworks', 'production' do |r| # rubocop:disable Metrics/BlockLength
    # REWORKS RUNS
    # --------------------------------------------------------------------------

    interactor = ProductionApp::ReworksRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

    r.on 'reworks_runs', Integer do |id|
      # Check for notfound:
      r.on !interactor.exists?(:reworks_runs, id) do
        handle_not_found(r)
      end

      r.is do
        r.get do       # SHOW
          check_auth!('reworks', 'read')
          show_partial { Production::Reworks::ReworksRun::Show.call(id) }
        end
      end
    end

    r.on 'reworks_runs' do
      r.on 'single_pallet_edit' do
        check_auth!('reworks', 'new')
        reworks_run_type_id = get_reworks_run_type_id(AppConst::RUN_TYPE_SINGLE_PALLET_EDIT)
        raise Crossbeams::FrameworkError, 'Run type does not exist. Perhaps required seeds were not run. Please contact support.' if reworks_run_type_id.nil?

        r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{reworks_run_type_id}"
      end

      # r.on 'batch_pallet_edit' do
      #   check_auth!('reworks', 'new')
      #   reworks_run_type_id = get_reworks_run_type_id(AppConst::RUN_TYPE_BATCH_PALLET_EDIT)
      #   raise Crossbeams::FrameworkError, 'Run type does not exist. Perhaps required seeds were not run. Please contact support.' if reworks_run_type_id.nil?
      #
      #   r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{reworks_run_type_id}"
      # end

      r.on 'scrap_pallet' do
        check_auth!('reworks', 'new')
        reworks_run_type_id = get_reworks_run_type_id(AppConst::RUN_TYPE_SCRAP_PALLET)
        raise Crossbeams::FrameworkError, 'Run type does not exist. Perhaps required seeds were not run. Please contact support.' if reworks_run_type_id.nil?

        r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{reworks_run_type_id}"
      end

      r.on 'unscrap_pallet' do
        check_auth!('reworks', 'new')
        reworks_run_type_id = get_reworks_run_type_id(AppConst::RUN_TYPE_UNSCRAP_PALLET)
        raise Crossbeams::FrameworkError, 'Run type does not exist. Perhaps required seeds were not run. Please contact support.' if reworks_run_type_id.nil?

        r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{reworks_run_type_id}"
      end

      # r.on 'repack' do
      #   check_auth!('reworks', 'new')
      #   reworks_run_type_id = get_reworks_run_type_id(AppConst::RUN_TYPE_REPACK)
      #   raise Crossbeams::FrameworkError, 'Run type does not exist. Perhaps required seeds were not run. Please contact support.' if reworks_run_type_id.nil?
      #
      #   r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{reworks_run_type_id}"
      # end
      #
      # r.on 'buildup' do
      #   check_auth!('reworks', 'new')
      #   reworks_run_type_id = get_reworks_run_type_id(AppConst::RUN_TYPE_BUILDUP)
      #   raise Crossbeams::FrameworkError, 'Run type does not exist. Perhaps required seeds were not run. Please contact support.' if reworks_run_type_id.nil?
      #
      #   r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{reworks_run_type_id}"
      # end
      #
      # r.on 'tip_bins' do
      #   check_auth!('reworks', 'new')
      #   reworks_run_type_id = get_reworks_run_type_id(AppConst::RUN_TYPE_TIP_BINS)
      #   raise Crossbeams::FrameworkError, 'Run type does not exist. Perhaps required seeds were not run. Please contact support.' if reworks_run_type_id.nil?
      #
      #   r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{reworks_run_type_id}"
      # end
    end

    r.on 'reworks_run_types', Integer do |id| # rubocop:disable Metrics/BlockLength
      store_locally(:reworks_run_type_id, id)

      r.on 'reworks_runs' do # rubocop:disable Metrics/BlockLength
        r.on 'new' do
          r.get do
            store_locally(:list_url, back_button_url)
            check_auth!('reworks', 'new')
            show_partial_or_page(r) { Production::Reworks::ReworksRun::New.call(id, remote: fetch?(r)) }
          end
          r.post do
            res = interactor.create_reworks_run(id, params[:reworks_run])
            if res.success
              if res.instance[:make_changes]
                redirect_via_json "/production/reworks/reworks_run_types/#{id}/pallets/#{res.instance[:pallets_selected].join(',')}/edit_pallet"
              else
                flash[:notice] = res.message
                redirect_via_json(retrieve_from_local_store(:list_url))
              end
            else
              pallets_selected = interactor.resolve_selected_pallet_numbers(res.instance[:pallets_selected])
              params[:reworks_run][:pallets_selected] = pallets_selected
              re_show_form(r, res) do
                Production::Reworks::ReworksRun::New.call(id,
                                                          form_values: params[:reworks_run],
                                                          form_errors: res.errors)
              end
            end
          end
        end

        r.on 'multiselect_reworks_run_pallets' do
          check_auth!('reworks', 'new')
          res = interactor.resolve_pallet_numbers_from_multiselect(id, multiselect_grid_choices(params))
          if res.success
            show_partial_or_page(r) { Production::Reworks::ReworksRun::New.call(id, form_values: res.instance) }
          else
            re_show_form(r, res) do
              Production::Reworks::ReworksRun::New.call(id,
                                                        form_values: params[:reworks_run_pallet],
                                                        form_errors: res.errors)
            end
          end
        end
      end

      r.on 'pallets', String do |pallet_number|
        r.on 'edit_pallet'  do
          pallet_numbers = pallet_number.split(',')
          r.get do
            if pallet_numbers.length == 1
              show_partial_or_page(r) do
                Production::Reworks::ReworksRun::EditPallet.call(id,
                                                                 pallet_numbers.first,
                                                                 back_url: "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{id}")
              end
            else
              show_partial_or_page(r) { Production::Reworks::ReworksRun::SelectPalletSequence.call(id, pallet_numbers) }
            end
          end
        end
      end
    end

    r.on 'pallets', String do |pallet_number| # rubocop:disable Metrics/BlockLength
      reworks_run_type_id = retrieve_from_local_store(:reworks_run_type_id)
      store_locally(:reworks_run_type_id, reworks_run_type_id)

      r.on 'pallet_shipping_details' do
        r.get do
          show_partial_or_page(r) { Production::Reworks::ReworksRun::ShowPalletShippingDetails.call(pallet_number) }
        end
      end

      r.on 'select_pallet_sequence' do
        r.get do
          redirect_via_json "/production/reworks/reworks_run_types/#{id}/pallets/#{pallet_number.join(',')}/edit_pallet"
        end
      end

      r.on 'print_reworks_pallet_label' do # Print Pallet Label
        r.get do
          show_partial { Production::Reworks::ReworksRun::PrintReworksLabel.call(nil, pallet_number, false) }
        end
        r.post do
          res = interactor.print_reworks_pallet_label(pallet_number, params[:reworks_run_print])
          if res.success
            flash[:notice] = res.message
            r.redirect(back_button_url)
          else
            re_show_form(r, res) do
              Production::Reworks::ReworksRun::PrintReworksLabel.call(nil,
                                                                      pallet_number,
                                                                      false,
                                                                      form_values: params[:reworks_run_print],
                                                                      form_errors: res.errors)
            end
          end
        end
      end

      r.on 'edit_carton_quantities' do
        r.get do
          show_partial_or_page(r) { Production::Reworks::ReworksRun::EditSequenceQuantities.call(pallet_number) }
        end
      end

      r.on 'set_gross_weight' do
        r.get do
          show_partial { Production::Reworks::ReworksRun::SetPalletGrossWeight.call(pallet_number, reworks_run_type_id) }
        end
        r.post do
          res = interactor.update_pallet_gross_weight(params[:reworks_run_pallet])
          if res.success
            flash[:notice] = res.message
            redirect_via_json "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet"
          else
            re_show_form(r, res) do
              Production::Reworks::ReworksRun::SetPalletGrossWeight.call(pallet_number,
                                                                         reworks_run_type_id,
                                                                         form_values: params[:reworks_run_pallet],
                                                                         form_errors: res.errors)
            end
          end
        end
      end
    end

    r.on 'pallet_sequences', Integer do |id| # rubocop:disable Metrics/BlockLength
      reworks_run_type_id = retrieve_from_local_store(:reworks_run_type_id)
      store_locally(:reworks_run_type_id, reworks_run_type_id)

      r.on 'edit_reworks_pallet_sequence' do # Edit pallet sequence
        r.get do
          show_partial_or_page(r) { Production::Reworks::ReworksRun::EditPalletSequence.call(id, back_url: back_button_url) }
        end
        r.patch do
          res = interactor.update_reworks_run_pallet_sequence(params[:reworks_run_sequence])
          if res.success
            store_locally(:reworks_run_sequence_changes, res.instance)
            show_partial_or_page(r) { Production::Reworks::ReworksRun::ShowPalletSequenceChanges.call(id, res.instance, back_url: back_button_url) }
          else
            re_show_form(r, res, url: "/production/reworks/pallet_sequences/#{id}/edit_reworks_pallet_sequence") do
              Production::Reworks::ReworksRun::EditPalletSequence.call(id,
                                                                       back_url: "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet",
                                                                       form_values: params[:reworks_run_sequence],
                                                                       form_errors: res.errors)
            end
          end
        end
      end

      r.on 'accept_pallet_sequence_changes' do
        params = retrieve_from_local_store(:reworks_run_sequence_changes)
        res = interactor.update_pallet_sequence_record(id, reworks_run_type_id, params)
        if res.success
          flash[:notice] = res.message
          r.redirect "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet"
        end
      end

      r.on 'reject_pallet_sequence_changes' do
        res = interactor.reject_pallet_sequence_changes(id)
        flash[:notice] = 'Changes to Pallet sequence has be discarded'
        r.redirect "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet"
      end

      r.on 'edit_reworks_production_run' do # Edit pallet sequence
        production_run_id = ProductionApp::ReworksRepo.new.find_production_run_id(id)
        r.get do
          show_partial_or_page(r) { Production::Reworks::ReworksRun::EditProductionRun.call(id, production_run_id, reworks_run_type_id) }
        end
        r.post do
          res = interactor.update_reworks_production_run(params[:reworks_run_sequence])
          if res.success
            flash[:notice] = res.message
            redirect_via_json "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet"
          else
            re_show_form(r, res) do
              Production::Reworks::ReworksRun::EditProductionRun.call(id,
                                                                      production_run_id,
                                                                      reworks_run_type_id,
                                                                      form_values: params[:reworks_run_sequence],
                                                                      form_errors: res.errors)
            end
          end
        end
      end

      r.on 'production_run_changed' do
        production_run_details = if params[:changed_value].blank?
                                   []
                                 else
                                   interactor.production_run_details_table(params[:changed_value])
                                 end
        json_actions([OpenStruct.new(type: :replace_inner_html,
                                     dom_id: 'reworks_run_pallet_production_run_details',
                                     value: production_run_details)])
      end

      r.on 'edit_reworks_farm_details' do # Edit pallet sequence
        r.get do
          show_partial_or_page(r) { Production::Reworks::ReworksRun::EditFarmDetails.call(id, reworks_run_type_id) }
        end
        r.post do
          res = interactor.update_reworks_farm_details(params[:reworks_run_sequence])
          if res.success
            flash[:notice] = res.message
            redirect_via_json "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet"
          else
            re_show_form(r, res) do
              Production::Reworks::ReworksRun::EditFarmDetails.call(id,
                                                                    reworks_run_type_id,
                                                                    form_values: params[:reworks_run_sequence],
                                                                    form_errors: res.errors)
            end
          end
        end
      end

      r.on 'farm_changed' do
        pucs = if params[:changed_value].blank?
                 []
               else
                 interactor.farm_pucs(params[:changed_value])
               end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_puc_id',
                                     options_array: pucs),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_orchard_id',
                                     options_array: []),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_cultivar_id',
                                     options_array: [])])
      end

      r.on 'puc_changed' do
        orchards = if params[:changed_value].blank? || params[:reworks_run_sequence_farm_id].blank?
                     []
                   else
                     interactor.puc_orchards(params[:reworks_run_sequence_farm_id], params[:changed_value])
                   end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_orchard_id',
                                     options_array: orchards),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_cultivar_id',
                                     options_array: [])])
      end

      r.on 'orchard_changed' do
        cultivars = if params[:changed_value].blank? || params[:reworks_run_sequence_cultivar_group_id].blank?
                      []
                    else
                      interactor.orchard_cultivars(params[:reworks_run_sequence_cultivar_group_id], params[:changed_value])
                    end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_cultivar_id',
                                     options_array: cultivars)])
      end

      r.on 'basic_pack_code_changed' do
        std_fruit_size_count_id = params[:reworks_run_sequence_std_fruit_size_count_id]
        if std_fruit_size_count_id.blank? || params[:changed_value].blank?
          actual_counts = []
        else
          basic_pack_code_id = params[:changed_value]
          actual_counts = interactor.for_select_basic_pack_actual_counts(basic_pack_code_id, std_fruit_size_count_id)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_fruit_actual_counts_for_pack_id',
                                     options_array: actual_counts)])
      end

      r.on 'actual_count_changed' do
        if params[:changed_value].blank?
          standard_pack_codes = []
          size_references = []
        else
          fruit_actual_counts_for_pack_id = params[:changed_value]
          actual_count = MasterfilesApp::FruitSizeRepo.new.find_fruit_actual_counts_for_pack(fruit_actual_counts_for_pack_id)
          standard_pack_codes = interactor.for_select_actual_count_standard_pack_codes(actual_count.standard_pack_code_ids)
          size_references = interactor.for_select_actual_count_size_references(actual_count.size_reference_ids)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_standard_pack_code_id',
                                     options_array: standard_pack_codes),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_fruit_size_reference_id',
                                     options_array: size_references)])
      end

      r.on 'packed_tm_group_changed' do
        if params[:changed_value].blank? || params[:reworks_run_sequence_marketing_variety_id].blank?
          customer_variety_varieties = []
        else
          packed_tm_group_id = params[:changed_value]
          marketing_variety_id = params[:reworks_run_sequence_marketing_variety_id]
          customer_variety_varieties = interactor.for_select_customer_variety_varieties(packed_tm_group_id, marketing_variety_id)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_customer_variety_variety_id',
                                     options_array: customer_variety_varieties)])
      end

      r.on 'pallet_stack_type_changed' do
        pallet_base_id = params[:reworks_run_sequence_pallet_base_id]
        if pallet_base_id.blank? || params[:changed_value].blank?
          pallet_formats = []
        else
          pallet_stack_type_id = params[:changed_value]
          pallet_formats = interactor.for_select_pallet_formats(pallet_base_id, pallet_stack_type_id)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_pallet_format_id',
                                     options_array: pallet_formats)])
      end

      r.on 'pallet_format_changed' do
        basic_pack_code_id = params[:reworks_run_sequence_basic_pack_code_id]
        if basic_pack_code_id.blank? || params[:changed_value].blank?
          cartons_per_pallets = []
        else
          pallet_format_id = params[:changed_value]
          cartons_per_pallets = interactor.for_select_cartons_per_pallets(pallet_format_id, basic_pack_code_id)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_cartons_per_pallet_id',
                                     options_array: cartons_per_pallets)])
      end

      r.on 'pm_type_changed' do
        pm_subtypes = if params[:changed_value].blank?
                        []
                      else
                        interactor.for_select_pm_type_pm_subtypes(params[:changed_value])
                      end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_pm_subtype_id',
                                     options_array: pm_subtypes)])
      end

      r.on 'pm_subtype_changed' do
        pm_boms = if params[:changed_value].blank?
                    []
                  else
                    interactor.for_select_pm_subtype_pm_boms(params[:changed_value])
                  end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_pm_bom_id',
                                     options_array: pm_boms)])
      end

      r.on 'pm_bom_changed' do
        if params[:changed_value].blank?
          pm_bom_products = []
          pm_bom = nil
        else
          pm_bom_id = params[:changed_value]
          pm_bom = MasterfilesApp::BomsRepo.new.find_pm_bom(pm_bom_id)
          pm_bom_products = interactor.pm_bom_products_table(pm_bom_id)
        end
        json_actions([OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'reworks_run_sequence_description',
                                     value: pm_bom&.description),
                      OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'reworks_run_sequence_erp_bom_code',
                                     value: pm_bom&.erp_bom_code),
                      OpenStruct.new(type: :replace_inner_html,
                                     dom_id: 'reworks_run_sequence_pm_boms_products',
                                     value: pm_bom_products)])
      end

      r.on 'print_reworks_carton_label' do # Print Carton Label
        r.get do
          show_partial { Production::Reworks::ReworksRun::PrintReworksLabel.call(id, nil, true) }
        end
        r.post do
          res = interactor.print_reworks_carton_label(id, params[:reworks_run_print])
          if res.success
            flash[:notice] = res.message
            r.redirect(back_button_url)
          else
            re_show_form(r, res) do
              Production::Reworks::ReworksRun::PrintReworksLabel.call(id,
                                                                      nil,
                                                                      true,
                                                                      form_values: params[:reworks_run_print],
                                                                      form_errors: res.errors)
            end
          end
        end
      end

      r.on 'clone_sequence' do
        check_auth!('reworks', 'edit')
        res = interactor.clone_pallet_sequence(id, reworks_run_type_id)
        flash[:notice] = res.message
        r.redirect "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet"
      end

      r.on 'remove_sequence' do
        check_auth!('reworks', 'delete')
        res = interactor.remove_pallet_sequence(id, reworks_run_type_id)
        flash[:notice] = res.message
        redirect_via_json "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet"
      end

      r.on 'edit_carton_quantities' do
        res = interactor.edit_carton_quantities(id, reworks_run_type_id, params)
        if res.success
          update_grid_row(id, changes: { carton_quantity: res.instance[:carton_quantity], pallet_carton_quantity: res.instance[:pallet_carton_quantity], sequence_nett_weight: res.instance[:sequence_nett_weight] }, notice: res.message)
        else
          undo_grid_inline_edit(message: res.message, message_type: :warning)
        end
      end
    end
  end
  def get_reworks_run_type_id(run_type)
    repo = ProductionApp::ReworksRepo.new
    repo.find_reworks_run_type_from_run_type(run_type)
  end
end
