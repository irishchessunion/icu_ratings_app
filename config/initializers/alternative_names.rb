# The icu_name gem only passes permitted_classes on Ruby 3+, but Psych 5.x
# enforces safe loading regardless of Ruby version. Temporarily allow Regexp.
module Psych
  class << self
    alias_method :_original_load, :load unless method_defined?(:_original_load)
    def load(yaml, *args, **kwargs)
      kwargs[:permitted_classes] = [Regexp] unless kwargs.key?(:permitted_classes)
      _original_load(yaml, *args, **kwargs)
    end
  end
end

# Load the default alternatives for the ICU::Name class.
%w[first last].each do |type|
  ICU::Name.load_alternatives(type)
end

# Restore original Psych.load
module Psych
  class << self
    alias_method :load, :_original_load if method_defined?(:_original_load)
  end
end
