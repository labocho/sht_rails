require "handlebars"
require "active_support"

module ShtRails

  module Handlebars
    def self.call(template)
      register_helpers
      if template.locals.include?(ShtRails.action_view_key.to_s) || template.locals.include?(ShtRails.action_view_key.to_sym)
<<-SHT
  partials.each do |key, value|
    ::ShtRails::Handlebars.context.register_partial(key, value)
  end if defined?(partials) && partials.is_a?(Hash)
  ::ShtRails::Handlebars.context.compile(#{template.source.inspect}).call(#{ShtRails.action_view_key.to_s} || {}).html_safe
SHT
      else
        "#{template.source.inspect}.html_safe"
      end
    end

    def self.context
      @context ||= ::Handlebars::Context.new
    end

    def self.register_helpers
      return if ShtRails.cache_helpers && @helper_registered
      Dir.glob(ShtRails.template_helpers_path + "**/*") do |path|
        source = Rails.application.assets.find_asset(path).to_s
        context.handlebars.eval_js "Handlebars = this;\n" + source
      end
      @helper_registered = true
    end
  end
end

ActiveSupport.on_load(:action_view) do
  ActionView::Template.register_template_handler(::ShtRails.template_extension.to_sym, ::ShtRails::Handlebars)
end
