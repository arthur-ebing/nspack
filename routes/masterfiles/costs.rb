# frozen_string_literal: true

class Nspack < Roda
  route 'costs', 'masterfiles' do |r|
    # COST TYPES
    # --------------------------------------------------------------------------
    r.on 'cost_types', Integer do |id|
      interactor = RawMaterialsApp::RmtDeliveryInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:cost_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        show_partial { Masterfiles::Costs::CostType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          # check_auth!('costs', 'read')
          show_partial { Masterfiles::Costs::CostType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_cost_type(id, params[:cost_type])
          if res.success
            update_grid_row(id, changes: { cost_type_code: res.instance[:cost_type_code], cost_unit: res.instance[:cost_unit], description: res.instance[:description] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Costs::CostType::Edit.call(id, form_values: params[:cost_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          res = interactor.delete_cost_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'cost_types' do
      interactor = RawMaterialsApp::RmtDeliveryInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        # check_auth!('costs', 'new')
        show_partial_or_page(r) { Masterfiles::Costs::CostType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_cost_type(params[:cost_type])
        if res.success
          row_keys = %i[
            id
            cost_type_code
            cost_unit
            description
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/costs/cost_types/new') do
            Masterfiles::Costs::CostType::New.call(form_values: params[:cost_type],
                                                   form_errors: res.errors,
                                                   remote: fetch?(r))
          end
        end
      end
    end

    # COSTS
    # --------------------------------------------------------------------------
    r.on 'costs', Integer do |id|
      interactor = RawMaterialsApp::RmtDeliveryInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:costs, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        show_partial { Masterfiles::Costs::Cost::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          show_partial { Masterfiles::Costs::Cost::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_cost(id, params[:cost])
          if res.success
            update_grid_row(id, changes: { cost_type_code: res.instance[:cost_type_code], cost_code: res.instance[:cost_code], cost_type_id: res.instance[:cost_type_id], default_amount: res.instance[:default_amount], description: res.instance[:description] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Costs::Cost::Edit.call(id, form_values: params[:cost], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          res = interactor.delete_cost(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'costs' do
      interactor = RawMaterialsApp::RmtDeliveryInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        show_partial_or_page(r) { Masterfiles::Costs::Cost::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_cost(params[:cost])
        if res.success
          row_keys = %i[
            id
            cost_type_id
            cost_type_code
            cost_code
            default_amount
            description
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/costs/costs/new') do
            Masterfiles::Costs::Cost::New.call(form_values: params[:cost],
                                               form_errors: res.errors,
                                               remote: fetch?(r))
          end
        end
      end
    end
  end
end
