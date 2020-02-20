# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
# rubocop:disable Metrics/ClassLength

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

    # CONTRACT TYPES
    # --------------------------------------------------------------------------
    r.on 'contract_types', Integer do |id|
      interactor = MasterfilesApp::ContractTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:contract_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('hr', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::HumanResources::ContractType::Edit.call(id) }
      end
      r.is do
        r.get do       # SHOW
          check_auth!('hr', 'read')
          show_partial { Masterfiles::HumanResources::ContractType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_contract_type(id, params[:contract_type])
          if res.success
            update_grid_row(id, changes: { code: res.instance[:code], description: res.instance[:description] }, notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::HumanResources::ContractType::Edit.call(id, form_values: params[:contract_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('hr', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_contract_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end
    r.on 'contract_types' do
      interactor = MasterfilesApp::ContractTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('hr', 'new')
        show_partial_or_page(r) { Masterfiles::HumanResources::ContractType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_contract_type(params[:contract_type])
        if res.success
          row_keys = %i[
            id
            code
            description
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/human_resources/contract_types/new') do
            Masterfiles::HumanResources::ContractType::New.call(form_values: params[:contract_type],
                                                                form_errors: res.errors,
                                                                remote: fetch?(r))
          end
        end
      end
    end

    # WAGE LEVELS
    # --------------------------------------------------------------------------
    r.on 'wage_levels', Integer do |id|
      interactor = MasterfilesApp::WageLevelInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:wage_levels, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('hr', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::HumanResources::WageLevel::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('hr', 'read')
          show_partial { Masterfiles::HumanResources::WageLevel::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_wage_level(id, params[:wage_level])
          if res.success
            update_grid_row(id, changes: { wage_level: res.instance[:wage_level], description: res.instance[:description] }, notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::HumanResources::WageLevel::Edit.call(id, form_values: params[:wage_level], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('hr', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_wage_level(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end
    r.on 'wage_levels' do
      interactor = MasterfilesApp::WageLevelInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('hr', 'new')
        show_partial_or_page(r) { Masterfiles::HumanResources::WageLevel::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_wage_level(params[:wage_level])
        if res.success
          row_keys = %i[
            id
            wage_level
            description
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/human_resources/wage_levels/new') do
            Masterfiles::HumanResources::WageLevel::New.call(form_values: params[:wage_level],
                                                             form_errors: res.errors,
                                                             remote: fetch?(r))
          end
        end
      end
    end

    # CONTRACT WORKERS
    # --------------------------------------------------------------------------
    r.on 'contract_workers', Integer do |id|
      interactor = MasterfilesApp::ContractWorkerInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:contract_workers, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('hr', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::HumanResources::ContractWorker::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('hr', 'read')
          show_partial { Masterfiles::HumanResources::ContractWorker::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_contract_worker(id, params[:contract_worker])
          if res.success
            row_keys = %i[
              employment_type_id
              contract_type_id
              wage_level_id
              full_names
              surname
              title
              email
              contact_number
              personnel_number
              start_date
              end_date
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::HumanResources::ContractWorker::Edit.call(id, form_values: params[:contract_worker], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('hr', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_contract_worker(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end
    r.on 'contract_workers' do
      interactor = MasterfilesApp::ContractWorkerInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('hr', 'new')
        show_partial_or_page(r) { Masterfiles::HumanResources::ContractWorker::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_contract_worker(params[:contract_worker])
        if res.success
          row_keys = %i[
            id
            employment_type_id
            contract_type_id
            wage_level_id
            full_names
            surname
            title
            email
            contact_number
            personnel_number
            start_date
            end_date
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/human_resources/contract_workers/new') do
            Masterfiles::HumanResources::ContractWorker::New.call(form_values: params[:contract_worker],
                                                                  form_errors: res.errors,
                                                                  remote: fetch?(r))
          end
        end
      end
    end
    # SHIFT TYPES
    # --------------------------------------------------------------------------
    r.on 'shift_types', Integer do |id|
      interactor = MasterfilesApp::ShiftTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:shift_types, id) do
        handle_not_found(r)
      end

      r.is do
        r.get do       # SHOW
          check_auth!('hr', 'read')
          show_partial { Masterfiles::HumanResources::ShiftType::Show.call(id) }
        end
        r.delete do    # DELETE
          check_auth!('hr', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_shift_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end
    r.on 'shift_types' do
      interactor = MasterfilesApp::ShiftTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'new' do    # NEW
        check_auth!('hr', 'new')
        set_last_grid_url('/list/shift_types', r)
        show_partial_or_page(r) { Masterfiles::HumanResources::ShiftType::New.call(remote: fetch?(r)) }
      end
      r.on 'ph_plant_resource_changed' do
        ph_pr_id = params[:changed_value].empty? ? nil : params[:changed_value]
        options_array = ph_pr_id ? interactor.line_plant_resources(ph_pr_id) : []
        json_replace_select_options('shift_type_line_plant_resource_id', options_array, message: nil, keep_dialog_open: true)
      end
      r.post do        # CREATE
        res = interactor.create_shift_type(params[:shift_type])
        if res.success
          if fetch?(r)
            row_keys = %i[
              id
              employment_type_code
              start_hour
              end_hour
              day_night_or_custom
              shift_type_code
              plant_resource_code
            ]
            add_grid_row(attrs: select_attributes(res.instance, row_keys),
                         notice: res.message)
          else
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          end
        else
          re_show_form(r, res, url: '/masterfiles/human_resources/shift_types/new') do
            Masterfiles::HumanResources::ShiftType::New.call(form_values: params[:shift_type],
                                                             form_errors: res.errors,
                                                             remote: fetch?(r))
          end
        end
      end
    end

    # LINK PERSONNEL IDENTIFIERS
    # --------------------------------------------------------------------------
    r.on 'personnel_identifiers', Integer do |id|
      interactor = MasterfilesApp::ContractWorkerInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'link_contract_worker' do
        r.get do
          check_auth!('hr', 'edit')
          # interactor.assert_permission!(:edit, id)
          show_partial { Masterfiles::HumanResources::PersonnelIdentifier::LinkWorker.call(id) }
        end

        r.patch do
          res = interactor.link_to_personnel_identifier(id, params[:personnel_identifier])
          if res.success
            row_keys = %i[
              contract_worker
              in_use
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::HumanResources::PersonnelIdentifier::LinkWorker.call(id, form_values: params[:personnel_identifier], form_errors: res.errors) }
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
# rubocop:enable Metrics/ClassLength
