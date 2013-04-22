require_relative '../menagerie_generator'

module MenagerieGenerator
  class Page
    def initialize title="", base_path="/"
      @title = title
      @base = Pathname.new base_path
    end


    def content= c
      @content = c
    end

    def write path
      header(path) << content << footer
    end

    private
      attr_reader :title, :content, :base

      def header path
        path = Pathname.new path
        %Q{<!doctype html>
           <meta name="viewport" content="initial-scale=1.0, width=device-width" />
           <link rel="stylesheet" type="text/css" media="screen, projection" href="#{base.relative_path_from(path)}/css/style.css" />
           <title>#{title}</title>

           <div class="content">
        }
      end

      def footer
        %Q{ </div> }
      end
  end
end
