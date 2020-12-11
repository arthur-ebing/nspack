# frozen_string_literal: true

class Nspack < Roda
  route 'xml', 'messcada' do |r|
    # --------------------------------------------------------------------------
    # CARTON LABELING FROM MAF
    # --------------------------------------------------------------------------
    r.on 'carton_labeling' do
      response['Content-Type'] = 'application/xml'

      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.is do
        r.post do
          schema = Nokogiri::XML(request.body.gets)
          device = schema.xpath('.//ProductLabel').attribute('Module').value
          identifier = schema.xpath('.//ProductLabel').attribute('Input2').value
          # TODO: Input1 is the scan code representing the "pack button" (if this is in format "B1", we can use it as the button...
          params = { device: device, card_reader: '', identifier: identifier }
          res = MesscadaApp::AddSystemResourceIncentiveToParams.call(params, has_button: true)
          res = interactor.maf_carton_labeling(res.instance) if res.success
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
