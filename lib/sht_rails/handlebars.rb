require "handlebars"
require "active_support"

module ShtRails

  module Handlebars
    def self.call(template)
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
  end
end

ActiveSupport.on_load(:action_view) do
  ActionView::Template.register_template_handler(::ShtRails.template_extension.to_sym, ::ShtRails::Handlebars)
end