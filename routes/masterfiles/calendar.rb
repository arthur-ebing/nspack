# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'calendar', 'masterfiles' do |r|
    # SEASON GROUPS
    # --------------------------------------------------------------------------
    r.on 'season_groups', Integer do |id|
      interactor = MasterfilesApp::SeasonGroupInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:season_groups, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('calendar', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Calendar::SeasonGroup::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('calendar', 'read')
          show_partial { Masterfiles::Calendar::SeasonGroup::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_season_group(id, params[:season_group])
          if res.success
            update_grid_row(id, changes: { season_group_code: res.instance[:season_group_code], description: res.instance[:description], season_group_year: res.instance[:season_group_year] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Calendar::SeasonGroup::Edit.call(id, form_values: params[:season_group], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('calendar', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_season_group(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'season_groups' do
      interactor = MasterfilesApp::SeasonGroupInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('calendar', 'new')
        show_partial_or_page(r) { Masterfiles::Calendar::SeasonGroup::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_season_group(params[:season_group])
        if res.success
          row_keys = %i[
            id
            season_group_code
            description
            season_group_year
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/calendar/season_groups/new') do
            Masterfiles::Calendar::SeasonGroup::New.call(form_values: params[:season_group],
                                                         form_errors: res.errors,
                                                         remote: fetch?(r))
          end
        end
      end
    end

    # SEASONS
    # --------------------------------------------------------------------------
    r.on 'seasons', Integer do |id|
      interactor = MasterfilesApp::SeasonInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:seasons, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('calendar', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Calendar::Season::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('calendar', 'read')
          show_partial { Masterfiles::Calendar::Season::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_season(id, params[:season])
          if res.success
            row_keys = %i[
              season_group_code
              commodity_code
              season_code
              description
              season_year
              start_date
              end_date
              active
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Calendar::Season::Edit.call(id, form_values: params[:season], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('calendar', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_season(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'seasons' do
      interactor = MasterfilesApp::SeasonInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'start_date_changed' do
        end_date = interactor.one_year_from_start_date(params[:changed_value])
        json_replace_input_value('season_end_date', end_date)
      end

      r.on 'new' do    # NEW
        check_auth!('calendar', 'new')
        show_partial_or_page(r) { Masterfiles::Calendar::Season::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_season(params[:season])
        if res.success
          row_keys = %i[
            id
            season_group_code
            commodity_code
            season_code
            description
            season_year
            start_date
            end_date
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/calendar/seasons/new') do
            Masterfiles::Calendar::Season::New.call(form_values: params[:season],
                                                    form_errors: res.errors,
                                                    remote: fetch?(r))
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
