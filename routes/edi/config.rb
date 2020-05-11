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

        rule = EdiApp::EdiOutRepo.new.find_edi_out_rule(id)
        destination_type = if !rule[:depot_id].nil_or_empty?
                             'DEPOT'
                           else
                             !rule[:party_role_id].nil_or_empty? && rule[:flow_type] == 'PO' ? 'PARTY_ROLE' : nil
                           end
        po_mode = !destination_type.nil? ? "_#{destination_type.downcase}" : nil
        show_partial_or_page(r) { Edi::Config::EdiOutRule::Edit.call(id, "#{rule[:flow_type].downcase}#{po_mode}".to_sym) }
      end

      r.is do # rubocop:disable Metrics/BlockLength
        r.get do       # SHOW
          check_auth!('config', 'read')
          show_partial { Edi::Config::EdiOutRule::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_edi_out_rule(id, params[:edi_out_rule])
          po_mode = !params[:edi_out_rule][:destination_type].nil_or_empty? ? "_#{params[:edi_out_rule][:destination_type].downcase}" : nil
          if res.success
            # flash[:notice] = res.message
            show_partial_or_page(r) { Edi::Config::EdiOutRule::Edit.call(id, "#{res.instance[:flow_type].downcase}#{po_mode}".to_sym) }
          else
            re_show_form(r, res, url: "/edi/config/edi_out_rules/#{id}/edit") do
              Edi::Config::EdiOutRule::Edit.call(id,
                                                 "#{params[:edi_out_rule][:flow_type].downcase}#{po_mode}".to_sym,
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
          po_mode = !params[:edi_out_rule][:destination_type].nil_or_empty? ? "_#{params[:edi_out_rule][:destination_type].downcase}" : nil
          if res.success
            show_partial_or_page(r) { Edi::Config::EdiOutRule::Edit.call(res.instance[:id], "#{params[:edi_out_rule][:flow_type].downcase}#{po_mode}".to_sym) }
          else
            re_show_form(r, res, url: '/edi/config/edi_out_rules') do
              Edi::Config::EdiOutRule::New.call(form_values: params[:edi_out_rule],
                                                form_errors: res.errors,
                                                remote: fetch?(r),
                                                mode: "#{params[:edi_out_rule][:flow_type].downcase}#{po_mode}".to_sym)
            end
          end
        end
      end
    end

    r.on 'flow_type_changed' do
      return po_selected if params[:changed_value] == AppConst::EDI_FLOW_PO
      return ps_selected if params[:changed_value] == AppConst::EDI_FLOW_PS

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
      if params[:changed_value] == 'DEPOT'
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
      elsif params[:changed_value] == 'PARTY_ROLE'
        roles = [AppConst::ROLE_CUSTOMER, AppConst::ROLE_SHIPPER, AppConst::ROLE_EXPORTER]
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

  def po_selected
    json_actions([OpenStruct.new(type: :replace_select_options,
                                 dom_id: 'edi_out_rule_destination_type',
                                 options_array: %w[DEPOT PARTY_ROLE]),
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
                                 options_array: [])])
  end

  def ps_selected
    roles = [AppConst::ROLE_MARKETER, AppConst::ROLE_TARGET_CUSTOMER]
    json_actions([OpenStruct.new(type: :replace_select_options,
                                 dom_id: 'edi_out_rule_destination_type',
                                 options_array: ['']),
                  OpenStruct.new(type: :hide_element,
                                 dom_id: 'edi_out_rule_destination_type_field_wrapper'),
                  OpenStruct.new(type: :replace_select_options,
                                 dom_id: 'edi_out_rule_depot_id',
                                 options_array: []),
                  OpenStruct.new(type: :hide_element,
                                 dom_id: 'edi_out_rule_depot_id_field_wrapper'),
                  OpenStruct.new(type: :replace_select_options,
                                 dom_id: 'edi_out_rule_role_id',
                                 options_array: roles),
                  OpenStruct.new(type: :replace_select_options,
                                 dom_id: 'edi_out_rule_party_role_id',
                                 options_array: []),
                  OpenStruct.new(type: :show_element,
                                 dom_id: 'edi_out_rule_party_role_id_field_wrapper')])
  end
end
