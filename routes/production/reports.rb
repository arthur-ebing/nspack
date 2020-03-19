# frozen_string_literal: true

class Nspack < Roda
  route 'reports', 'production' do |r|
    # AGGREGATE PACKOUT REPORT
    # --------------------------------------------------------------------------
    r.on 'aggregate_packout' do
      show_page { Production::Reports::Packout::Edit.call }
    end

    r.on 'aggregate_packout_print' do
      attrs = params[:packout_report]
      res = CreateJasperReport.call(report_name: 'packout_summary',
                                    user: current_user.login_name,
                                    file: 'packout_summary',
                                    params: { FromDate: "#{attrs[:from_date]} 00:00:00|date",
                                              ToDate: "#{attrs[:to_date]} 00:00:00|date",
                                              detail_level: attrs[:detail_level] == 't' ? 'Detail' : 'Summary',
                                              keep_file: false })
      if res.success
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end
  end
end
