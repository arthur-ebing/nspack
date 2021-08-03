# frozen_string_literal: true

class Nspack < Roda
  route 'finance', 'masterfiles' do |r|
    # CURRENCIES
    # --------------------------------------------------------------------------
    r.on 'currencies', Integer do |id|
      interactor = MasterfilesApp::CurrencyInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:currencies, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('finance', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Finance::Currency::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('finance', 'read')
          show_partial { Masterfiles::Finance::Currency::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_currency(id, params[:currency])
          if res.success
            row_keys = %i[
              currency
              description
              active
            ]
            update_grid_row(id,
                            changes: select_attributes(res.instance, row_keys),
                            grid_id: 'currencies',
                            notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Finance::Currency::Edit.call(id, form_values: params[:currency], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('finance', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_currency(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'currencies' do
      interactor = MasterfilesApp::CurrencyInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('finance', 'new')
        show_partial_or_page(r) { Masterfiles::Finance::Currency::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_currency(params[:currency])
        if res.success
          row_keys = %i[
            id
            currency
            description
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/finance/currencies/new') do
            Masterfiles::Finance::Currency::New.call(form_values: params[:currency],
                                                     form_errors: res.errors,
                                                     remote: fetch?(r))
          end
        end
      end
    end

    # CUSTOMERS
    # --------------------------------------------------------------------------
    r.on 'customers', Integer do |id|
      interactor = MasterfilesApp::CustomerInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:customers, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('finance', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Finance::Customer::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('finance', 'read')
          show_partial { Masterfiles::Finance::Customer::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_customer(id, params[:customer])
          if res.success
            row_keys = %i[
              default_currency_id
              default_currency
              currency_ids
              currencies
              contact_people
              customer_party_role_id
              customer
              financial_account_code
              active
              fruit_industry_levy_id
              fruit_industry_levy
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys),
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Finance::Customer::Edit.call(id, form_values: params[:customer], form_errors: res.errors) }
          end
        end

        r.delete do    # DELETE
          check_auth!('finance', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_customer(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'customers' do
      interactor = MasterfilesApp::CustomerInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'customer_party_role_changed' do
        actions = []
        %w[medium_description
           short_description
           long_description
           company_reg_no
           vat_number].each do |dom_id|
          actions << OpenStruct.new(type: :hide_element, dom_id: "customer_#{dom_id}_field_wrapper")
          actions << OpenStruct.new(type: :set_required, dom_id: "customer_#{dom_id}", required: false)
        end

        if params[:changed_value] == 'Create New Organization'
          %w[medium_description short_description].each do |dom_id|
            actions << OpenStruct.new(type: :set_required, dom_id: "customer_#{dom_id}", required: true)
          end
          %w[medium_description
             short_description
             long_description
             company_reg_no
             vat_number].each do |dom_id|
            actions << OpenStruct.new(type: :show_element, dom_id: "customer_#{dom_id}_field_wrapper")
          end
        end

        json_actions(actions)
      end

      r.on 'new' do    # NEW
        check_auth!('finance', 'new')
        show_partial_or_page(r) { Masterfiles::Finance::Customer::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_customer(params[:customer])
        if res.success
          row_keys = %i[
            id
            default_currency_id
            default_currency
            currency_ids
            currencies
            contact_people
            customer_party_role_id
            customer
            financial_account_code
            active
            fruit_industry_levy_id
            fruit_industry_levy
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/finance/customers/new') do
            Masterfiles::Finance::Customer::New.call(form_values: params[:customer],
                                                     form_errors: res.errors,
                                                     remote: fetch?(r))
          end
        end
      end
    end

    # DEAL TYPES
    # --------------------------------------------------------------------------
    r.on 'deal_types', Integer do |id|
      interactor = MasterfilesApp::DealTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:deal_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('finance', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Finance::DealType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('finance', 'read')
          show_partial { Masterfiles::Finance::DealType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_deal_type(id, params[:deal_type])
          if res.success
            row_keys = %i[
              deal_type
              fixed_amount
              status
              active
            ]
            update_grid_row(id,
                            changes: select_attributes(res.instance, row_keys),
                            grid_id: 'deal_types',
                            notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Finance::DealType::Edit.call(id, form_values: params[:deal_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('finance', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_deal_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'deal_types' do
      interactor = MasterfilesApp::DealTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('finance', 'new')
        show_partial_or_page(r) { Masterfiles::Finance::DealType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_deal_type(params[:deal_type])
        if res.success
          row_keys = %i[
            id
            deal_type
            fixed_amount
            status
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/finance/deal_types/new') do
            Masterfiles::Finance::DealType::New.call(form_values: params[:deal_type],
                                                     form_errors: res.errors,
                                                     remote: fetch?(r))
          end
        end
      end
    end

    # INCOTERMS
    # --------------------------------------------------------------------------
    r.on 'incoterms', Integer do |id|
      interactor = MasterfilesApp::IncotermInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:incoterms, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('finance', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Finance::Incoterm::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('finance', 'read')
          show_partial { Masterfiles::Finance::Incoterm::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_incoterm(id, params[:incoterm])
          if res.success
            row_keys = %i[
              incoterm
              status
              active
            ]
            update_grid_row(id,
                            changes: select_attributes(res.instance, row_keys),
                            notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Finance::Incoterm::Edit.call(id, form_values: params[:incoterm], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('finance', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_incoterm(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'incoterms' do
      interactor = MasterfilesApp::IncotermInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('finance', 'new')
        show_partial_or_page(r) { Masterfiles::Finance::Incoterm::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_incoterm(params[:incoterm])
        if res.success
          row_keys = %i[
            id
            incoterm
            status
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/finance/incoterms/new') do
            Masterfiles::Finance::Incoterm::New.call(form_values: params[:incoterm],
                                                     form_errors: res.errors,
                                                     remote: fetch?(r))
          end
        end
      end
    end

    # CUSTOMER PAYMENT TERM SETS
    # --------------------------------------------------------------------------
    r.on 'customer_payment_term_sets', Integer do |id|
      interactor = MasterfilesApp::CustomerPaymentTermSetInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:customer_payment_term_sets, id) do
        handle_not_found(r)
      end

      r.on 'link_payment_terms' do
        r.post do
          res = interactor.link_payment_terms(id, multiselect_grid_choices(params))
          flash[res.success ? :notice : :error] = res.message
          redirect_to_last_grid(r)
        end
      end

      r.on 'edit' do   # EDIT
        check_auth!('finance', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Finance::CustomerPaymentTermSet::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('finance', 'read')
          show_partial { Masterfiles::Finance::CustomerPaymentTermSet::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_customer_payment_term_set(id, params[:customer_payment_term_set])
          if res.success
            flash[:notice] = res.message
            r.redirect "/masterfiles/finance/customer_payment_term_sets/#{res.instance.id}"
          else
            re_show_form(r, res) { Masterfiles::Finance::CustomerPaymentTermSet::Edit.call(id, form_values: params[:customer_payment_term_set], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('finance', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_customer_payment_term_set(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'customer_payment_term_sets' do
      interactor = MasterfilesApp::CustomerPaymentTermSetInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('finance', 'new')
        show_partial_or_page(r) { Masterfiles::Finance::CustomerPaymentTermSet::New.call(form_values: params, remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_customer_payment_term_set(params[:customer_payment_term_set])
        if res.success
          flash[:notice] = res.message
          r.redirect "/masterfiles/finance/customer_payment_term_sets/#{res.instance.id}"
        else
          re_show_form(r, res, url: '/masterfiles/finance/customer_payment_term_sets/new') do
            Masterfiles::Finance::CustomerPaymentTermSet::New.call(form_values: params[:customer_payment_term_set],
                                                                   form_errors: res.errors,
                                                                   remote: fetch?(r))
          end
        end
      end
    end

    # PAYMENT TERM DATE TYPES
    # --------------------------------------------------------------------------
    r.on 'payment_term_date_types', Integer do |id|
      interactor = MasterfilesApp::PaymentTermDateTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:payment_term_date_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('finance', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Finance::PaymentTermDateType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('finance', 'read')
          show_partial { Masterfiles::Finance::PaymentTermDateType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_payment_term_date_type(id, params[:payment_term_date_type])
          if res.success
            row_keys = %i[
              type_of_date
              no_days_after_etd
              no_days_after_eta
              no_days_after_atd
              no_days_after_ata
              no_days_after_invoice
              no_days_after_invoice_sent
              no_days_after_container_load
              anchor_to_date
              adjust_anchor_date_to_month_end
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Finance::PaymentTermDateType::Edit.call(id, form_values: params[:payment_term_date_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('finance', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_payment_term_date_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'payment_term_date_types' do
      interactor = MasterfilesApp::PaymentTermDateTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('finance', 'new')
        show_partial_or_page(r) { Masterfiles::Finance::PaymentTermDateType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_payment_term_date_type(params[:payment_term_date_type])
        if res.success
          row_keys = %i[
            id
            type_of_date
            no_days_after_etd
            no_days_after_eta
            no_days_after_atd
            no_days_after_ata
            no_days_after_invoice
            no_days_after_invoice_sent
            no_days_after_container_load
            anchor_to_date
            adjust_anchor_date_to_month_end
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/finance/payment_term_date_types/new') do
            Masterfiles::Finance::PaymentTermDateType::New.call(form_values: params[:payment_term_date_type],
                                                                form_errors: res.errors,
                                                                remote: fetch?(r))
          end
        end
      end
    end

    # PAYMENT TERM TYPES
    # --------------------------------------------------------------------------
    r.on 'payment_term_types', Integer do |id|
      interactor = MasterfilesApp::PaymentTermTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:payment_term_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('finance', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Finance::PaymentTermType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('finance', 'read')
          show_partial { Masterfiles::Finance::PaymentTermType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_payment_term_type(id, params[:payment_term_type])
          if res.success
            update_grid_row(id, changes: { payment_term_type: res.instance[:payment_term_type] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Finance::PaymentTermType::Edit.call(id, form_values: params[:payment_term_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('finance', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_payment_term_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'payment_term_types' do
      interactor = MasterfilesApp::PaymentTermTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('finance', 'new')
        show_partial_or_page(r) { Masterfiles::Finance::PaymentTermType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_payment_term_type(params[:payment_term_type])
        if res.success
          row_keys = %i[
            id
            payment_term_type
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/finance/payment_term_types/new') do
            Masterfiles::Finance::PaymentTermType::New.call(form_values: params[:payment_term_type],
                                                            form_errors: res.errors,
                                                            remote: fetch?(r))
          end
        end
      end
    end

    # PAYMENT TERMS
    # --------------------------------------------------------------------------
    r.on 'payment_terms', Integer do |id|
      interactor = MasterfilesApp::PaymentTermInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:payment_terms, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('finance', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Finance::PaymentTerm::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('finance', 'read')
          show_partial { Masterfiles::Finance::PaymentTerm::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_payment_term(id, params[:payment_term])
          if res.success
            row_keys = %i[
              payment_term
              payment_term_date_type_id
              payment_term_date_type
              short_description
              long_description
              percentage
              days
              amount_per_carton
              for_liquidation
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Finance::PaymentTerm::Edit.call(id, form_values: params[:payment_term], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('finance', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_payment_term(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'payment_terms' do
      interactor = MasterfilesApp::PaymentTermInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('finance', 'new')
        show_partial_or_page(r) { Masterfiles::Finance::PaymentTerm::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_payment_term(params[:payment_term])
        if res.success
          row_keys = %i[
            id
            payment_term
            payment_term_date_type_id
            payment_term_date_type
            short_description
            long_description
            percentage
            days
            amount_per_carton
            for_liquidation
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/finance/payment_terms/new') do
            Masterfiles::Finance::PaymentTerm::New.call(form_values: params[:payment_term],
                                                        form_errors: res.errors,
                                                        remote: fetch?(r))
          end
        end
      end
    end

    # CUSTOMER PAYMENT TERMS
    # --------------------------------------------------------------------------
    r.on 'customer_payment_terms', Integer do |id|
      interactor = MasterfilesApp::CustomerPaymentTermInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:customer_payment_terms, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('finance', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Finance::CustomerPaymentTerm::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('finance', 'read')
          show_partial { Masterfiles::Finance::CustomerPaymentTerm::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_customer_payment_term(id, params[:customer_payment_term])
          if res.success
            update_grid_row(id, changes: { payment_term_id: res.instance[:payment_term_id], customer_payment_term_set_id: res.instance[:customer_payment_term_set_id] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Finance::CustomerPaymentTerm::Edit.call(id, form_values: params[:customer_payment_term], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('finance', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_customer_payment_term(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'customer_payment_terms' do
      interactor = MasterfilesApp::CustomerPaymentTermInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('finance', 'new')
        show_partial_or_page(r) { Masterfiles::Finance::CustomerPaymentTerm::New.call(remote: fetch?(r)) }
      end

      r.post do        # CREATE
        res = interactor.create_customer_payment_term(params[:customer_payment_term])
        if res.success
          row_keys = %i[
            id
            payment_term_id
            customer_payment_term_set_id
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/finance/customer_payment_terms/new') do
            Masterfiles::Finance::CustomerPaymentTerm::New.call(form_values: params[:customer_payment_term],
                                                                form_errors: res.errors,
                                                                remote: fetch?(r))
          end
        end
      end
    end

    # ORDER TYPES
    # --------------------------------------------------------------------------
    r.on 'order_types', Integer do |id|
      interactor = MasterfilesApp::OrderTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:order_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('finance', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Finance::OrderType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('finance', 'read')
          show_partial { Masterfiles::Finance::OrderType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_order_type(id, params[:order_type])
          if res.success
            update_grid_row(id, changes: { order_type: res.instance[:order_type], description: res.instance[:description] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Finance::OrderType::Edit.call(id, form_values: params[:order_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('finance', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_order_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'order_types' do
      interactor = MasterfilesApp::OrderTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('finance', 'new')
        show_partial_or_page(r) { Masterfiles::Finance::OrderType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_order_type(params[:order_type])
        if res.success
          row_keys = %i[
            id
            order_type
            description
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/finance/order_types/new') do
            Masterfiles::Finance::OrderType::New.call(form_values: params[:order_type],
                                                      form_errors: res.errors,
                                                      remote: fetch?(r))
          end
        end
      end
    end
  end
end
