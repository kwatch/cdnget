# -*- coding: utf-8 -*-

require 'stringio'

require 'minitest'
require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/ok'

require 'cdnget'


describe CDNGet do

  def capture_io(stdin=nil)
    bkup = [$stdin, $stdout, $stderr]
    $stdin  = StringIO.new(stdin || "")
    $stdout = StringIO.new
    $stderr = StringIO.new
    begin
      yield
      return $stdout.string(), $stderr.string()
    ensure
      $stdin, $stdout, $stderr = bkup
    end
  end


  describe 'cdnget [-h][--help]' do

    it "prints help message." do
      expected = CDNGet::Main.new("cdnget").help_message()
      ok {CDNGet::Main.new("cdnget").run("-h")}     == expected
      ok {CDNGet::Main.new("cdnget").run("--help")} == expected
    end

  end


  describe 'cdnget [-v][--version]' do

    it "prints help message." do
      expected = CDNGet::RELEASE + "\n"
      ok {CDNGet::Main.new("cdnget").run("-v")}        == expected
      ok {CDNGet::Main.new("cdnget").run("--version")} == expected
    end

  end


  describe 'cdnget' do

    it "lists CDN." do
      expected = <<END
cdnjs       # https://cdnjs.com/
jsdelivr    # https://www.jsdelivr.com/
google      # https://developers.google.com/speed/libraries/
unpkg       # https://unpkg.com/
#jquery      # https://code.jquery.com/
#aspnet      # https://www.asp.net/ajax/cdn/
END
      actual = CDNGet::Main.new().run()
      ok {actual} == expected.gsub(/^\#.*\n/, '')
    end

  end


  describe 'cdnget CDN' do

    it "(cdnjs) lists librareis." do
      actual = CDNGet::Main.new().run("cdnjs")
      ok {actual} =~ /^jquery                # JavaScript library for DOM operations$/
      ok {actual} =~ /^angular\.js            # AngularJS is an MVC framework for building web applications\./
      ok {actual} =~ /^ember\.js              # Ember is a JavaScript framework for creating ambitious web applications that eliminates boilerplate and provides a standard application architecture\./
    end

    it "(google) lists librareis." do
      actual = CDNGet::Main.new().run("google")
      ok {actual} =~ /^jquery /
      #ok {actual} =~ /^angularjs /
      ok {actual} =~ /^swfobject /
      ok {actual} =~ /^webfont /
    end

    it "(jsdelivr) lists librareis." do
      actual = CDNGet::Main.new().run("jsdelivr")
      ok {actual} =~ /^jquery /
      ok {actual} =~ /^angularjs /
      ok {actual} =~ /^bootstrap /
    end

    it "(unpkg) lists librareis." do
      exc = assert_raises(CDNGet::CommandError) do
        actual = CDNGet::Main.new().run("unpkg")
      end
      ok {exc.message} == "unpkg: cannot list libraries; please specify pattern such as 'jquery*'."
    end

  end


  describe 'cdnget CDN "jquery*"' do

    it "(cdnjs) lists libraries starting to pattern." do
      actual = CDNGet::Main.new().run("cdnjs", "jquery*")
      ok {actual} =~ /^jquery                #/
      ok {actual} =~ /^jqueryui              #/   # match
      ok {actual} !~ /^require-jquery        #/   # not match
      ok {actual} !~ /^angular/
      ok {actual} !~ /^twitter-bootstrap/
      ok {actual} !~ /^ember\.js/
    end

    it "(google) lists libraries starting to pattern." do
      actual = CDNGet::Main.new().run("google", "jquery*")
      ok {actual} =~ /^jquery                #/
      ok {actual} =~ /^jqueryui              #/   # match
      ok {actual} !~ /^angularjs/
    end

    it "(jsdelivr) lists libraries starting to pattern." do
      actual = CDNGet::Main.new().run("jsdelivr", "jquery*")
      ok {actual} =~ /^jquery                #/
      ok {actual} =~ /^jquery\.ui             #/   # match
      ok {actual} !~ /^angularjs/
      ok {actual} !~ /^bootstrap/
    end

    it "(unpkg) lists libraries starting to pattern." do
      actual = CDNGet::Main.new().run("unpkg", "jquery*")
      ok {actual} =~ /^jquery                #/
      ok {actual} =~ /^jquery-ui             #/   # match
      ok {actual} !~ /^angularjs/
      ok {actual} !~ /^bootstrap/
    end

  end


  describe 'cdnget cdnjs "*jquery"' do

    it "(cdnjs) lists libraries ending to pattern." do
      actual = CDNGet::Main.new().run("cdnjs", "*jquery")
      ok {actual} =~ /^jquery                #/
      ok {actual} !~ /^jqueryui              #/   # not match
      ok {actual} =~ /^require-jquery        #/   # match
      ok {actual} !~ /^angular/
      ok {actual} !~ /^twitter-bootstrap/
      ok {actual} !~ /^ember\.js/
    end

    it "(google) lists libraries ending to pattern." do
      actual = CDNGet::Main.new().run("google", "*jquery")
      ok {actual} =~ /^jquery                #/
      ok {actual} !~ /^jqueryui              #/   # not match
      ok {actual} !~ /^angularjs/
    end

    it "(jsdelivr) lists libraries ending to pattern." do
      actual = CDNGet::Main.new().run("jsdelivr", "*jquery")
      ok {actual} =~ /^jquery                #/
      ok {actual} !~ /^jquery\.ui             #/   # not match
      ok {actual} !~ /^angularjs/
      ok {actual} !~ /^bootstrap/
    end

    it "(unpkg) lists libraries ending to pattern." do
      actual = CDNGet::Main.new().run("unpkg", "*jquery")
      ok {actual} =~ /^jquery                #/
      ok {actual} !~ /^jquery-ui             #/   # not match
      ok {actual} !~ /^angularjs/
      ok {actual} !~ /^bootstrap/
    end

  end


  describe 'cdnget cdnjs "*jquery*"' do

    it "(cdnjs) lists libraries including pattern." do
      actual = CDNGet::Main.new().run("cdnjs", "*jquery*")
      ok {actual} =~ /^jquery                #/
      ok {actual} =~ /^jqueryui              #/   # match
      ok {actual} =~ /^require-jquery        #/   # match
      ok {actual} !~ /^angular/
      ok {actual} !~ /^twitter-bootstrap/
      ok {actual} !~ /^ember\.js/
    end

    it "(google) lists libraries including pattern." do
      actual = CDNGet::Main.new().run("google", "*o*")
      ok {actual} !~ /^jquery /
      ok {actual} !~ /^angularjs /
      ok {actual} =~ /^mootools /
      ok {actual} =~ /^swfobject /
    end

    it "(jsdelivr) lists libraries including pattern." do
      actual = CDNGet::Main.new().run("jsdelivr", "*jquery*")
      ok {actual} =~ /^jquery /
      ok {actual} =~ /^jasmine\.jquery /
      ok {actual} =~ /^jquery\.zoom /
      ok {actual} !~ /^angularjs/
      ok {actual} !~ /^bootstrap/
    end

    it "(unpkg) lists libraries including pattern." do
      actual = CDNGet::Main.new().run("unpkg", "*jquery*")
      ok {actual} =~ /^jquery /
      ok {actual} =~ /^jquery-csv /
      ok {actual} =~ /^jquery\.terminal /
      ok {actual} =~ /^nd-jquery /
      ok {actual} !~ /^angularjs/
      ok {actual} !~ /^bootstrap/
    end

  end


  describe "cdnget CDN jquery" do

    it "(cdnjs) lists versions of library." do
      actual = CDNGet::Main.new().run("cdnjs", "jquery")
      text1 = <<END
name:  jquery
desc:  JavaScript library for DOM operations
tags:  jquery, library, ajax, framework, toolkit, popular
versions:
END
      ok {actual}.start_with?(text1)
      text2 = <<END
  - 1.3.2
  - 1.3.1
  - 1.3.0
  - 1.2.6
  - 1.2.3
END
      ok {actual}.end_with?(text2)
      ok {actual} =~ /^  - 2\.2\.0$/
      ok {actual} =~ /^  - 1\.12\.0$/
    end

    it "(google) lists versions of library." do
      actual = CDNGet::Main.new().run("google", "jquery")
      text1 = <<END
name:  jquery
site:  http://jquery.com/
versions:
END
      ok {actual}.start_with?(text1)
      text2 = <<END
  - 1.3.2
  - 1.3.1
  - 1.3.0
  - 1.2.6
  - 1.2.3
END
      ok {actual}.end_with?(text2)
      ok {actual} =~ /^  - 2\.2\.0$/
      ok {actual} =~ /^  - 1\.12\.0$/
    end

    it "(jsdelivr) lists versions of library." do
      actual = CDNGet::Main.new().run("jsdelivr", "jquery")
      text1 = <<END
name:  jquery
desc:  jQuery is a fast and concise JavaScript Library that simplifies HTML document traversing, event handling, animating, and Ajax interactions for rapid web development. jQuery is designed to change the way that you write JavaScript.
site:  http://jquery.com/
versions:
END
      ok {actual}.start_with?(text1)
      text2 = <<END
  - 1.7.2
  - 1.7.1
  - 1.7
  - 1.5.1
  - 1.4.4
END
      ok {actual}.end_with?(text2)
      ok {actual} =~ /^  - 2\.2\.0$/
      ok {actual} =~ /^  - 1\.12\.0$/
    end

    it "(unpkg) lists versions of library." do
      actual = CDNGet::Main.new().run("unpkg", "jquery")
      text1 = <<END
name:  jquery
desc:  JavaScript library for DOM operations
site:  https://jquery.com
versions:
END
      ok {actual}.start_with?(text1)
      text2 = <<END
  - 1.7.3
  - 1.7.2
  - 1.6.3
  - 1.6.2
  - 1.5.1
END
      ok {actual}.end_with?(text2)
      ok {actual} =~ /^  - 2\.2\.0$/
      ok {actual} =~ /^  - 1\.12\.0$/
    end

    it "(cdnjs) raises error when library name is wrong." do
      pr = proc { CDNGet::Main.new().run("cdnjs", "jquery-ui") }
      ok {pr}.raise?(CDNGet::CommandError, "jquery-ui: Library not found.")
      #
      pr = proc { CDNGet::Main.new().run("cdnjs", "emberjs", "2.2.1") }
      ok {pr}.raise?(CDNGet::CommandError, "emberjs: Library not found (maybe 'ember.js'?).")
    end

    it "(google) raises error when library name is wrong." do
      pr = proc { CDNGet::Main.new().run("google", "jquery-ui") }
      ok {pr}.raise?(CDNGet::CommandError, "jquery-ui: Library not found.")
    end

    it "(jsdelivr) raises error when library name is wrong." do
      pr = proc { CDNGet::Main.new().run("google", "jquery-ui") }
      ok {pr}.raise?(CDNGet::CommandError, "jquery-ui: Library not found.")
    end

    it "(unpkg) raises error when library name is wrong." do
      pr = proc { CDNGet::Main.new().run("unpkg", "jquery-foobar") }
      ok {pr}.raise?(CDNGet::CommandError, "jquery-foobar: Library not found.")
    end

  end


  describe "cdnget cdnjs jquery 2.2.0" do

    it "(cdnjs) lists files." do
      expected = <<END
name:     jquery
version:  2.2.0
desc:     JavaScript library for DOM operations
tags:     jquery, library, ajax, framework, toolkit, popular
urls:
  - https://cdnjs.cloudflare.com/ajax/libs/jquery/2.2.0/jquery.js
  - https://cdnjs.cloudflare.com/ajax/libs/jquery/2.2.0/jquery.min.js
  - https://cdnjs.cloudflare.com/ajax/libs/jquery/2.2.0/jquery.min.map
END
      actual = CDNGet::Main.new().run("cdnjs", "jquery", "2.2.0")
      ok {actual} == expected
    end

    it "(google) lists files." do
      expected = <<END
name:     jquery
version:  2.2.0
site:     http://jquery.com/
urls:
  - https://ajax.googleapis.com/ajax/libs/jquery/2.2.0/jquery.min.js
END
      actual = CDNGet::Main.new().run("google", "jquery", "2.2.0")
      ok {actual} == expected
    end

    it "(jsdelivr) lists files." do
      expected = <<END
name:     jquery
version:  2.2.0
urls:
  - https://cdn.jsdelivr.net/jquery/2.2.0/jquery.js
  - https://cdn.jsdelivr.net/jquery/2.2.0/jquery.min.js
  - https://cdn.jsdelivr.net/jquery/2.2.0/jquery.min.map
END
      actual = CDNGet::Main.new().run("jsdelivr", "jquery", "2.2.0")
      ok {actual} == expected
    end

    it "(unpkg) lists files." do
      expected = <<END
name:     jquery
version:  3.6.0
urls:
  - https://unpkg.com/jquery@3.6.0/src/
  - https://unpkg.com/jquery@3.6.0/dist/
  - https://unpkg.com/jquery@3.6.0/external/
  - https://unpkg.com/jquery@3.6.0/bower.json
  - https://unpkg.com/jquery@3.6.0/package.json
  - https://unpkg.com/jquery@3.6.0/README.md
  - https://unpkg.com/jquery@3.6.0/AUTHORS.txt
  - https://unpkg.com/jquery@3.6.0/LICENSE.txt
END
      actual = CDNGet::Main.new().run("unpkg", "jquery", "3.6.0")
      ok {actual} == expected
    end

    it "(cdnjs) lists files containing subdirectory." do
      expected = <<END
name:     jquery-jcrop
version:  0.9.12
desc:     Jcrop is the quick and easy way to add image cropping functionality to your web application.
tags:     jquery, crop
urls:
  - https://cdnjs.cloudflare.com/ajax/libs/jquery-jcrop/0.9.12/css/Jcrop.gif
  - https://cdnjs.cloudflare.com/ajax/libs/jquery-jcrop/0.9.12/css/jquery.Jcrop.css
  - https://cdnjs.cloudflare.com/ajax/libs/jquery-jcrop/0.9.12/css/jquery.Jcrop.min.css
  - https://cdnjs.cloudflare.com/ajax/libs/jquery-jcrop/0.9.12/js/jquery.Jcrop.js
  - https://cdnjs.cloudflare.com/ajax/libs/jquery-jcrop/0.9.12/js/jquery.Jcrop.min.js
  - https://cdnjs.cloudflare.com/ajax/libs/jquery-jcrop/0.9.12/js/jquery.color.js
  - https://cdnjs.cloudflare.com/ajax/libs/jquery-jcrop/0.9.12/js/jquery.color.min.js
  - https://cdnjs.cloudflare.com/ajax/libs/jquery-jcrop/0.9.12/js/jquery.min.js
END
      actual = CDNGet::Main.new().run("cdnjs", "jquery-jcrop", "0.9.12")
      ok {actual} == expected
    end

    it "(google) lists files containing subdirectory." do
      skip("no libraries containing subdirectory")
    end

    it "(cdnjs) raises error when library name is wrong." do
      pr = proc { CDNGet::Main.new().run("cdnjs", "jquery-ui", "1.9.2") }
      ok {pr}.raise?(CDNGet::CommandError, "jquery-ui: Library not found.")
      #
      pr = proc { CDNGet::Main.new().run("cdnjs", "emberjs", "2.2.1") }
      ok {pr}.raise?(CDNGet::CommandError, "emberjs: Library not found (maybe 'ember.js'?).")
    end

    it "(google) raises error when library name is wrong." do
      pr = proc { CDNGet::Main.new().run("google", "jquery-ui", "1.9.2") }
      ok {pr}.raise?(CDNGet::CommandError, "jquery-ui: Library not found.")
    end

    it "(jsdelivr) raises error when library name is wrong." do
      pr = proc { CDNGet::Main.new().run("jsdelivr", "jquery-ui", "1.9.2") }
      ok {pr}.raise?(CDNGet::CommandError, "jquery-ui: Library not found.")
    end

    it "(unpkg) raises error when library name is wrong." do
      pr = proc { CDNGet::Main.new().run("unpkg", "jquery-foobar", "1.9.2") }
      ok {pr}.raise?(CDNGet::CommandError, "jquery-foobar: Library not found.")
    end

  end


  describe "cdnget CDN jquery 2.2.0 dir" do

    def _do_download_test1(cdn_code, library="jquery", version="2.2.0")
      @tmpdir = tmpdir = "tmpdir1"
      Dir.mkdir(tmpdir)
      sout, serr = capture_io() do
        actual = CDNGet::Main.new().run(cdn_code, library, version, tmpdir)
      end
      yield tmpdir, sout, serr
    ensure
      FileUtils.rm_r(tmpdir) if File.directory?(tmpdir)
    end

    def _do_download_test2(cdn_code, library="jquery-jcrop", version="0.9.12")
      @tmpdir = tmpdir = "tmpdir1"
      Dir.mkdir(tmpdir)
      sout, serr = capture_io() do
        actual = CDNGet::Main.new().run(cdn_code, library, version, tmpdir)
      end
      yield tmpdir, sout, serr
    ensure
      FileUtils.rm_r(tmpdir) if File.directory?(tmpdir)
    end

    def _do_download_test3(cdn_code, libname, version, expected)
      @tmpdir = tmpdir = "tmpdir1"
      Dir.mkdir(tmpdir)
      path = "#{tmpdir}/#{libname}/#{version}"
      # 1st
      sout, serr = capture_io() do
        actual = CDNGet::Main.new().run(cdn_code, libname, version, tmpdir)
      end
      ok {serr} == ""
      ok {sout} == expected
      # 2nd
      sout, serr = capture_io() do
        actual = CDNGet::Main.new().run(cdn_code, libname, version, tmpdir)
      end
      ok {serr} == ""
      ok {sout} == expected.gsub(/(\(Created\))?\n/) {
        if $1
          "(Already exists)\n"
        else
          " (Unchanged)\n"
        end
      }
    ensure
      FileUtils.rm_r(tmpdir)
    end

    it "(cdnjs) downloads files into dir." do
      _do_download_test1("cdnjs", "jquery", "2.2.0") do |tmpdir, sout, serr|
        ok {"#{tmpdir}/jquery/2.2.0/jquery.js"     }.file_exist?
        ok {"#{tmpdir}/jquery/2.2.0/jquery.min.js" }.file_exist?
        ok {"#{tmpdir}/jquery/2.2.0/jquery.min.map"}.file_exist?
        ok {sout} == <<END
#{tmpdir}/jquery/2.2.0/jquery.js ... Done (258,388 byte)
#{tmpdir}/jquery/2.2.0/jquery.min.js ... Done (85,589 byte)
#{tmpdir}/jquery/2.2.0/jquery.min.map ... Done (129,544 byte)
END
      end
    end

    it "(google) downloads files into dir." do
      _do_download_test1("google", "jquery", "2.2.0") do |tmpdir, sout, serr|
        ok {"#{tmpdir}/jquery/2.2.0/jquery.min.js" }.file_exist?
        ok {sout} == <<END
#{tmpdir}/jquery/2.2.0/jquery.min.js ... Done (85,589 byte)
END
      end
    end

    it "(jsdelivr) downloads files into dir." do
      _do_download_test1("jsdelivr", "jquery", "2.2.0") do |tmpdir, sout, serr|
        ok {"#{tmpdir}/jquery/2.2.0/jquery.js"}.file_exist?
        ok {"#{tmpdir}/jquery/2.2.0/jquery.min.js"}.file_exist?
        ok {"#{tmpdir}/jquery/2.2.0/jquery.min.map"}.file_exist?
        ok {sout} == <<END
#{tmpdir}/jquery/2.2.0/jquery.js ... Done (258,388 byte)
#{tmpdir}/jquery/2.2.0/jquery.min.js ... Done (85,589 byte)
#{tmpdir}/jquery/2.2.0/jquery.min.map ... Done (129,544 byte)
END
      end
    end

    it "(unpkg) downloads files into dir." do
      _do_download_test1("unpkg") do |tmpdir, sout, serr|
        ok {"#{tmpdir}/jquery@2.2.0/README.md"     }.file_exist?
        ok {"#{tmpdir}/jquery@2.2.0/package.json"  }.file_exist?
        ok {"#{tmpdir}/jquery@2.2.0/src"           }.dir_exist?
        ok {"#{tmpdir}/jquery@2.2.0/dist"          }.dir_exist?
        ok {sout} == <<END
#{tmpdir}/jquery@2.2.0/package.json ... Done (1,880 byte)
#{tmpdir}/jquery@2.2.0/README.md ... Done (172 byte)
#{tmpdir}/jquery@2.2.0/AUTHORS.txt ... Done (10,258 byte)
#{tmpdir}/jquery@2.2.0/LICENSE.txt ... Done (1,606 byte)
#{tmpdir}/jquery@2.2.0/bower.json ... Done (190 byte)
#{tmpdir}/jquery@2.2.0/dist/ ... Done (Created)
#{tmpdir}/jquery@2.2.0/src/ ... Done (Created)
END
      end
    end

    it "(cdnjs) downloads files (containing subdir) into dir." do
      _do_download_test2("cdnjs", "jquery-jcrop", "0.9.12") do |tmpdir, sout, serr|
        ok {"#{tmpdir}/jquery-jcrop/0.9.12/css/Jcrop.gif"             }.file_exist?
        ok {"#{tmpdir}/jquery-jcrop/0.9.12/css/jquery.Jcrop.css"      }.file_exist?
        ok {"#{tmpdir}/jquery-jcrop/0.9.12/css/jquery.Jcrop.min.css"  }.file_exist?
        ok {"#{tmpdir}/jquery-jcrop/0.9.12/js/jquery.Jcrop.js"        }.file_exist?
        ok {"#{tmpdir}/jquery-jcrop/0.9.12/js/jquery.Jcrop.min.js"    }.file_exist?
        ok {"#{tmpdir}/jquery-jcrop/0.9.12/js/jquery.color.js"        }.file_exist?
        ok {"#{tmpdir}/jquery-jcrop/0.9.12/js/jquery.color.min.js"    }.file_exist?
        ok {"#{tmpdir}/jquery-jcrop/0.9.12/js/jquery.min.js"          }.file_exist?
        ok {sout} == <<END
#{tmpdir}/jquery-jcrop/0.9.12/css/Jcrop.gif ... Done (329 byte)
#{tmpdir}/jquery-jcrop/0.9.12/css/jquery.Jcrop.css ... Done (3,280 byte)
#{tmpdir}/jquery-jcrop/0.9.12/css/jquery.Jcrop.min.css ... Done (2,102 byte)
#{tmpdir}/jquery-jcrop/0.9.12/js/jquery.Jcrop.js ... Done (42,434 byte)
#{tmpdir}/jquery-jcrop/0.9.12/js/jquery.Jcrop.min.js ... Done (15,892 byte)
#{tmpdir}/jquery-jcrop/0.9.12/js/jquery.color.js ... Done (16,142 byte)
#{tmpdir}/jquery-jcrop/0.9.12/js/jquery.color.min.js ... Done (6,845 byte)
#{tmpdir}/jquery-jcrop/0.9.12/js/jquery.min.js ... Done (93,068 byte)
END
      end
    end

    it "(google) downloads files (containing subdir) into dir." do
      skip("no libraries containing subdirectory")
    end

    it "(jsdelivr) downloads files (containing subdir) into dir." do
      _do_download_test2("jsdelivr", "jquery.lightslider", "1.1.1") do |tmpdir, sout, serr|
        ok {"#{tmpdir}/jquery.lightslider/1.1.1/css/jquery.lightslider.min.css"}.file_exist?
        ok {"#{tmpdir}/jquery.lightslider/1.1.1/img/controls.png"}.file_exist?
        ok {"#{tmpdir}/jquery.lightslider/1.1.1/js/jquery.lightslider.min.js"}.file_exist?
        ok {sout} == <<END
#{tmpdir}/jquery.lightslider/1.1.1/css/jquery.lightslider.min.css ... Done (5,060 byte)
#{tmpdir}/jquery.lightslider/1.1.1/img/controls.png ... Done (2,195 byte)
#{tmpdir}/jquery.lightslider/1.1.1/js/jquery.lightslider.min.js ... Done (10,359 byte)
END
      end
    end

    it "(unpkg) downloads files (containing subdir) into dir." do
      _do_download_test2("unpkg", "react", "17.0.2") do |tmpdir, sout, serr|
        ok {"#{tmpdir}/react@17.0.2/LICENSE"           }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/index.js"          }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/jsx-dev-runtime.js"}.file_exist?
        ok {"#{tmpdir}/react@17.0.2/jsx-runtime.js"    }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/cjs/"              }.dir_exist?
        ok {"#{tmpdir}/react@17.0.2/umd/"              }.dir_exist?
        ok {"#{tmpdir}/react@17.0.2/build-info.json"   }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/package.json"      }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/README.md"         }.file_exist?
        expected = <<END
#{tmpdir}/react@17.0.2/LICENSE ... Done (1,086 byte)
#{tmpdir}/react@17.0.2/index.js ... Done (190 byte)
#{tmpdir}/react@17.0.2/jsx-dev-runtime.js ... Done (222 byte)
#{tmpdir}/react@17.0.2/jsx-runtime.js ... Done (214 byte)
#{tmpdir}/react@17.0.2/cjs/ ... Done (Created)
#{tmpdir}/react@17.0.2/umd/ ... Done (Created)
#{tmpdir}/react@17.0.2/build-info.json ... Done (167 byte)
#{tmpdir}/react@17.0.2/package.json ... Done (777 byte)
#{tmpdir}/react@17.0.2/README.md ... Done (737 byte)
END
        ok {sout} == expected
      end
    end

    it "(cdnjs) doesn't override existing files when they are identical to downloaded files." do
      tmpdir = "tmpdir1"
      expected = <<END
#{tmpdir}/jquery-jcrop/2.0.4/css/Jcrop.css ... Done (7,401 byte)
#{tmpdir}/jquery-jcrop/2.0.4/css/Jcrop.gif ... Done (329 byte)
#{tmpdir}/jquery-jcrop/2.0.4/css/Jcrop.min.css ... Done (5,281 byte)
#{tmpdir}/jquery-jcrop/2.0.4/js/Jcrop.js ... Done (75,652 byte)
#{tmpdir}/jquery-jcrop/2.0.4/js/Jcrop.min.js ... Done (38,379 byte)
END
      _do_download_test3("cdnjs", "jquery-jcrop", "2.0.4", expected)
    end

    it "(google) doesn't override existing files when they are identical to downloaded files." do
      tmpdir = "tmpdir1"
      expected = <<END
#{tmpdir}/jquery/3.6.0/jquery.min.js ... Done (89,501 byte)
END
      _do_download_test3("google", "jquery", "3.6.0", expected)
    end

    it "(jsdelivr) doesn't override existing files when they are identical to downloaded files." do
      tmpdir = "tmpdir1"
      expected = <<END
#{tmpdir}/jquery.imagefill/0.1/css/grid.css ... Done (5,436 byte)
#{tmpdir}/jquery.imagefill/0.1/css/main.css ... Done (5,837 byte)
#{tmpdir}/jquery.imagefill/0.1/img/fill-icon.png ... Done (1,530 byte)
#{tmpdir}/jquery.imagefill/0.1/js/jquery-imagefill.js ... Done (2,717 byte)
END
      _do_download_test3("jsdelivr", "jquery.imagefill", "0.1", expected)
    end

    it "(unpkg) doesn't override existing files when they are identical to downloaded files." do
      tmpdir = "tmpdir1"
      expected = <<END
#{tmpdir}/vue@3.2.19/LICENSE ... Done (1,091 byte)
#{tmpdir}/vue@3.2.19/README.md ... Done (4,105 byte)
#{tmpdir}/vue@3.2.19/index.js ... Done (171 byte)
#{tmpdir}/vue@3.2.19/index.mjs ... Done (26 byte)
#{tmpdir}/vue@3.2.19/package.json ... Done (1,654 byte)
#{tmpdir}/vue@3.2.19/ref-macros.d.ts ... Done (2,624 byte)
#{tmpdir}/vue@3.2.19/compiler-sfc/ ... Done (Created)
#{tmpdir}/vue@3.2.19/dist/ ... Done (Created)
#{tmpdir}/vue@3.2.19/server-renderer/ ... Done (Created)
END
      _do_download_test3("unpkg", "vue", "3.2.19", expected)
    end

  end


  describe "cdnget CDN jquery 2.2.0 foo bar" do

    it "results in argument error." do
      args = ["cdnjs", "jquery", "2.2.0", "foo", "bar"]
      pr = proc { CDNGet::Main.new("cdnget").run(*args) }
      ok {pr}.raise?(CDNGet::CommandError, "'bar': Too many arguments.")
    end

  end


end
