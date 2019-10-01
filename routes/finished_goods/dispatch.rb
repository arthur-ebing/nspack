# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'dispatch', 'finished_goods' do |r|
    # VOYAGES_PORTS
    # --------------------------------------------------------------------------
    r.on 'voyage_ports', Integer do |id|
      interactor = FinishedGoodsApp::VoyagePortInteractor.new(current_user, {}, { route_url: request.path }, {})

      # Check for notfound:
      r.on !interactor.exists?(:voyage_ports, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('dispatch', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { FinishedGoods::Dispatch::VoyagePort::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('dispatch', 'read')
          show_partial { FinishedGoods::Dispatch::VoyagePort::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_voyage_port(id, params[:voyage_port])
          if res.success
            row_keys = %i[
              voyage_id
              port_id
              trans_shipment_vessel_id
              ata
              atd
              eta
              etd
              port_code
              trans_shipment_vessel
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { FinishedGoods::Dispatch::VoyagePort::Edit.call(id, form_values: params[:voyage_port], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('dispatch', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_voyage_port(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    # r.on 'voyage_ports' do
    #   interactor = FinishedGoodsApp::VoyagePortInteractor.new(current_user, {}, { route_url: request.path }, {})
    # end

    # VOYAGES
    # --------------------------------------------------------------------------
    r.on 'voyages', Integer do |id|
      interactor = FinishedGoodsApp::VoyageInteractor.new(current_user, {}, { route_url: request.path }, {})

      # Check for notfound:
      r.on !interactor.exists?(:voyages, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('dispatch', 'edit')
        interactor.assert_permission!(:edit, id)
        show_page { FinishedGoods::Dispatch::Voyage::Edit.call(id) }
      end

      r.on 'voyage_ports' do
        interactor = FinishedGoodsApp::VoyagePortInteractor.new(current_user, {}, { route_url: request.path }, {})
        r.on 'new' do    # NEW
          check_auth!('dispatch', 'new')
          show_partial_or_page(r) { FinishedGoods::Dispatch::VoyagePort::New.call(id, remote: fetch?(r)) }
        end
        r.post do        # CREATE
          p params
          res = interactor.create_voyage_port(params[:voyage_port].merge(voyage_id: id))

          if res.success
            row_keys = %i[
              id
              voyage_id
              port_id
              trans_shipment_vessel_id
              ata
              atd
              eta
              etd
              active
              port_code
              trans_shipment_vessel
            ]
            add_grid_row(attrs: select_attributes(res.instance, row_keys),
                         notice: res.message)
          else
            re_show_form(r, res, url: "/finished_goods/dispatch/voyages#{id}/voyage_ports/new") do
              FinishedGoods::Dispatch::VoyagePort::New.call(id,
                                                            form_values: params[:voyage_port],
                                                            form_errors: res.errors,
                                                            remote: fetch?(r))
            end
          end
        end
      end

      r.on 'complete' do
        r.get do
          check_auth!('dispatch', 'edit')
          interactor.assert_permission!(:complete, id)
          show_partial { FinishedGoods::Dispatch::Voyage::Complete.call(id) }
        end

        r.post do
          res = interactor.complete_a_voyage(id, params[:voyage])
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res) { FinishedGoods::Dispatch::Voyage::Complete.call(id, params[:voyage], res.errors) }
          end
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('dispatch', 'read')
          show_page { FinishedGoods::Dispatch::Voyage::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_voyage(id, params[:voyage])
          if res.success
            row_keys = %i[
              vessel_id
              voyage_type_id
              voyage_number
              voyage_code
              year
              completed
              completed_at
              vessel_code
              voyage_type_code
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { FinishedGoods::Dispatch::Voyage::Edit.call(id, form_values: params[:voyage], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('dispatch', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_voyage(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'voyages' do
      interactor = FinishedGoodsApp::VoyageInteractor.new(current_user, {}, { route_url: request.path }, {})
      r.on 'new' do    # NEW
        check_auth!('dispatch', 'new')
        show_partial_or_page(r) { FinishedGoods::Dispatch::Voyage::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_voyage(params[:voyage])
        if res.success
          row_keys = %i[
            id
            vessel_id
            voyage_type_id
            voyage_number
            voyage_code
            year
            completed
            completed_at
            active
            vessel_code
            voyage_type_code
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/finished_goods/dispatch/voyages/new') do
            FinishedGoods::Dispatch::Voyage::New.call(form_values: params[:voyage],
                                                      form_errors: res.errors,
                                                      remote: fetch?(r))
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
