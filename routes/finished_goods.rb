# frozen_string_literal: true

Dir['./routes/finished_goods/*.rb'].sort.each { |f| require f }

class Nspack < Roda
  route('finished_goods') do |r|
    store_current_functional_area('Finished Goods')
    r.multi_route('finished_goods')
  end
end
