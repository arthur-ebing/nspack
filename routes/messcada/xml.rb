# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda
  route 'xml', 'messcada' do |r|
    response['Content-Type'] = 'application/xml'
    xml_interpreter = MesscadaXMLInterpreter.new(request)
    interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})

    # --------------------------------------------------------------------------
    # BIN TIPPING FROM MAF
    # --------------------------------------------------------------------------
    r.on 'bin_tipping' do
      r.post 'can_dump' do
        params = xml_interpreter.params_for_can_bin_be_tipped
        res = interactor.can_tip_bin?(params)
        if res.success
          %(<ContainerMove PID="200" Mode="5" Status="true" RunNumber="#{res.instance[:run_id]}" Red="false" Yellow="false" Green="true" Msg="#{res.message}" />)
        else
          %(<ContainerMove PID="200" Mode="5" Status="false" RunNumber="" Red="true" Yellow="false" Green="false" Msg="#{res.message}" />)
        end
      end

      r.post 'dump' do
        params = xml_interpreter.params_for_tipped_bin
        res = interactor.tip_rmt_bin(params)
        if res.success
          %(<ContainerMove PID="200" Mode="6" Status="true" RunNumber="#{res.instance[:run_id]}" Red="false" Yellow="false" Green="true" Msg="#{res.message}" />)
        else
          %(<ContainerMove PID="200" Mode="6" Status="false" RunNumber="" Red="true" Yellow="false" Green="false" Msg="#{res.message}" />)
        end
      end
    end

    # --------------------------------------------------------------------------
    # CARTON LABELING FROM MAF / ITPC (LINE SCANNING)
    # --------------------------------------------------------------------------
    r.on 'carton_labeling' do
      r.is do
        r.post do
          params = xml_interpreter.params_for_carton_labeling
          res = MesscadaApp::AddSystemResourceIncentiveToParams.call(params)
          res = interactor.xml_carton_labeling(res.instance) if res.success
          if res.success
            res.instance
          else
            %(<ProductLabel PID="223" Status="false" Threading="true" LabelRenderAmount="0" Msg="#{res.message}" />)
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
