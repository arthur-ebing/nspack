# frozen_string_literal: true

class Nspack < Roda
  route 'locations', 'raw_materials' do |r|
    # CA TREATMENT LOCATIONS
    # --------------------------------------------------------------------------
    r.on 'ca_treatment', Integer do |id|
      interactor = RawMaterialsApp::LocationInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:locations, id) do
        handle_not_found(r)
      end

      r.on 'apply_status' do
        r.get do
          check_auth!('locations', 'edit')
          interactor.assert_permission!(:edit, id)
          show_partial { RawMaterials::Locations::Location::ApplyStatus.call(id) }
        end

        r.post do
          params.inspect
          res = interactor.apply_status(id, params[:location])
          if res.success
            update_grid_row(id, changes: { status: res.instance.current_status }, notice: res.message)
          else
            re_show_form(r, res) { RawMaterials::Locations::Location::ApplyStatus.call(id, form_values: params[:location], form_errors: res.errors) }
          end
        end
      end
    end

    r.on 'ca_treatments' do
      r.on 'rmt_bin', Integer do |id|
        show_partial_or_page(r) { RawMaterials::Locations::RmtBin::ColdstoreEvents.call(id, remote: fetch?(r)) }
      end
    end
  end
end
