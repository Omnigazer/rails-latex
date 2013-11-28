# -*- coding: utf-8 -*-
require 'fileutils'
require 'rails-latex/latex_to_pdf'
require 'rails-latex/latex_to_rtf'
require 'action_view'

module ActionView               # :nodoc: all
  module Template::Handlers
    class ERBLatex < ERB
      def self.call(template)
        new.compile(template)
      end

      def compile(template)
        erb = "<% __in_erb_template=true %>#{template.source}"
        _format = template.inspect.to_s.split(".erbtex")[0].split(".")[-1]
        out=self.class.erb_implementation.new(erb, :trim=>(self.class.erb_trim_mode == "-")).src
        case _format
        when "rtf" then
          out + ";LatexToRtf.generate_rtf(@output_buffer.to_s,@latex_config||{})"
        when "html" then
          out + ";LatexToHtml.generate_html(@output_buffer.to_s,@latex_config||{})"
        else
          out + ";LatexToPdf.generate_pdf(@output_buffer.to_s,@latex_config||{},@latex_parse_twice)"  
        end
      end
    end
  end
  Template.register_template_handler :erbtex, Template::Handlers::ERBLatex
end

