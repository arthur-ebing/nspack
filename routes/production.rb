# frozen_string_literal: true

Dir['./routes/production/*.rb'].sort.each { |f| require f }

class Nspack < Roda
  route('production') do |r|
    store_current_functional_area('production')
    r.multi_route('production')
  end
end
