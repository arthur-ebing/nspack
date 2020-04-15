# frozen_string_literal: true

Dir['./routes/masterfiles/*.rb'].sort.each { |f| require f }

class Nspack < Roda
  route('masterfiles') do |r|
    store_current_functional_area('masterfiles')
    r.multi_route('masterfiles')
  end
end
