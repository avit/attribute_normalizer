module AttributeNormalizer

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def normalize_attributes(*attributes, &block)
      options = attributes.last.is_a?(::Hash) ? attributes.pop : {}

      attributes.each do |attribute|

        klass = class << self; self end

        klass.send :define_method, "normalize_#{attribute}" do |value|
          value = value.strip if value.is_a?(String)
          normalized = block_given? && !value.blank? ? yield(value) : value
          normalized.blank? ? nil : normalized
        end

        klass.send :private, "normalize_#{attribute}"

        src = ""
        if options[:on] == :read || options.empty?
          src += <<-end_src
            def #{attribute}
              @normalized_attributes ||= {}
              @normalized_attributes[:#{attribute}] ||= self.class.send(:normalize_#{attribute}, self[:#{attribute}]) unless self[:#{attribute}].nil?
            end
          end_src
        end

        if options[:on] == :write || options.empty?
          src += <<-end_src
            def #{attribute}=(#{attribute})
              @normalized_attributes ||= {}
              @normalized_attributes[:#{attribute}] = self[:#{attribute}] = self.class.send(:normalize_#{attribute}, #{attribute})
            end
          end_src
        end
        module_eval src, __FILE__, __LINE__

      end

    end
  end
end
