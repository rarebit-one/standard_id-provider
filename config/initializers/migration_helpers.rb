# Monkey patch ActiveRecord::Migration to add primary_key_type and foreign_key_type methods
module ActiveRecord
  class Migration
    class << self
      def primary_and_foreign_key_types
        config = Rails.configuration.generators
        config.options[config.orm][:primary_key_type] || :bigint
      end

      def primary_key_type
        primary_and_foreign_key_types
      end

      def foreign_key_type
        primary_and_foreign_key_types
      end
    end

    # Make these methods available as instance methods too
    def primary_and_foreign_key_types
      self.class.primary_and_foreign_key_types
    end

    def primary_key_type
      self.class.primary_key_type
    end

    def foreign_key_type
      self.class.foreign_key_type
    end
  end
end
