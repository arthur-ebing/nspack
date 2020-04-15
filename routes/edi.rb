# frozen_string_literal: true

Dir['./routes/edi/*.rb'].sort.each { |f| require f }

class Nspack < Roda
  route('edi') do |r|
    store_current_functional_area('edi')
    r.multi_route('edi')
  end
end
