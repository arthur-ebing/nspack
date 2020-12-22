# frozen_string_literal: true

Dir['./routes/messcada/*.rb'].sort.each { |f| require f }

class Nspack < Roda
  route('messcada') do |r|
    store_current_functional_area('raw materials')

    r.on 'whoami' do
      code = ProductionApp::ResourceRepo.new.get_value(:system_resources, :system_resource_code, ip_address: request.ip)
      if code.nil?
        # if request.ip == '172.16.145.68'
        #   'ITPC-901'
        # else
        response.status = 404
        ''
        # end
      else
        code
      end
    end

    r.multi_route('messcada')
  end
end
