require 'active_support/lazy_load_hooks'
require 'active_support/inflector'

require 'rvt/engine'
require 'rvt/slave'

module RVT
  # Shortcut for +RVT::Engine.config.rvt+.
  def self.config
    Engine.config.rvt
  end

  ActiveSupport.run_load_hooks(:rvt, self)
end

# Inflect the name as an acronym to help Rails auto loading find constants
# under +RVT::+ instead of +Rvt::+.
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'RVT'
end
