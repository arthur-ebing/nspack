# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'reports', 'finished_goods' do |r|
    @repo = BaseRepo.new
    # DELIVERY NOTE
    # --------------------------------------------------------------------------
    r.on 'dispatch_note', Integer do |id|
      jasper_params = JasperParams.new('dispatch_note',
                                       current_user.login_name,
                                       load_id: id,
                                       pallet_report: 'detail',
                                       for_picklist: false,
                                       cartons_equals_pallets: AppConst::CARTON_EQUALS_PALLET)
      res = CreateJasperReport.call(jasper_params)

      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # DELIVERY NOTE - SUMMARISED
    # --------------------------------------------------------------------------
    r.on 'dispatch_note_summarised', Integer do |id|
      jasper_params = JasperParams.new('dispatch_note',
                                       current_user.login_name,
                                       load_id: id,
                                       pallet_report: 'summary',
                                       for_picklist: false,
                                       cartons_equals_pallets: AppConst::CARTON_EQUALS_PALLET)
      res = CreateJasperReport.call(jasper_params)

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
      jasper_params = JasperParams.new(report_name,
                                       current_user.login_name,
                                       load_id: id,
                                       pallet_report: 'detail',
                                       for_picklist: true,
                                       cartons_equals_pallets: AppConst::CARTON_EQUALS_PALLET)
      res = CreateJasperReport.call(jasper_params)

      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # ADDENDUM
    # --------------------------------------------------------------------------
    r.on 'addendum', Integer do |id|
      jasper_params = JasperParams.new('addendum',
                                       current_user.login_name,
                                       load_id: id,
                                       place_of_issue: AppConst::ADDENDUM_PLACE_OF_ISSUE)
      res = CreateJasperReport.call(jasper_params)

      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # # VERIFIED GROSS MASS
    # # --------------------------------------------------------------------------
    # r.on 'verified_gross_mass', Integer do |id|
    #   jasper_params = JasperParams.new('container_mass_declaration',
    #                                    current_user.login_name,
    #                                    load_container_id: @repo.get_id(:load_containers, load_id: id))
    #   res = CreateJasperReport.call(jasper_params)
    #
    #   if res.success
    #     change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
    #   else
    #     show_error(res.message, fetch?(r))
    #   end
    # end

    # VERIFIED GROSS MASS
    # --------------------------------------------------------------------------
    r.on 'verified_gross_mass', Integer do |id|
      jasper_params = JasperParams.new('container_mass_declaration',
                                       current_user.login_name,
                                       load_container_id: @repo.get_id(:load_containers, load_id: id),
                                       user_name: current_user.user_name)
      res = CreateJasperReport.call(jasper_params)

      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # GOVT INSPECTION SHEET PASSED
    # --------------------------------------------------------------------------
    r.on 'passed_inspection_report', Integer do |id|
      jasper_params = JasperParams.new('govt_inspection_report',
                                       current_user.login_name,
                                       govt_inspection_sheet_id: id,
                                       inspection_passed: true,
                                       signee_caption: AppConst::GOVT_INSPECTION_SIGNEE_CAPTION)
      res = CreateJasperReport.call(jasper_params)

      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # GOVT INSPECTION SHEET FAILED
    # --------------------------------------------------------------------------
    r.on 'failed_inspection_report', Integer do |id|
      jasper_params = JasperParams.new('govt_inspection_report',
                                       current_user.login_name,
                                       govt_inspection_sheet_id: id,
                                       inspection_passed: false,
                                       signee_caption: AppConst::GOVT_INSPECTION_SIGNEE_CAPTION)
      res = CreateJasperReport.call(jasper_params)

      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # GOVT FINDING SHEET
    # --------------------------------------------------------------------------
    r.on 'finding_sheet', Integer do |id|
      jasper_params = JasperParams.new('govt_finding_sheet',
                                       current_user.login_name,
                                       govt_inspection_sheet_id: id)
      jasper_params.parent_folder = AppConst::RPT_INDUSTRY
      res = CreateJasperReport.call(jasper_params)

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
      jasper_params = JasperParams.new('interwarehouse',
                                       current_user.login_name,
                                       vehicle_job_id: vehicle_job_id)
      res = CreateJasperReport.call(jasper_params)

      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
