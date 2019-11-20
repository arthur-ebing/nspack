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

    r.on 'reworks_runs' do # rubocop:disable Metrics/BlockLength
      r.on 'single_pallet_edit' do
        check_auth!('reworks', 'new')
        reworks_run_type_id = get_reworks_run_type_id(AppConst::RUN_TYPE_SINGLE_PALLET_EDIT)
        r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{reworks_run_type_id}"
      end

      r.on 'batch_pallet_edit' do
        check_auth!('reworks', 'new')
        reworks_run_type_id = get_reworks_run_type_id(AppConst::RUN_TYPE_BATCH_PALLET_EDIT)
        r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{reworks_run_type_id}"
      end

      r.on 'scrap_pallet' do
        check_auth!('reworks', 'new')
        reworks_run_type_id = get_reworks_run_type_id(AppConst::RUN_TYPE_SCRAP_PALLET)
        r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{reworks_run_type_id}"
      end

      r.on 'unscrap_pallet' do
        check_auth!('reworks', 'new')
        reworks_run_type_id = get_reworks_run_type_id(AppConst::RUN_TYPE_UNSCRAP_PALLET)
        r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{reworks_run_type_id}"
      end

      r.on 'repack' do
        check_auth!('reworks', 'new')
        reworks_run_type_id = get_reworks_run_type_id(AppConst::RUN_TYPE_REPACK)
        r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{reworks_run_type_id}"
      end

      r.on 'buildup' do
        check_auth!('reworks', 'new')
        reworks_run_type_id = get_reworks_run_type_id(AppConst::RUN_TYPE_BUILDUP)
        r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{reworks_run_type_id}"
      end

      r.on 'tip_bins' do
        check_auth!('reworks', 'new')
        reworks_run_type_id = get_reworks_run_type_id(AppConst::RUN_TYPE_TIP_BINS)
        r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{reworks_run_type_id}"
      end
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
    end

    r.on 'pallet_sequences', Integer do |id| # rubocop:disable Metrics/BlockLength
      reworks_run_type_id = retrieve_from_local_store(:reworks_run_type_id)
      store_locally(:reworks_run_type_id, reworks_run_type_id)

      r.on 'edit_reworks_pallet_sequence' do # Edit pallet sequence
        product_setup_id = ProductionApp::ReworksRepo.new.find_product_setup_id(id)
        r.get do
          show_partial_or_page(r) { Production::Reworks::ReworksRun::EditPalletSequence.call(id, product_setup_id, back_url: back_button_url) }
        end
        r.patch do
          res = interactor.update_reworks_run_pallet_sequence(params[:product_setup])
          if res.success
            show_partial_or_page(r) { Production::Reworks::ReworksRun::ShowPalletSequenceChanges.call(id, res.instance, back_url: back_button_url) }
          else
            re_show_form(r, res, url: "/production/reworks/pallet_sequences/#{id}/edit_reworks_pallet_sequence") do
              Production::Reworks::ReworksRun::EditPalletSequence.call(id,
                                                                       product_setup_id,
                                                                       back_url: "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet",
                                                                       form_values: params[:product_setup],
                                                                       form_errors: res.errors)
            end
          end
        end
      end

      r.on 'accept_pallet_sequence_changes' do
        res = interactor.update_pallet_sequence_record(id, reworks_run_type_id, params)
        if res.success
          flash[:notice] = res.message
          r.redirect "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet"
        end
      end

      r.on 'reject_pallet_sequence_changes' do
        res = interactor.update_pallet_sequence_record(id, reworks_run_type_id, params)
        if res.success
          flash[:notice] = res.message
          r.redirect "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet"
        end
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
          update_grid_row(id, changes: { seq_carton_qty: res.instance[:seq_carton_qty], carton_quantity: res.instance[:carton_quantity], sequence_nett_weight: res.instance[:sequence_nett_weight] }, notice: res.message)
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
