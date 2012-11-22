require 'tilt'

module ShtRails
  class Tilt < Tilt::Template
    def self.default_mime_type
      'application/javascript'
    end

    def prepare
      @namespace = "this.#{ShtRails.template_namespace}"
    end

    attr_reader :namespace

    def evaluate(scope, locals, &block)
      template_key = path_to_key scope
      partial_name = template_key.gsub(%r(/), ".")
      <<-HandlebarsTemplate
  (function() { 
  #{namespace} || (#{namespace} = {});
  #{namespace}CachedShtTemplates || (#{namespace}CachedShtTemplates = {});
  #{namespace}CachedShtTemplates[#{template_key.inspect}] = Handlebars.compile(#{data.inspect});
  Handlebars.registerPartial(#{partial_name.inspect}, #{data.inspect});
  #{namespace}[#{template_key.inspect}] = function(object) {
    if (object == null){
      return #{ShtRails.template_namespace}CachedShtTemplates[#{template_key.inspect}];
    } else {
      return #{ShtRails.template_namespace}CachedShtTemplates[#{template_key.inspect}](object);
    }
  };
  }).call(this);
      HandlebarsTemplate
    end
    
    def path_to_key(scope)
      path = scope.logical_path.to_s.split('/')
      path.last.gsub!(/^_/, '')
      path.join('/')
    end
  end
end