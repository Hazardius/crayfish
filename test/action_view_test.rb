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

require 'test_helper'

class CrayfishActionViewTest < ActiveSupport::TestCase

  class Response
    def content_type
      'pdf'
    end

    def content_type= val
    end

    def headers
      @headers ||= {}
    end
  end

  class ActionController
    include Crayfish::ActionController

    def response
      @response ||= Response.new
    end

    def headers
      response.headers
    end

    def options
      { :html => true }
    end
  end

  class ActionView
    include Crayfish::ActionView

    def controller
      @controller ||= ActionController.new
    end
  end

  def setup
    @view = ActionView.new
    @view.send(:setup)
  end

  test "forced html paint" do
    assert_equal @view.send(:paint,'plain',true), 'plain'
  end

  test "should not flush output bufer in HTML mode" do
    @view.send(:output_buffer) << "A"
    @view.send(:flush)
    assert_equal @view.send(:output_buffer), 'A'
  end

  test "should flush output bufer in PDF mode" do
    ActionController.any_instance.stubs(:options).returns({})
    view = ActionView.new
    view.send(:setup)

    view.send(:output_buffer) << "A"
    view.send(:flush)
    assert_equal view.send(:output_buffer), ''
  end

end
