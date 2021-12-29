# frozen_string_literal: true

module LabelApp
  class LabelRepo < BaseRepo
    crud_calls_for :multi_labels, name: :multi_label
    crud_calls_for :label_publish_logs, name: :label_publish_log, wrapper: LabelPublishLog
    crud_calls_for :label_publish_log_details, name: :label_publish_log_detail, wrapper: LabelPublishLogDetail
    crud_calls_for :label_publish_notifications, name: :label_publish_notification, wrapper: LabelPublishNotification

    def find_label(id)
      find_with_association(:labels, id,
                            wrapper: Label,
                            sub_tables: [{ sub_table: :label_images,
                                           one_to_one: { png_image: :png_image } }])
    end

    def create_label(attrs)
      png_image = attrs.delete(:png_image)
      id = create(:labels, attrs)
      create(:label_images, label_id: id, png_image: png_image) if png_image
      id
    end

    def update_label(id, attrs)
      png_image = attrs.delete(:png_image)
      update(:labels, id, attrs)
      DB[:label_images].where(label_id: id).update(png_image: png_image) if png_image
    end

    def delete_label(id)
      DB[:label_images].where(label_id: id).delete
      delete(:labels, id)
    end

    def delete_label_with_sub_labels(id)
      DB.transaction do
        DB[:multi_labels].where(label_id: id).delete
        delete_label(id)
      end
    end

    def sub_label_list(sub_label_ids)
      DB[:labels].select(:id, :label_name)
                 .where(id: sub_label_ids)
                 .map { |r| [r[:label_name], r[:id]] }
    end

    def link_multi_label(id, sub_label_ids)
      DB.transaction do
        DB[:multi_labels].where(label_id: id).delete

        sub_label_ids.split(',').each_with_index do |sub_label_id, index|
          create_multi_label(label_id: id,
                             sub_label_id: sub_label_id,
                             print_sequence: index + 1)
        end
      end
    end

    # Number of sub labels on a multi label.
    #
    # @param id [integer] the multi label id.
    # @return [integer] the count of sub labels.
    def no_sub_labels(id)
      DB[:multi_labels].where(label_id: id).count
    end

    # Get all the label ids of sub labels for a multi label.
    #
    # @param id [integer] the multi label id.
    # @return [Array] the ids of the sub labels.
    def sub_label_ids(id)
      DB[:multi_labels].where(label_id: id).order(:print_sequence).select_map(:sub_label_id)
    end

    # Get a list of multi labels that this label is a sub-label of.
    # Only return active labels.
    #
    # @param id [integer] the sub label id.
    # @return [Array] the label names of the multi labels.
    def sub_label_belongs_to_names(id)
      DB[:multi_labels].join(:labels, id: :label_id)
                       .where(sub_label_id: id, active: true)
                       .order(:label_name)
                       .select_map(:label_name)
    end

    # Re-build the sample data for a multi label from its sub-labels.
    def refresh_multi_label_variables(id)
      datalist = DB[:multi_labels].join(:labels, id: :sub_label_id)
                                  .where(label_id: id)
                                  .order(:print_sequence)
                                  .select(:sample_data)
                                  .map { |a| a[:sample_data] || {} }
      update_label(id, sample_data: hash_for_jsonb_col(new_sample(datalist)))
    end

    def label_publish_states(label_publish_log_id)
      query = <<~SQL
        SELECT l.label_name, d.server_ip, d.destination, d.status, d.errors, d.complete, d.failed
          FROM label_publish_log_details d
          JOIN labels l ON l.id = d.label_id
          WHERE d.label_publish_log_id = ?
          ORDER BY d.destination, l.label_name
      SQL
      DB[query, label_publish_log_id].all
    end

    def published_label_lookup(label_publish_log_id)
      query = <<~SQL
        SELECT DISTINCT l.id, l.label_name
        FROM label_publish_log_details p
        JOIN labels l ON l.id = p.label_id
        WHERE p.label_publish_log_id = ?
      SQL
      Hash[DB[query, label_publish_log_id].map { |r| [r[:label_name], r[:id]] }]
    end

    def published_label_conditions(label_publish_log_id)
      complete_query = <<~SQL
        SELECT COUNT(id)
          FROM public.label_publish_log_details
          WHERE label_publish_log_id = ?
            AND NOT complete
      SQL

      fail_query = <<~SQL
        SELECT COUNT(id)
          FROM public.label_publish_log_details
          WHERE label_publish_log_id = ?
            AND failed
      SQL

      complete = DB[complete_query, label_publish_log_id].get.zero?
      failed = DB[fail_query, label_publish_log_id].get.positive?
      [complete, failed]
    end

    def published_label_ids_for(log_id)
      DB[:label_publish_log_details].distinct.where(label_publish_log_id: log_id, complete: true, failed: false).select_map(:label_id)
    end

    def create_label_publish_notifications(label_publish_log_id, label_ids, urls)
      urls.each do |url|
        label_ids.each do |label_id|
          create_label_publish_notification(label_publish_log_id: label_publish_log_id, label_id: label_id, url: url)
        end
      end
    end

    def label_publishing_user_login_name(label_publish_log_id)
      name = get(:label_publish_logs, label_publish_log_id, :user_name)
      get_value(:users, :login_name, user_name: name)
    end

    def check_label_for_unset_variables(id)
      multi = get(:labels, id, :multi_label)
      if multi
        res = nil
        DB[:multi_labels].where(label_id: id).select_map(:sub_label_id).each do |label_id|
          res = check_sub_label_for_unset_variables(label_id)
          return res unless res.success
        end
      else
        res = check_sub_label_for_unset_variables(id)
      end
      res
    end

    def check_sub_label_for_unset_variables(id) # rubocop:disable Metrics/AbcSize
      label_json = get(:labels, id, :label_json)
      hash = JSON.parse(label_json)
      json = UtilityFunctions.symbolize_keys(hash)
      return ok_response if json[:version].nil?

      unset = false
      json[:nodes].each do |node|
        next unless node[:name] == 'variableBox'
        next unless node[:varAttrs][:staticValue].nil?

        unset = true if node[:varType] == 'unset'
      end
      unset ? failed_response('Cannot complete - this label has unset variables') : ok_response
    end

    def archive_template(label_id, active: true, user_name: nil)
      template_id = DB[:label_templates].where(label_template_name: get_value(:labels, :label_name, id: label_id)).get(:id)
      return if template_id.nil?

      update(:label_templates, template_id, active: active)
      status = if active
                 'UN-ARCHIVED'
               else
                 'ARCHIVED'
               end
      log_status(:label_templates, template_id, status, comment: nil, user_name: user_name)
    end

    private

    # Re-combine F-numbers:
    # { F1, F2, F3 }, { F1, F2 } => { F1, F2, F3, F4, F5 }
    def new_sample(datalist)
      new_vars = {}
      cnt = 0
      offsets = datalist.map { |a| cnt += a.length }
      offsets.unshift(0)

      datalist.each_with_index do |data, index|
        data.each do |key, val|
          no = key.delete('F').to_i + offsets[index]
          new_vars["F#{no}"] = val
        end
      end
      new_vars
    end
  end
end
