require 'faraday'
require 'active_support/concern'

module JSONAPIObjects
  module IncludesHelper
    extend ActiveSupport::Concern

    included do
      # Fetch includes if they are specified
      set_callback :initialize, :after do
        @includes = []
      end
      set_callback :compile, :before, :fetch_includes
    end

    def includes_string(str)
      str.split(',').each do |substr|
        includes *substr.split('.').map(&:to_sym)
      end
    end

    def includes(*children)
      @includes << children
    end

    def included_referenced?
      self[:included].to_a.all? do |resource|
        all_relationship_data.any? do |data|
          data[:id] == resource[:id] &&
            data[:type] == resource[:type]
        end
      end
    end

    def fetch_includes
      rels      = @includes.each_with_object([]) do |(parent_name, *), rels|
        all_relationships.each do |name, rel|
          rels << [rel] if name == parent_name
        end
      end
      responses = []
      connection.in_parallel do
        rels.each do |rel|
          connection.get(rel[:links])
        end
      end
    end

    def all_relationship_data
      all_relationships.values.flatten.compact.map { |r| r[:data] }
    end

    def all_relationships
      data_obj = Array.wrap(self[:data]).compact
      data_obj.each_with_object([]) do |resource, ary|
        relationships = resource[:relationships]
        next unless relationships.present?
        ary.concat relationships.to_a
      end
    end

    def connection
      Faraday.new do |faraday|
        faraday.adapter :typhoeus
      end
    end
  end
end