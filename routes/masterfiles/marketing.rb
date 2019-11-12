# frozen_string_literal: true

class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'marketing', 'masterfiles' do |r| # rubocop:disable Metrics/BlockLength
    # MARKS
    # --------------------------------------------------------------------------
    r.on 'marks', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::MarkInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:marks, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('marketing', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Marketing::Mark::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('marketing', 'read')
          show_partial { Masterfiles::Marketing::Mark::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_mark(id, params[:mark])
          if res.success
            update_grid_row(id, changes: { mark_code: res.instance[:mark_code], description: res.instance[:description] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Marketing::Mark::Edit.call(id, form_values: params[:mark], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('marketing', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_mark(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'marks' do
      interactor = MasterfilesApp::MarkInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('marketing', 'new')
        show_partial_or_page(r) { Masterfiles::Marketing::Mark::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_mark(params[:mark])
        if res.success
          row_keys = %i[
            id
            mark_code
            description
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/marketing/marks/new') do
            Masterfiles::Marketing::Mark::New.call(form_values: params[:mark],
                                                   form_errors: res.errors,
                                                   remote: fetch?(r))
          end
        end
      end
    end

    # CUSTOMER VARIETIES
    # --------------------------------------------------------------------------
    r.on 'customer_varieties', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::CustomerVarietyInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:customer_varieties, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('marketing', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Marketing::CustomerVariety::Edit.call(id) }
      end

      r.on 'link_customer_varieties' do
        r.on 'link' do
          repo = MasterfilesApp::MarketingRepo.new
          customer_variety = repo.find_customer_variety(id)
          handle_not_found(r) unless customer_variety
          check_auth!('marketing', 'edit')
          cultivar_group_id = repo.marketing_variety_cultivar_group(customer_variety.variety_as_customer_variety_id)
          r.redirect "/list/link_marketing_varieties/multi?key=customer_variety_varieties&id=#{id}&cultivar_group_id=#{cultivar_group_id}"
        end

        r.post do
          res = interactor.associate_customer_variety_varieties(id, multiselect_grid_choices(params))
          if fetch?(r)
            show_json_notice(res.message)
          else
            flash[:notice] = res.message
            r.redirect '/list/marketing_varieties'
          end
        end
      end

      r.on 'clone_customer_variety' do
        r.on 'clone' do
          repo = MasterfilesApp::MarketingRepo.new
          customer_variety = repo.find_customer_variety(id)
          handle_not_found(r) unless customer_variety
          check_auth!('marketing', 'edit')
          packed_tm_group_ids = repo.available_to_clone_packed_tm_groups(customer_variety.variety_as_customer_variety_id)
          r.redirect "/list/clone_customer_varieties/multi?key=customer_variety_varieties&id=#{id}&packed_tm_group_id=#{packed_tm_group_ids}"
        end

        r.post do
          res = interactor.clone_customer_variety(id, multiselect_grid_choices(params))
          if fetch?(r)
            show_json_notice(res.message)
          else
            flash[:notice] = res.message
            r.redirect '/list/target_market_groups'
          end
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('marketing', 'read')
          show_partial { Masterfiles::Marketing::CustomerVariety::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_customer_variety(id, params[:customer_variety])
          if res.success
            update_grid_row(id, changes: { variety_as_customer_variety: res.instance[:variety_as_customer_variety], packed_tm_group: res.instance[:packed_tm_group] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Marketing::CustomerVariety::Edit.call(id, form_values: params[:customer_variety], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('marketing', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_customer_variety(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'customer_varieties' do # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::CustomerVarietyInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'variety_as_customer_variety_changed' do
        customer_variety_varieties = interactor.for_select_group_marketing_varieties(params[:changed_value])
        json_replace_multi_options('customer_variety_customer_variety_varieties', customer_variety_varieties)
      end

      r.on 'new' do    # NEW
        check_auth!('marketing', 'new')
        show_partial_or_page(r) { Masterfiles::Marketing::CustomerVariety::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_customer_variety(params[:customer_variety])
        if res.success
          row_keys = %i[
            id
            variety_as_customer_variety
            packed_tm_group
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/marketing/customer_varieties/new') do
            Masterfiles::Marketing::CustomerVariety::New.call(form_values: params[:customer_variety],
                                                              form_errors: res.errors,
                                                              remote: fetch?(r))
          end
        end
      end
    end

    # CUSTOMER VARIETY VARIETIES
    # --------------------------------------------------------------------------
    r.on 'customer_variety_varieties', Integer do |id|
      interactor = MasterfilesApp::CustomerVarietyInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:customer_variety_varieties, id) do
        handle_not_found(r)
      end

      r.is do
        r.delete do    # DELETE
          check_auth!('marketing', 'delete')
          res = interactor.delete_customer_variety_variety(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end
  end
end
