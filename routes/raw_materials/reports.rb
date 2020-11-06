# frozen_string_literal: true

class Nspack < Roda
  route 'reports', 'raw_materials' do |r|
    @repo = BaseRepo.new
    # DELIVERY NOTE
    # --------------------------------------------------------------------------
    r.on 'bin_load', Integer do |id|
      jasper_params = JasperParams.new('bin_loads',
                                       current_user.login_name,
                                       bin_load_id: id)
      res = CreateJasperReportNew.call(jasper_params)

      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end
  end
end
