module ActiveRecord #:nodoc:
  module ConnectionAdapters #:nodoc:
    module OracleEnhancedDirty #:nodoc:

      module InstanceMethods
        private
        
        def field_changed?(attr, old, value)
          if column = column_for_attribute(attr)
            # RSI: added also :decimal type
            if (column.type == :integer || column.type == :decimal) && column.null && (old.nil? || old == 0) && value.blank?
              # For nullable integer columns, NULL gets stored in database for blank (i.e. '') values.
              # Hence we don't record it as a change if the value changes from nil to ''.
              # If an old value of 0 is set to '' we want this to get changed to nil as otherwise it'll
              # be typecast back to 0 (''.to_i => 0)
              value = nil
            # RSI: Oracle stores empty string '' or empty text (CLOB) as NULL
            # therefore need to convert empty string value to nil if old value is nil
            elsif (column.type == :string || column.type == :text) && column.null && old.nil?
              value = nil if value == ''
            else
              value = column.type_cast(value)
            end
          end

          old != value
        end
        
      end

    end
  end
end

if ActiveRecord::Base.instance_methods.include?('changed?')
  ActiveRecord::Base.class_eval do
    include ActiveRecord::ConnectionAdapters::OracleEnhancedDirty::InstanceMethods
  end
end