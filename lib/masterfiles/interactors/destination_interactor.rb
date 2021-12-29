# frozen_string_literal: true

module MasterfilesApp
  class DestinationInteractor < BaseInteractor
    def create_region(params)
      res = validate_region_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_region(res)
      end
      instance = region(id)
      success_response("Created destination region #{instance.destination_region_name}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { destination_region_name: ['This destination region already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_region(id, params)
      res = validate_region_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_region(id, res)
      end
      instance = region(id)
      success_response("Updated destination region #{instance.destination_region_name}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_region(id)
      name = region(id).destination_region_name
      repo.transaction do
        repo.delete_region(id)
      end
      success_response("Deleted destination region #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete destination region. It is still referenced#{e.message.partition('referenced').last}")
    end

    def create_country(id, params)
      res = validate_country_params(params)
      return validation_failed_response(res) if res.failure?

      country_id = nil
      repo.transaction do
        country_id = repo.create_country(id, res)
      end
      instance = country(country_id)
      success_response("Created destination country #{instance.country_name}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { country_name: ['This destination country already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_country(id, params)
      res = validate_country_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_country(id, res)
      end
      instance = country(id)
      success_response("Updated destination country #{instance.country_name}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_country(id)
      name = country(id).country_name
      repo.transaction do
        repo.delete_country(id)
      end
      success_response("Deleted destination country #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete destination country. It is still referenced#{e.message.partition('referenced').last}")
    end

    def create_city(id, params)
      res = validate_city_params(params)
      return validation_failed_response(res) if res.failure?

      city_id = nil
      repo.transaction do
        city_id = repo.create_city(id, res)
      end
      instance = city(city_id)
      success_response("Created destination city #{instance.city_name}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { city_name: ['This destination city already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_city(id, params)
      res = validate_city_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_city(id, res)
      end
      instance = city(id)
      success_response("Updated destination city #{instance.city_name}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_city(id)
      name = city(id).city_name
      repo.transaction do
        repo.delete_city(id)
      end
      success_response("Deleted destination city #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete destination city. It is still referenced#{e.message.partition('referenced').last}")
    end

    private

    def repo
      @repo ||= DestinationRepo.new
    end

    def region(id)
      repo.find_region(id)
    end

    def validate_region_params(params)
      RegionSchema.call(params)
    end

    def country(id)
      repo.find_country(id)
    end

    def validate_country_params(params)
      CountrySchema.call(params)
    end

    def city(id)
      repo.find_city(id)
    end

    def validate_city_params(params)
      CitySchema.call(params)
    end
  end
end
