# frozen_string_literal: true

class Nspack < Roda
  route 'actions', 'edi' do |r|
    interactor = EdiApp::ActionsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

    # UPLOAD
    # --------------------------------------------------------------------------
    r.on 'send_ps' do
      r.get do
        show_partial_or_page(r) { Edi::Actions::Send::PS.call }
      end

      r.post do
        res = interactor.send_ps(params[:ps])
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        r.redirect '/edi/actions/send_ps'
      end
    end

    # RE-RECEIVE
    # --------------------------------------------------------------------------
    r.on 're_receive_file' do
      res = interactor.re_receive_file(params[:file_path])
      flash[:notice] = res.message
      redirect_to_last_grid(r)
    end
    r.on 're_receive_in_transaction', Integer do |id|
      res = interactor.re_receive_file_from_transaction(id)
      flash[:notice] = res.message
      redirect_to_last_grid(r)
    end

    r.on 'create_manual_intake' do
      id = interactor.create_manual_intake
      r.redirect "/edi/actions/edit_manual_intake/#{id}"
    end

    r.on 'edit_manual_intake', Integer do |id|
      r.on 'inline_edit', Integer do |index|
        p params
        res = interactor.update_op_recordset(id, index, params)
        show_json_notice(res.message)
      end

      r.on 'grid' do
        interactor.manual_intake_items_grid(id)
      rescue StandardError => e
        show_json_exception(e)
      end

      r.on 'add_row' do
        res = interactor.add_manual_intake_row(id)
        if res.success
          r.redirect "/edi/actions/edit_manual_intake/#{id}"
          # row_keys = %i[
          #   id
          #   record_type
          #   sscc
          #   seq_no
          #   farm
          #   mark
          #   pack
          #   grade
          #   orgzn
          # ]
          # add_grid_row(attrs: select_attributes(res.instance, row_keys),
          #              notice: res.message)
        else
          show_json_error(res.message)
        end
      end

      r.get do
        show_partial_or_page(r) { Edi::Actions::Edit::ManualIntake.call(id) }
      end

      r.patch do
        res = interactor.update_edi_manual_intake_header(id, params[:manual_intake])
        if res.success
          redirect_to_last_grid(r)
        else
          re_show_form(r, res) { Edi::Actions::Edit::ManualIntake.call(id, form_values: params[:manual_intake], form_errors: res.errors) }
        end
      end
    end

    r.on 'process_manual_transaction', Integer do |id|
      res = interactor.process_manual_transaction(id)
      if res.success
        flash[:notice] = res.message
      else
        flash[:error] = res.message
      end
      redirect_to_last_grid(r)
    end
  end
end
