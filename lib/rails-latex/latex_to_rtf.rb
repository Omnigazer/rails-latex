require 'iconv'
class LatexToRtf
  def self.config
    @config||={:command => 'latex2rtf', :arguments => ['-oreport.rtf']}
  end

  # Converts a string of LaTeX +code+ into a binary string of RTF.
  #
  # rtflatex is used to convert the file and creates the directory +#{Rails.root}/tmp/rails-latex/+ to store intermediate
  # files.
  #
  # The config argument defaults to LatexTortf.config but can be overridden using @latex_config.
  #
  # The parse_twice argument is deprecated in favor of using config[:parse_twice] instead.
  def self.generate_rtf(code,config)
    config=self.config.merge(config)
    # parse_twice=config[:parse_twice] if parse_twice.nil?
    dir=File.join(Rails.root,'tmp','rails-latex',"#{Process.pid}-#{Thread.current.hash}")
    input=File.join(dir,'input.tex')
    FileUtils.mkdir_p(dir)
    # copy any additional supporting files (.cls, .sty, ...)
    supporting = config[:supporting]
    if supporting.class == String or supporting.class == Array and supporting.length > 0
      FileUtils.cp(supporting, dir)
    end
    code = Iconv.conv('CP1251', 'UTF-8', code)
    File.open(input,'w:Windows-1251') {|io| io.write(code) }
    Process.waitpid(
      fork do
        begin
          Dir.chdir dir
          # STDOUT.reopen("input.log","a")
          STDERR.reopen(STDOUT)
          args=config[:arguments] + %w[input.tex]
          # system config[:command],'-draftmode',*args if parse_twice
          exec config[:command],*args
        rescue
          File.open("input.log",'w') {|io|
            io.write("#{$!.message}:\n#{$!.backtrace.join("\n")}\n")
          }
        ensure
          Process.exit! 1
        end
      end)
    if File.exist?(rtf_file=File.join(dir,'report.rtf'))
#      FileUtils.mv(input.sub(/\.tex$/,'.log'),File.join(dir,'..','input.log'))
      result = rtf_file
#      FileUtils.rm_rf(dir)
    else
      raise "rtflatex failed: See #{input.sub(/\.tex$/,'.log')} for details"
    end
    result
  end

  # Escapes LaTex special characters in text so that they wont be interpreted as LaTex commands.
  #
  # This method will use RedCloth to do the escaping if available.
  def self.escape_latex(text)
    # :stopdoc:
    unless @latex_escaper
      if defined?(RedCloth::Formatters::LATEX)
        class << (@latex_escaper=RedCloth.new(''))
          include RedCloth::Formatters::LATEX
        end
      else
        class << (@latex_escaper=Object.new)
          ESCAPE_RE=/([{}_$&%#])|([\\^~|<>])/
          ESC_MAP={
            '\\' => 'backslash',
            '^' => 'asciicircum',
            '~' => 'asciitilde',
            '|' => 'bar',
            '<' => 'less',
            '>' => 'greater',
          }

          def latex_esc(text)   # :nodoc:
            text.gsub(ESCAPE_RE) {|m|
              if $1
                "\\#{m}"
              else
                "\\text#{ESC_MAP[m]}{}"
              end
            }
          end
        end
      end
      # :startdoc:
    end

    @latex_escaper.latex_esc(text.to_s).html_safe
  end
end
