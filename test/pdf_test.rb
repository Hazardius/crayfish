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

class PDFTest < ActiveSupport::TestCase

  test 'merge options' do
    response = mock('Response')
    response.expects(:content_type).returns(nil)
    response.expects(:content_type=).with(Mime::PDF)

    headers = mock('Headers')
    headers.expects(:[]=).with('Content-Disposition', 'inline')

    controller = stub('Controller')
    controller.stubs(:options).returns(:controller => :options)
    controller.stubs(:response).returns(response)
    controller.stubs(:headers).returns(headers)

    pdf = Crayfish::Rails::PDF.new(controller)
    assert_equal pdf.options, :inline=>true, :prawn=>{}, :controller=>:options
  end

end