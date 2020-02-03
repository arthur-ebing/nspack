# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'reports', 'finished_goods' do |r|
    # DELIVERY NOTE
    # --------------------------------------------------------------------------
    r.on 'dispatch_note', Integer do |id|
      res = CreateJasperReport.call(report_name: 'dispatch_note',
                                    user: current_user.login_name,
                                    file: 'dispatch_note',
                                    params: { load_id: id,
                                              pallet_report: 'detail',
                                              for_picklist: 'false|boolean',
                                              cartons_equals_pallets: "#{AppConst::CARTON_EQUALS_PALLET}|boolean",
                                              keep_file: false })
      if res.success
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # DELIVERY NOTE - SUMMARISED
    # --------------------------------------------------------------------------
    r.on 'dispatch_note_summarised', Integer do |id|
      res = CreateJasperReport.call(report_name: 'dispatch_note',
                                    user: current_user.login_name,
                                    file: 'dispatch_note',
                                    params: { load_id: id,
                                              pallet_report: 'summary',
                                              for_picklist: 'false|boolean',
                                              cartons_equals_pallets: "#{AppConst::CARTON_EQUALS_PALLET}|boolean",
                                              keep_file: false })
      if res.success
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # PICKLIST
    # --------------------------------------------------------------------------
    r.on 'picklist', Integer do |id|
      res = CreateJasperReport.call(report_name: 'dispatch_note',
                                    user: current_user.login_name,
                                    file: 'dispatch_note',
                                    params: { load_id: id,
                                              pallet_report: 'detail',
                                              for_picklist: 'true|boolean',
                                              cartons_equals_pallets: "#{AppConst::CARTON_EQUALS_PALLET}|boolean",
                                              keep_file: false })
      if res.success
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # ADDENDUM
    # --------------------------------------------------------------------------
    r.on 'addendum', Integer do |id|
      res = CreateJasperReport.call(report_name: 'addendum',
                                    user: current_user.login_name,
                                    file: 'addendum',
                                    params: { load_id: id,
                                              place_of_issue: AppConst::ADDENDUM_PLACE_OF_ISSUE,
                                              keep_file: false })
      if res.success
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # VERIFIED GROSS MASS
    # --------------------------------------------------------------------------
    r.on 'verified_gross_mass', Integer do |id|
      res = CreateJasperReport.call(report_name: 'container_mass_declaration',
                                    user: current_user.login_name,
                                    file: 'container_mass_declaration',
                                    params: { load_container_id: BaseRepo.new.get_with_args(:load_containers, :id, load_id: id),
                                              keep_file: false })
      if res.success
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # VERIFIED GROSS MASS
    # --------------------------------------------------------------------------
    r.on 'verified_gross_mass', Integer do |id|
      res = CreateJasperReport.call(report_name: 'container_mass_declaration',
                                    user: current_user.login_name,
                                    file: 'container_mass_declaration',
                                    params: { load_container_id: BaseRepo.new.get_with_args(:load_containers, :id, load_id: id),
                                              user_name: current_user.user_name,
                                              keep_file: false })
      if res.success
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # GOVT INSPECTION SHEET PASSED
    # --------------------------------------------------------------------------
    r.on 'passed_inspection_report', Integer do |id|
      res = CreateJasperReport.call(report_name: 'govt_inspection_report',
                                    user: current_user.login_name,
                                    file: 'govt_inspection_report',
                                    params: { govt_inspection_sheet_id: id,
                                              QueryCondition: 'govt_inspection_pallets.passed is true',
                                              keep_file: false })
      if res.success
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # GOVT INSPECTION SHEET FAILED
    # --------------------------------------------------------------------------
    r.on 'failed_inspection_report', Integer do |id|
      res = CreateJasperReport.call(report_name: 'govt_inspection_report',
                                    user: current_user.login_name,
                                    file: 'govt_inspection_report',
                                    params: { govt_inspection_sheet_id: id,
                                              QueryCondition: 'govt_inspection_pallets.passed is false',
                                              keep_file: false })
      if res.success
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # GOVT FINDING SHEET
    # --------------------------------------------------------------------------
    r.on 'finding_sheet', Integer do |id|
      res = CreateJasperReport.call(report_name: 'govt_finding_sheet',
                                    user: current_user.login_name,
                                    file: 'govt_finding_sheet',
                                    parent_folder: AppConst::RPT_INDUSTRY,
                                    params: { govt_inspection_sheet_id: id,
                                              QueryCondition: 'govt_inspection_pallets.passed is false',
                                              keep_file: false })
      if res.success
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
