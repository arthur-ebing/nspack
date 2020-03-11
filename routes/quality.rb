# frozen_string_literal: true

Dir['./routes/quality/*.rb'].each { |f| require f }

class Nspack < Roda
  route('quality') do |r|
    store_current_functional_area('Quality')
    r.multi_route('quality')
  end
end
