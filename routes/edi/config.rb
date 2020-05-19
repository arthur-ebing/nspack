# frozen_string_literal: true

class Nspack < Roda # rubocop:disable  Metrics/ClassLength
  route 'config', 'edi' do |r| # rubocop:disable Metrics/BlockLength
    interactor = EdiApp::EdiOutRuleInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

    # EDI OUT RULES
    # --------------------------------------------------------------------------
    r.on 'edi_out_rules', Integer do |id| # rubocop:disable Metrics/BlockLength
      r.on 'edit' do   # EDIT
        check_auth!('config', 'edit')
        interactor.assert_permission!(:edit, id)

        show_partial_or_page(r) { Edi::Config::EdiOutRule::Edit.call(id) }
      end

      r.is do # rubocop:disable Metrics/BlockLength
        r.get do       # SHOW
          check_auth!('config', 'read')
          show_partial { Edi::Config::EdiOutRule::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_edi_out_rule(id, params[:edi_out_rule])
          if res.success
            # flash[:notice] = res.message
            show_partial_or_page(r) { Edi::Config::EdiOutRule::Edit.call(id) }
          else
            re_show_form(r, res, url: "/edi/config/edi_out_rules/#{id}/edit") do
              Edi::Config::EdiOutRule::Edit.call(id,
                                                 form_values: params[:edi_out_rule],
                                                 form_errors: res.errors)
            end
          end
        end
        r.delete do    # DELETE
          check_auth!('config', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_edi_out_rule(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'edi_out_rules' do # rubocop:disable Metrics/BlockLength
      r.get do
        check_auth!('config', 'new')
        show_partial_or_page(r) { Edi::Config::EdiOutRule::New.call(remote: fetch?(r)) }
      end

      r.post do
        params[:edi_out_rule].delete_if { |_k, v| v.nil_or_empty? }
        if params[:edi_out_rule][:flow_type].nil_or_empty?
          res = OpenStruct.new(message: 'Validation Error', errors: { flow_type: ['must be filled'] })
          re_show_form(r, res, url: '/edi/config/edi_out_rules') do
            Edi::Config::EdiOutRule::New.call(form_values: params[:edi_out_rule],
                                              form_errors: res.errors,
                                              remote: fetch?(r))
          end
        else
          res = interactor.create_edi_out_rule(params[:edi_out_rule])
          if res.success
            show_partial_or_page(r) { Edi::Config::EdiOutRule::Edit.call(res.instance[:id]) }
          else
            re_show_form(r, res, url: '/edi/config/edi_out_rules') do
              Edi::Config::EdiOutRule::New.call(form_values: params[:edi_out_rule],
                                                form_errors: res.errors,
                                                remote: fetch?(r))
            end
          end
        end
      end
    end

    r.on 'flow_type_changed' do # rubocop:disable Metrics/BlockLength
      unless params[:changed_value].nil_or_empty?
        repo = EdiApp::EdiOutRepo.new
        rules_template = AppConst::EDI_OUT_RULES_TEMPLATE
        destinations = repo.destinations_for_flow(params[:changed_value])
        party_role_default_destination_screen = (destinations.size == 1 && destinations[0] == AppConst::PARTY_ROLE_DESTINATION_TYPE)
        actions = [OpenStruct.new(type: :replace_select_options,
                                  dom_id: 'edi_out_rule_destination_type',
                                  options_array: destinations),
                   OpenStruct.new(type: destinations.nil_or_empty? || party_role_default_destination_screen ? :hide_element : :show_element,
                                  dom_id: 'edi_out_rule_destination_type_field_wrapper'),
                   OpenStruct.new(type: :replace_select_options,
                                  dom_id: 'edi_out_rule_depot_id',
                                  options_array: []),
                   OpenStruct.new(type: repo.can_transform_for_depot?(params[:changed_value]) ? :show_element : :hide_element,
                                  dom_id: 'edi_out_rule_depot_id_field_wrapper'),
                   OpenStruct.new(type: :replace_select_options,
                                  dom_id: 'edi_out_rule_role_id',
                                  options_array: party_role_default_destination_screen ? rules_template[params[:changed_value]][:roles].to_a : []),
                   OpenStruct.new(type: repo.can_transform_for_party?(params[:changed_value]) ? :show_element : :hide_element,
                                  dom_id: 'edi_out_rule_role_id_field_wrapper'),
                   OpenStruct.new(type: :replace_select_options,
                                  dom_id: 'edi_out_rule_party_role_id',
                                  options_array: []),
                   OpenStruct.new(type: repo.can_transform_for_party?(params[:changed_value]) ? :show_element : :hide_element,
                                  dom_id: 'edi_out_rule_party_role_id_field_wrapper')]
        return json_actions(actions)
      end

      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'edi_out_rule_destination_type',
                                   options_array: []),
                    OpenStruct.new(type: :show_element,
                                   dom_id: 'edi_out_rule_destination_type_field_wrapper'),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'edi_out_rule_depot_id',
                                   options_array: []),
                    OpenStruct.new(type: :show_element,
                                   dom_id: 'edi_out_rule_depot_id_field_wrapper'),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'edi_out_rule_role_id',
                                   options_array: []),
                    OpenStruct.new(type: :show_element,
                                   dom_id: 'edi_out_rule_role_id_field_wrapper'),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'edi_out_rule_party_role_id',
                                   options_array: []),
                    OpenStruct.new(type: :show_element,
                                   dom_id: 'edi_out_rule_party_role_id_field_wrapper')])
    end

    r.on 'destination_type_changed' do # rubocop:disable Metrics/BlockLength
      if params[:changed_value] == AppConst::DEPOT_DESTINATION_TYPE
        depots = MasterfilesApp::DepotRepo.new.for_select_depots
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'edi_out_rule_depot_id',
                                     options_array: depots),
                      OpenStruct.new(type: :show_element,
                                     dom_id: 'edi_out_rule_depot_id_field_wrapper'),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'edi_out_rule_role_id',
                                     options_array: []),
                      OpenStruct.new(type: :hide_element,
                                     dom_id: 'edi_out_rule_role_id_field_wrapper'),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'edi_out_rule_party_role_id',
                                     options_array: []),
                      OpenStruct.new(type: :hide_element,
                                     dom_id: 'edi_out_rule_party_role_id_field_wrapper')])
      elsif params[:changed_value] == AppConst::PARTY_ROLE_DESTINATION_TYPE
        roles = AppConst::EDI_OUT_RULES_TEMPLATE[params[:edi_out_rule_flow_type]][:roles].to_a
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'edi_out_rule_depot_id',
                                     options_array: []),
                      OpenStruct.new(type: :hide_element,
                                     dom_id: 'edi_out_rule_depot_id_field_wrapper'),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'edi_out_rule_role_id',
                                     options_array: roles),
                      OpenStruct.new(type: :show_element,
                                     dom_id: 'edi_out_rule_role_id_field_wrapper'),
                      OpenStruct.new(type: :show_element,
                                     dom_id: 'edi_out_rule_party_role_id_field_wrapper')])
      else
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'edi_out_rule_depot_id',
                                     options_array: []),
                      OpenStruct.new(type: :show_element,
                                     dom_id: 'edi_out_rule_depot_id_field_wrapper'),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'edi_out_rule_role_id',
                                     options_array: []),
                      OpenStruct.new(type: :show_element,
                                     dom_id: 'edi_out_rule_role_id_field_wrapper'),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'edi_out_rule_party_role_id',
                                     options_array: []),
                      OpenStruct.new(type: :show_element,
                                     dom_id: 'edi_out_rule_party_role_id_field_wrapper')])
      end
    end

    r.on 'role_id_changed' do
      party_roles = MasterfilesApp::PartyRepo.new.for_select_party_roles_org_code(params[:changed_value])
      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'edi_out_rule_party_role_id',
                                   options_array: party_roles),
                    OpenStruct.new(type: :show_element,
                                   dom_id: 'edi_out_rule_party_role_id_field_wrapper')])
    end
  end
end
