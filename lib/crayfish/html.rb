# Copyright (c) 2012 Bingoentreprenøren AS
# Copyright (c) 2012 Patrick Hanevold
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'nokogiri'

module Prawn
  class Table
    class Cell
      class Subtable
        # prawn suicide prevention
        def inline_format= something
        end
      end
    end

    def crayfish_debug_dump node
      if node.kind_of? Prawn::Table
        (0..node.row_length).map do |n|
          crayfish_debug_dump node.row(n).map{ |c| crayfish_debug_dump c }
        end
      elsif node.kind_of? Prawn::Table::Cell::Text
        node.content
      elsif node.kind_of? Array
        node.map{ |c| crayfish_debug_dump c }
      elsif node.kind_of? String
        node
      elsif node.kind_of? Fixnum
        node
      elsif node.kind_of? Hash
        node.map{ |k,v| [k,crayfish_debug_dump(v)] }
      else
        node.class.name
      end
    end

    # inspect with human readable output
    def inspect
      "<Prawn::Table #{crayfish_debug_dump(self).inspect}>"
    end

    attr_accessor :post_resize
  end
end

module Crayfish
  class Html

    attr_reader :pdf

    def initialize fish,pdf
      @fish    = fish
      @pdf     = pdf
    end

    def asset_paths
      @@asset_paths ||= ::ActionView::Helpers::AssetTagHelper::AssetPaths.new(::Rails.configuration.action_controller)
    end

    def public_path_to_fs_path path
      if /^(?<stripped>[^\?]*)\?[0-9]*$/ =~ path
        path = stripped
      end

      search_paths = [::Rails.public_path] + ::Rails.configuration.assets.paths
      search_paths.each do |search_path|
        if File.exists?("#{search_path}/#{path}")
          return "#{search_path}/#{path}"
        end
      end

      if /^\/assets\/(?<path>.*)$/ =~ path
        search_paths.each do |search_path|
          if File.exists?("#{search_path}/#{path}")
            return "#{search_path}/#{path}"
          end
        end
      end
      raise "Could not locate #{path} in #{search_paths.inspect}"
    end

    def image_fs_path image
      public_path = asset_paths.compute_public_path(image, 'images')
      public_path_to_fs_path(public_path)
    end

    def apply_style cell,style
      # background-color:#ccccff
      style.split(';').each do |style|
        if /^background-color:#(?<color>.*)$/ =~ style
          cell.background_color = color
        end
      end
    end

    def traverse_children node,path,params={ :table => nil, :tr => nil }
      count = {}
      node.children.each{ |node| count[node.name.to_sym] = (count[node.name.to_sym]||0) + 1 }
      counters = Hash[*count.map{ |k,v| [k,0] }.flatten]
      node.children.map do |node|
        postfix = ''
        if count[node.name.to_sym] > 1
          postfix = "[#{counters[node.name.to_sym]}]"
          counters[node.name.to_sym] += 1
        end
        compile node, "#{path}/#{node.name}#{postfix}", '', params
      end
    end

    def style cell,node,scope
      cell[:colspan] = node.attributes['colspan'].value.to_i if node.attributes['colspan']
      cell[:rowspan] = node.attributes['rowspan'].value.to_i if node.attributes['rowspan']
      cell[:valign]  = :center if cell[:rowspan]
      cell[:align]   = node.attributes['align'].value.to_sym if node.attributes['align']
      scope[:table_styles] << { :row => scope[:table].size, :col => scope[:tr].size, :style => node.attributes['style'].value } if node.attributes['style']
    end

    def compile node, path = "/#{node.name}", postfix='',scope={ :table => nil, :tr => nil }
      name = node.name.to_sym

      case name
      when :img
        image = { :image =>  image_fs_path(node.attributes['src'].value) }
        image[:width]  = node.attributes['width'].value.to_f  if node.attributes['width']
        image[:height] = node.attributes['height'].value.to_f if node.attributes['height']
        return image

      when :table
        table = []
        table_styles = []
        traverse_children node, "#{path}#{postfix}", :table => table, :table_styles => table_styles, :tr => nil

        # apply style
        full_width = 540
        attribs = { :cell_style => { :inline_format => true } }
        if node.attributes['width'] and /^(?<percent>.*)%$/ =~ node.attributes['width'].value
          attribs[:post_resize] = "#{percent}%"
        end
        attribs[:cell_style][:borders] = [] if node.attributes['border'] and node.attributes['border'].value=='0'

        pdf_table = @pdf.make_table(table, attribs)
        table_styles.each do |style|
          apply_style(pdf_table.row(style[:row]).column(style[:col]),style[:style]) 
        end
        scope[:td] << pdf_table if scope[:td]
        return pdf_table

      when :tbody
        traverse_children node, "#{path}#{postfix}", :table => scope[:table], :table_styles => scope[:table_styles], :tr => nil
        return

      when :tr
        row = []
        traverse_children node, "#{path}#{postfix}", :table => scope[:table], :table_styles => scope[:table_styles], :tr => row
        scope[:table] << row
        return :tr => row

      when :td
        cells = []
        traverse_children node, "#{path}#{postfix}", :table => scope[:table], :table_styles => scope[:table_styles], :tr => scope[:tr], :td => cells
        if cells.size <= 1
          cells << "" if cells.size == 0
          cell = { :content => cells.first.kind_of?(String) ? cells.first.strip : cells.first }
          style cell,node,scope
          scope[:tr] << cell
        else
          scope[:tr] << cells
        end
        return

      when :th
        cells = []
        traverse_children node, "#{path}#{postfix}", :table => scope[:table], :table_styles => scope[:table_styles], :tr => scope[:tr], :td => cells
        if cells.size <= 1
          cells << "" if cells.size == 0
          cell = { :content => "<b>#{cells.first.strip}</b>", :align => :center }
          style cell,node,scope
          scope[:tr] << cell
        else
          scope[:tr] << cells
        end
        return

      when :text
        if scope[:td] and node.content.strip.size > 0
          scope[:td] << node.content.strip
        end
      when :html
      when :body
      else
        ::Rails.logger.debug "\e[1;31munknown node #{node.name} in CrayHtml\e[0m"
      end

      traverse_children node, "#{path}#{postfix}"
    end

    def post_resize node,parent_width
      if node.kind_of?(Prawn::Table::Cell::Subtable)
        post_resize node.subtable,parent_width
      elsif node.kind_of?(Prawn::Table)
        if node.post_resize
          if /^(?<size>.*)%$/ =~ node.post_resize
            new_width = parent_width * size.to_f / 100.0
            column_widths = node.column_widths.dup
            scale = new_width / column_widths.sum
            node.instance_variable_set '@column_widths', nil

            # reset constraints
            (0..node.row_length).map do |n|
              row = node.row(n).columns(0..-1)
              row.each_with_index do |cell,i|
                 cell.instance_variable_set '@max_width', column_widths[i]*scale
              end
            end
            node.width = new_width
            node.send(:set_column_widths)
            node.send(:position_cells)
          end
        end

        column_widths = node.column_widths
        (0..node.row_length).map do |n|

          row = node.row(n).columns(0..-1)
          
          row.each_with_index do |cell,i|
            colspan = 1
            row.to_a[i+1..-1].each do |cell|
              break unless cell.kind_of?(Prawn::Table::Cell::SpanDummy)
              colspan += 1
            end
            post_resize cell,column_widths[i..(i+colspan-1)].sum
          end
        end
      elsif node.kind_of? Array
        node.each{ |c| post_resize c,parent_width }
      elsif node.kind_of? Hash
        node.each do |k,v|
          post_resize v,parent_width
        end
      end
    end

    def draw text
      doc = Nokogiri::HTML(text)

      doc.children.map do |element|
        compile element
      end.flatten.each do |prawn|
        if prawn.kind_of? Hash
          if prawn.has_key? :image
            pdf.image prawn[:image], prawn
          end
        else
          post_resize prawn,540
          prawn.draw
        end
      end
    end

  end
end
