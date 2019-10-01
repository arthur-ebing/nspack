# frozen_string_literal: true

Dir['./routes/messcada/*.rb'].each { |f| require f }

class Nspack < Roda
  route('messcada') do |r|
    store_current_functional_area('raw materials')
    r.multi_route('messcada')
  end
end
