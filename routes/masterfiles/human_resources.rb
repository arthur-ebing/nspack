# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

class Nspack < Roda
  route 'human_resources', 'masterfiles' do |r|
    # EMPLOYMENT TYPES
    # --------------------------------------------------------------------------
    r.on 'employment_types', Integer do |id|
      interactor = MasterfilesApp::EmploymentTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:employment_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('hr', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::HumanResources::EmploymentType::Edit.call(id) }
      end
      r.is do
        r.get do       # SHOW
          check_auth!('hr', 'read')
          show_partial { Masterfiles::HumanResources::EmploymentType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_employment_type(id, params[:employment_type])
          if res.success
            update_grid_row(id, changes: { code: res.instance[:code] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::HumanResources::EmploymentType::Edit.call(id, form_values: params[:employment_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('hr', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_employment_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'employment_types' do
      interactor = MasterfilesApp::EmploymentTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('hr', 'new')
        show_partial_or_page(r) { Masterfiles::HumanResources::EmploymentType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_employment_type(params[:employment_type])
        if res.success
          row_keys = %i[
            id
            code
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/human_resources/employment_types/new') do
            Masterfiles::HumanResources::EmploymentType::New.call(form_values: params[:employment_type],
                                                                  form_errors: res.errors,
                                                                  remote: fetch?(r))
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
