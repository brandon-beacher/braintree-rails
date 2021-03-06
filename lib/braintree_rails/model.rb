module BraintreeRails
  def self.use_relative_model_naming?
    true
  end

  module Model
    module ClassMethods
      def self.extended(receiver)
        receiver.class_eval do
          extend ::ActiveModel::Naming
          include ::ActiveModel::Validations
          include ::ActiveModel::Conversion
        end
      end
    end

    module InstanceMethods
      def ensure_model(model)
        model = case model
        when String
          self.persisted = true
          self.class.braintree_model_class.find(model)
        when self.class.braintree_model_class
          self.persisted = true
          model
        when Hash
          self.persisted = false
          OpenStruct.new(model)
        else
          self.persisted = model.respond_to?(:persisted?) ? model.persisted? : false
          model
        end
        assign_attributes(extract_values(model))
        model
      end

      def add_errors(validation_errors)
        validation_errors.each do |error|
          self.errors.add :base, error.message if error.attribute.to_s == "base"
          self.errors.add error.attribute, error.message if respond_to?(error.attribute)
        end
      end
    end

    def self.included(receiver)
      receiver.send :include, BraintreeRails::Attributes
      receiver.send :include, BraintreeRails::Persistence
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end
