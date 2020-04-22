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
  end
end
