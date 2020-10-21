# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'reports', 'finished_goods' do |r|
    @repo = BaseRepo.new
    # DELIVERY NOTE
    # --------------------------------------------------------------------------
    r.on 'dispatch_note', Integer do |id|
      res = if AppConst::JASPER_NEW_METHOD
              jasper_params = JasperParams.new('dispatch_note',
                                               current_user.login_name,
                                               load_id: id,
                                               pallet_report: 'detail',
                                               for_picklist: false,
                                               cartons_equals_pallets: AppConst::CARTON_EQUALS_PALLET)
              CreateJasperReportNew.call(jasper_params)
            else
              CreateJasperReport.call(report_name: 'dispatch_note',
                                      user: current_user.login_name,
                                      file: 'dispatch_note',
                                      params: { load_id: id,
                                                pallet_report: 'detail',
                                                for_picklist: 'false|boolean',
                                                cartons_equals_pallets: "#{AppConst::CARTON_EQUALS_PALLET}|boolean",
                                                keep_file: false })
            end
      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # DELIVERY NOTE - SUMMARISED
    # --------------------------------------------------------------------------
    r.on 'dispatch_note_summarised', Integer do |id|
      res = if AppConst::JASPER_NEW_METHOD
              jasper_params = JasperParams.new('dispatch_note',
                                               current_user.login_name,
                                               load_id: id,
                                               pallet_report: 'summary',
                                               for_picklist: false,
                                               cartons_equals_pallets: AppConst::CARTON_EQUALS_PALLET)
              CreateJasperReportNew.call(jasper_params)
            else
              CreateJasperReport.call(report_name: 'dispatch_note',
                                      user: current_user.login_name,
                                      file: 'dispatch_note',
                                      params: { load_id: id,
                                                pallet_report: 'summary',
                                                for_picklist: 'false|boolean',
                                                cartons_equals_pallets: "#{AppConst::CARTON_EQUALS_PALLET}|boolean",
                                                keep_file: false })
            end
      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # PICKLIST
    # --------------------------------------------------------------------------
    r.on 'picklist', Integer do |id|
      report_name = AppConst::USE_EXTENDED_PALLET_PICKLIST ? 'dispatch_picklist' : 'picklist'
      res = if AppConst::JASPER_NEW_METHOD
              jasper_params = JasperParams.new(report_name,
                                               current_user.login_name,
                                               load_id: id,
                                               pallet_report: 'detail',
                                               for_picklist: true,
                                               cartons_equals_pallets: AppConst::CARTON_EQUALS_PALLET)
              CreateJasperReportNew.call(jasper_params)
            else
              CreateJasperReport.call(report_name: 'dispatch_note',
                                      user: current_user.login_name,
                                      file: report_name,
                                      params: { load_id: id,
                                                pallet_report: 'detail',
                                                for_picklist: 'true|boolean',
                                                cartons_equals_pallets: "#{AppConst::CARTON_EQUALS_PALLET}|boolean",
                                                keep_file: false })
            end
      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # ADDENDUM
    # --------------------------------------------------------------------------
    r.on 'addendum', Integer do |id|
      res = if AppConst::JASPER_NEW_METHOD
              jasper_params = JasperParams.new('addendum',
                                               current_user.login_name,
                                               load_id: id,
                                               place_of_issue: AppConst::ADDENDUM_PLACE_OF_ISSUE)
              # jasper_params.mode = :print
              # jasper_params.printer = 'L3060'
              CreateJasperReportNew.call(jasper_params)
            else
              CreateJasperReport.call(report_name: 'addendum',
                                      user: current_user.login_name,
                                      file: 'addendum',
                                      params: { load_id: id,
                                                place_of_issue: AppConst::ADDENDUM_PLACE_OF_ISSUE,
                                                keep_file: false })
            end
      if res.success
        # change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
        change_window_location_via_json('/', request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # # VERIFIED GROSS MASS
    # # --------------------------------------------------------------------------
    # r.on 'verified_gross_mass', Integer do |id|
    #   res = if AppConst::JASPER_NEW_METHOD
    #           jasper_params = JasperParams.new('container_mass_declaration',
    #                                            current_user.login_name,
    #                                            load_container_id: @repo.get_id(:load_containers, load_id: id))
    #           CreateJasperReportNew.call(jasper_params)
    #         else
    #           CreateJasperReport.call(report_name: 'container_mass_declaration',
    #                                   user: current_user.login_name,
    #                                   file: 'container_mass_declaration',
    #                                   params: { load_container_id: @repo.get_id(:load_containers, load_id: id),
    #                                             keep_file: false })
    #         end
    #   if res.success
    #     change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
    #   else
    #     show_error(res.message, fetch?(r))
    #   end
    # end

    # VERIFIED GROSS MASS
    # --------------------------------------------------------------------------
    r.on 'verified_gross_mass', Integer do |id|
      res = if AppConst::JASPER_NEW_METHOD
              jasper_params = JasperParams.new('container_mass_declaration',
                                               current_user.login_name,
                                               load_container_id: @repo.get_id(:load_containers, load_id: id),
                                               user_name: current_user.user_name)
              CreateJasperReportNew.call(jasper_params)
            else
              CreateJasperReport.call(report_name: 'container_mass_declaration',
                                      user: current_user.login_name,
                                      file: 'container_mass_declaration',
                                      params: { load_container_id: @repo.get_id(:load_containers, load_id: id),
                                                user_name: current_user.user_name,
                                                keep_file: false })
            end
      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # GOVT INSPECTION SHEET PASSED
    # --------------------------------------------------------------------------
    r.on 'passed_inspection_report', Integer do |id|
      res = if AppConst::JASPER_NEW_METHOD
              jasper_params = JasperParams.new('govt_inspection_report',
                                               current_user.login_name,
                                               govt_inspection_sheet_id: id,
                                               inspection_passed: true,
                                               signee_caption: AppConst::GOVT_INSPECTION_SIGNEE_CAPTION)
              CreateJasperReportNew.call(jasper_params)
            else
              CreateJasperReport.call(report_name: 'govt_inspection_report',
                                      user: current_user.login_name,
                                      file: 'govt_inspection_report',
                                      params: { govt_inspection_sheet_id: id,
                                                inspection_passed: 'true|boolean',
                                                signee_caption: AppConst::GOVT_INSPECTION_SIGNEE_CAPTION,
                                                keep_file: false })
            end
      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # GOVT INSPECTION SHEET FAILED
    # --------------------------------------------------------------------------
    r.on 'failed_inspection_report', Integer do |id|
      res = if AppConst::JASPER_NEW_METHOD
              jasper_params = JasperParams.new('govt_inspection_report',
                                               current_user.login_name,
                                               govt_inspection_sheet_id: id,
                                               inspection_passed: false,
                                               signee_caption: AppConst::GOVT_INSPECTION_SIGNEE_CAPTION)
              CreateJasperReportNew.call(jasper_params)
            else
              CreateJasperReport.call(report_name: 'govt_inspection_report',
                                      user: current_user.login_name,
                                      file: 'govt_inspection_report',
                                      params: { govt_inspection_sheet_id: id,
                                                inspection_passed: 'false|boolean',
                                                signee_caption: AppConst::GOVT_INSPECTION_SIGNEE_CAPTION,
                                                keep_file: false })
            end
      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # GOVT FINDING SHEET
    # --------------------------------------------------------------------------
    r.on 'finding_sheet', Integer do |id|
      res = if AppConst::JASPER_NEW_METHOD
              jasper_params = JasperParams.new('govt_finding_sheet',
                                               current_user.login_name,
                                               govt_inspection_sheet_id: id)
              jasper_params.parent_folder = AppConst::RPT_INDUSTRY
              CreateJasperReportNew.call(jasper_params)
            else
              CreateJasperReport.call(report_name: 'govt_finding_sheet',
                                      user: current_user.login_name,
                                      file: 'govt_finding_sheet',
                                      parent_folder: AppConst::RPT_INDUSTRY,
                                      params: { govt_inspection_sheet_id: id,
                                                keep_file: false })
            end
      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # TRIPSHEET SHEET
    # --------------------------------------------------------------------------
    r.on 'print_tripsheet', Integer do |id|
      vehicle_job_id = FinishedGoodsApp::GovtInspectionRepo.new.get_id(:vehicle_jobs, govt_inspection_sheet_id: id)
      res = if AppConst::JASPER_NEW_METHOD
              jasper_params = JasperParams.new('interwarehouse',
                                               current_user.login_name,
                                               vehicle_job_id: vehicle_job_id)
              CreateJasperReportNew.call(jasper_params)
            else
              CreateJasperReport.call(report_name: 'interwarehouse',
                                      user: current_user.login_name,
                                      file: 'interwarehouse',
                                      params: { vehicle_job_id: vehicle_job_id,
                                                keep_file: false })
            end
      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
