# frozen_string_literal: true

class Nspack < Roda
  route 'reports', 'finished_goods' do |r|
    report_repo = BaseRepo.new
    # DELIVERY NOTE
    # --------------------------------------------------------------------------
    r.on 'dispatch_note', Integer do |id|
      jasper_params = JasperParams.new('dispatch_note',
                                       current_user.login_name,
                                       load_id: id,
                                       pallet_report: 'detail',
                                       for_picklist: false,
                                       cartons_equals_pallets: AppConst::CR_PROD.carton_equals_pallet?)
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
                                       cartons_equals_pallets: AppConst::CR_PROD.carton_equals_pallet?)
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
      file_name = AppConst::USE_EXTENDED_PALLET_PICKLIST ? 'dispatch_picklist' : 'picklist'
      jasper_params = JasperParams.new('dispatch_note',
                                       current_user.login_name,
                                       load_id: id,
                                       pallet_report: 'detail',
                                       for_picklist: true,
                                       cartons_equals_pallets: AppConst::CR_PROD.carton_equals_pallet?)
      jasper_params.file_name = file_name
      res = CreateJasperReport.call(jasper_params)

      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    r.on 'dispatch_picklist', Integer do |id|
      file_name = AppConst::USE_EXTENDED_PALLET_PICKLIST ? 'dispatch_picklist' : 'picklist'
      jasper_params = JasperParams.new('dispatch_picklist',
                                       current_user.login_name,
                                       load_id: id,
                                       pallet_report: 'detail',
                                       for_picklist: true,
                                       cartons_equals_pallets: AppConst::CR_PROD.carton_equals_pallet?)
      jasper_params.file_name = file_name
      res = CreateJasperReport.call(jasper_params)

      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # ADDENDUM
    # --------------------------------------------------------------------------
    r.on 'addendum', Integer, String do |id, place|
      jasper_params = JasperParams.new('addendum',
                                       current_user.login_name,
                                       load_id: id,
                                       place_of_issue: place)
      res = CreateJasperReport.call(jasper_params)

      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # Phyto Data
    # --------------------------------------------------------------------------
    r.on 'accompanying_phyto', Integer do |id|
      jasper_params = JasperParams.new('accompanying_phyto',
                                       current_user.login_name,
                                       load_id: id,
                                       from_depot: AppConst::FROM_DEPOT)
      res = CreateJasperReport.call(jasper_params)

      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # Phyto Data
    # --------------------------------------------------------------------------
    r.on 'accompanying_phyto', Integer do |id|
      jasper_params = JasperParams.new('accompanying_phyto',
                                       current_user.login_name,
                                       load_id: id)
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
    #                                    load_container_id: report_repo.get_id(:load_containers, load_id: id))
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
                                       load_container_id: report_repo.get_id(:load_containers, load_id: id),
                                       pallets_weighed: AppConst::CR_PROD.are_pallets_weighed?,
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
      interactor = FinishedGoodsApp::GovtInspectionSheetInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      ph_code = interactor.govt_inspection_sheet_packhouse_code(id)
      jasper_params.parent_folder = AppConst::CR_FG.reporting_industry(plant_resource_code: ph_code)
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
