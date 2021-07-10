# frozen_string_literal: true

Dir['./routes/debug/*.rb'].sort.each { |f| require f }

class Nspack < Roda
  route('debug') do |r|
    store_current_functional_area('development')
    r.multi_route('debug')
  end
end
