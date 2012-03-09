# Copyright (c) 2012 Bingoentrepenøren AS
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

module Crayfish
  class CrayContainer

    attr_accessor :raw
    attr_reader :options,:tokens,:pdf

    def initialize fish, pdf, options = {}
      @fish    = fish
      @pdf     = pdf
      @raw     = []
      @options = options
      @tokens = { :span => options[:span] || /%\|/, :element => options[:element] || /%c{(?<content>[^}]*)}/ }
    end

    def append stuff, options={}
      @raw << stuff
    end

    def field str
      "%c{#{str}}"
    end

    def span
      '%|'
    end

    def row *args, &block
      raise "row must have block" unless block_given?
      row = CrayRow.new(@fish,pdf,self)
      block.call row
      row.draw ''
    end

    def row_for *args, &block
      raise "row_for must have block" unless block_given?
      row = CrayRow.new(@fish,pdf,self,args.first)
      block.call row
      row.draw ''
    end

  end
end
