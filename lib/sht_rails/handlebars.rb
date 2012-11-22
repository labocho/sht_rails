require "handlebars"
require "active_support"

module ShtRails

  module Handlebars
    def self.call(template)
      register_helpers
      register_partials
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

    # Register partial named "path.to.template"
    # If you have 'app/templates/foo/_bar.handlebars',
    # you can write `{{> foo/bar}}` or `{{> foo.bar}}` to use it.
    def self.register_partials
      Dir.chdir(ShtRails.template_base_path) do |dir|
        Dir.glob("**/*.#{ShtRails.template_extension}") do |path|
          # "foo/_bar.handlebars" -> "foo/bar"
          logical_name = File.join(
            File.dirname(path),
            File.basename(path, ".#{ShtRails.template_extension}").gsub(/^_?/, "")
          )
          # "foo/bar" -> "foo.bar"
          partial_name = logical_name.gsub(%r(/), ".")
          context.register_partial(partial_name, File.read(path))
        end
      end
    end
  end
end

ActiveSupport.on_load(:action_view) do
  ActionView::Template.register_template_handler(::ShtRails.template_extension.to_sym, ::ShtRails::Handlebars)
end
