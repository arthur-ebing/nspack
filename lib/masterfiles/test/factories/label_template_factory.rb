# frozen_string_literal: true

module MasterfilesApp
  module LabelTemplateFactory
    def create_label_template(opts = {})
      default = {
        label_template_name: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        application: Faker::Lorem.word,
        variables: BaseRepo.new.array_of_text_for_db_col(%w[A B C]),
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:label_templates].insert(default.merge(opts))
    end
  end
end
