# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable ClassLength
  route 'finished_goods', 'rmd' do |r|
    r.on 'pallet_movements' do
      interactor = FinishedGoodsApp::PalletMovementsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # --------------------------------------------------------------------------
      # MOVE PALLET
      # --------------------------------------------------------------------------
      r.on 'move_pallet' do
        r.get do
          pallet = {}
          notice = retrieve_from_local_store(:flash_notice)
          error = retrieve_from_local_store(:error)
          pallet.merge!(error_message: error.message) unless error.nil?
          pallet.merge!(errors: error.errors) if !error.nil? && !error.errors.nil_or_empty?

          form = Crossbeams::RMDForm.new(pallet,
                                         form_name: :pallet,
                                         notes: notice,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Scan Pallet And Location',
                                         action: '/rmd/finished_goods/pallet_movements/move_pallet',
                                         button_caption: 'Submit')

          form.add_field(:pallet_number, 'Pallet Number', scan: 'key248_all', scan_type: :pallet_number, submit_form: false, data_type: :number, required: true)
          form.add_field(:location, 'Location', scan: 'key248_all', scan_type: :location, submit_form: false, required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.move_pallet(params[:pallet][:pallet_number], params[:pallet][:location], !params[:pallet][:location_scan_field].nil_or_empty?)

          if res.success
            store_locally(:flash_notice, res.message)
          else
            store_locally(:error, res)
          end
          r.redirect('/rmd/finished_goods/pallet_movements/move_pallet')
        end
      end
    end
  end
end
