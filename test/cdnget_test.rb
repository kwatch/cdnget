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
      ok {actual} =~ /^jquery                # jquery, library, ajax, framework, toolkit, popular$/
      ok {actual} =~ /^angular\.js            # framework, mvc, AngularJS, angular, angular2, angular\.js$/
      ok {actual} =~ /^twitter-bootstrap     # css, less, mobile-first, responsive, front-end, framework, web, twitter, bootstrap$/
      ok {actual} =~ /^ember\.js              # ember, ember.js$/
    end

    it "(google) lists librareis." do
      actual = CDNGet::Main.new().run("google")
      ok {actual} =~ /^jquery /
      ok {actual} =~ /^angularjs /
      ok {actual} =~ /^webfont /
    end

    it "(jsdelivr) lists librareis." do
      actual = CDNGet::Main.new().run("jsdelivr")
      ok {actual} =~ /^jquery /
      ok {actual} =~ /^angularjs /
      ok {actual} =~ /^bootstrap /
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

    it "(google) lists libraries including pattern." do
      actual = CDNGet::Main.new().run("jsdelivr", "*jquery*")
      ok {actual} =~ /^jquery /
      ok {actual} =~ /^jasmine\.jquery /
      ok {actual} =~ /^jquery\.zoom /
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

  end


  describe "cdnget cdnjs jquery 2.2.0" do

    it "(cdnjs) lists files." do
      expected = <<END
name:     jquery
version:  2.2.0
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

    it "(cdnjs) lists files containing subdirectory." do
      expected = <<END
name:     jqueryui
version:  1.9.2
urls:
  - https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.9.2/i18n/jquery-ui-i18n.js
  - https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.9.2/i18n/jquery-ui-i18n.min.js
  - https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.9.2/jquery-ui.min.js
END
      actual = CDNGet::Main.new().run("cdnjs", "jqueryui", "1.9.2")
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

  end


  describe "cdnget CDN jquery 2.2.0 dir" do

    def _do_download_test1(cdn_code)
      tmpdir = "tmpdir1"
      Dir.mkdir(tmpdir)
      begin
        sout, serr = capture_io() do
          actual = CDNGet::Main.new().run("cdnjs", "jquery", "2.2.0", tmpdir)
        end
        ok {"#{tmpdir}/jquery/2.2.0/jquery.js"     }.file_exist?
        ok {"#{tmpdir}/jquery/2.2.0/jquery.min.js" }.file_exist?
        ok {"#{tmpdir}/jquery/2.2.0/jquery.min.map"}.file_exist?
        ok {sout} == <<END
#{tmpdir}/jquery/2.2.0/jquery.js ... Done (258,388 byte)
#{tmpdir}/jquery/2.2.0/jquery.min.js ... Done (85,589 byte)
#{tmpdir}/jquery/2.2.0/jquery.min.map ... Done (129,544 byte)
END
      ensure
        FileUtils.rm_r(tmpdir)
      end
    end

    def _do_download_test2(cdn_code)
      tmpdir = "tmpdir1"
      Dir.mkdir(tmpdir)
      expected = <<END
#{tmpdir}/jqueryui/1.9.2/i18n/jquery-ui-i18n.js ... Done (70,146 byte)
#{tmpdir}/jqueryui/1.9.2/i18n/jquery-ui-i18n.min.js ... Done (54,926 byte)
#{tmpdir}/jqueryui/1.9.2/jquery-ui.min.js ... Done (237,802 byte)
END
      begin
        sout, serr = capture_io() do
          actual = CDNGet::Main.new().run("cdnjs", "jqueryui", "1.9.2", tmpdir)
        end
        ok {"#{tmpdir}/jqueryui/1.9.2/i18n/jquery-ui-i18n.js"    }.file_exist?
        ok {"#{tmpdir}/jqueryui/1.9.2/i18n/jquery-ui-i18n.min.js"}.file_exist?
        ok {"#{tmpdir}/jqueryui/1.9.2/jquery-ui.min.js"          }.file_exist?
        ok {sout} == expected
      ensure
        FileUtils.rm_r(tmpdir)
      end
    end

    def _do_download_test3(cdn_code)
      tmpdir = "tmpdir1"
      Dir.mkdir(tmpdir)
      expected = <<END
#{tmpdir}/jqueryui/1.9.2/i18n/jquery-ui-i18n.js ... Done (70,146 byte)
#{tmpdir}/jqueryui/1.9.2/i18n/jquery-ui-i18n.min.js ... Done (54,926 byte)
#{tmpdir}/jqueryui/1.9.2/jquery-ui.min.js ... Done (237,802 byte)
END
      begin
        path = "#{tmpdir}/jqueryui/1.9.2"
        # 1st
        sout, serr = capture_io() do
          actual = CDNGet::Main.new().run("cdnjs", "jqueryui", "1.9.2", tmpdir)
        end
        ok {serr} == ""
        ok {sout} == expected
        # 2nd
        sout, serr = capture_io() do
          actual = CDNGet::Main.new().run("cdnjs", "jqueryui", "1.9.2", tmpdir)
        end
        ok {serr} == ""
        ok {sout} == expected.gsub(/\n/, " (Unchanged)\n")
      ensure
        FileUtils.rm_r(tmpdir)
      end
    end


    it "(cdnjs) downloads files into dir." do
      _do_download_test1("cdnjs")
    end

    it "(google) downloads files into dir." do
      _do_download_test1("google")
    end

    it "(jsdelivr) downloads files into dir." do
      _do_download_test1("jsdelivr")
    end

    it "(cdnjs) downloads files (containing subdir) into dir." do
      _do_download_test2("cdnjs")
    end

    it "(google) downloads files (containing subdir) into dir." do
      skip("no libraries containing subdirectory")
    end

    it "(jsdelivr) downloads files (containing subdir) into dir." do
      _do_download_test2("jsdelivr")
    end

    it "(cdnjs) doesn't override existing files when they are identical to downloaded files." do
      _do_download_test3("cdnjs")
    end

    it "(google) doesn't override existing files when they are identical to downloaded files." do
      _do_download_test3("google")
    end

    it "(jsdelivr) doesn't override existing files when they are identical to downloaded files." do
      _do_download_test3("jsdelivr")
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
