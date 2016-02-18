require 'active_record'
require 'memory_model'

module ApiHelper
  class SimpleObjectApi
    attr_reader :name, :spec, :model

    def initialize(name, spec)
      @name       = name
      @spec       = spec
      create_model
      create_api
      seed(count: 0)
    end

    def create_api(&block)
      block ||= proc {}
      helper = self
      spec.let!(:app) do
        seed
        spec = self
        Class.new JSONAPIonify::Api::Base do
          define_resource(helper.name) do
            instance_exec(spec.model, &block)
          end
        end
      end
      self
    end

    def create_model(&block)
      block ||= proc {}
      spec.let!(:model) do
        klass = Class.new(MemoryModel::Base) do
          primary_key

          def id
            _uuid_
          end

          instance_eval(&block)
        end
        stub_const('MySimpleObjectApi', klass)
      end
      self
    end

    def seed(count:, &block)
      block ||= proc {}
      spec.let!(:seed) do
        count.times.map do
          model.new.tap(&block).save
        end
      end
      self
    end

  end

  class ActiveRecordApi < SimpleObjectApi
    attr_reader :table_name

    def initialize(*args)
      super
      @table_name = "_spec_#{name}"
      create_table
    end

    def create_table(&block)
      block ||= proc {}
      helper = self
      spec.let!(:migration) do
        Class.new ActiveRecord::Migration do
          suppress_messages do
            drop_table helper.table_name rescue nil
            create_table helper.table_name, &block
          end
        end
      end
      self
    end

    def seed(count:, &block)
      block ||= proc {}
      spec.let!(:seed) do
        instances = count.times.map do
          model.new.tap(&block)
        end
        model.import instances
      end
      self
    end

    def create_model(&block)
      block ||= proc {}
      helper = self
      spec.let!(:model) do
        migration
        Class.new(ActiveRecord::Base) do
          self.table_name = helper.table_name
          instance_eval(&block)
        end
      end
      self
    end
  end

  def active_record_api(name)
    ActiveRecordApi.new(name, self)
  end

  def simple_object_api(name)
    SimpleObjectApi.new(name, self)
  end
end
