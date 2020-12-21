# frozen_string_literal: true

Dir['./routes/messcada/*.rb'].sort.each { |f| require f }

class Nspack < Roda
  route('messcada') do |r|
    store_current_functional_area('raw materials')

    r.on 'whoami' do
      code = ProductionApp::ResourceRepo.new.get_value(:system_resources, :system_resource_code, ip_address: request.ip)
      if code.nil?
        response.status = 404
        ''
      else
        code
      end
    end

    r.multi_route('messcada')
  end
end
