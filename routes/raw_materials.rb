# frozen_string_literal: true

Dir['./routes/raw_materials/*.rb'].sort.each { |f| require f }

class Nspack < Roda
  route('raw_materials') do |r|
    store_current_functional_area('raw materials')
    r.multi_route('raw_materials')
  end
end
