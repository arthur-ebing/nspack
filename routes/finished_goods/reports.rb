# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda
  route 'reports', 'finished_goods' do |r|
    # DELIVERY NOTE
    # --------------------------------------------------------------------------
    r.on 'delivery_note', Integer do |id|
      res = CreateJasperReport.call(report_name: 'dispatch_note',
                                    user: current_user.login_name,
                                    file: 'dispatch_note',
                                    params: { load_id: id,
                                              pallet_report: 'detail',
                                              for_picklist: 'false|boolean',
                                              keep_file: true })
      if res.success
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # DELIVERY NOTE - SUMMARISED
    # --------------------------------------------------------------------------
    r.on 'delivery_note_summarised', Integer do |id|
      res = CreateJasperReport.call(report_name: 'dispatch_note',
                                    user: current_user.login_name,
                                    file: 'dispatch_note',
                                    params: { load_id: id,
                                              pallet_report: 'summary',
                                              for_picklist: 'false|boolean',
                                              keep_file: true })
      if res.success
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # PICKLIST
    # --------------------------------------------------------------------------
    r.on 'piclklist', Integer do |id|
      res = CreateJasperReport.call(report_name: 'dispatch_note',
                                    user: current_user.login_name,
                                    file: 'dispatch_note',
                                    params: { load_id: id,
                                              pallet_report: 'detail',
                                              for_picklist: 'true|boolean',
                                              keep_file: true })
      if res.success
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
