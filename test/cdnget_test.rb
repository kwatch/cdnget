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
      exc = assert_raises(CDNGet::CommandError) do
        actual = CDNGet::Main.new().run("jsdelivr")
      end
      ok {exc.message} == "jsdelivr: cannot list libraries; please specify pattern such as 'jquery*'."
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
      ok {actual} =~ /^jquery-datepicker     #/   # match
      ok {actual} !~ /^angularjs/
      ok {actual} !~ /^bootstrap/
    end

    it "(unpkg) lists libraries starting to pattern." do
      actual = CDNGet::Main.new().run("unpkg", "jquery*")
      ok {actual} =~ /^jquery                #/
      ok {actual} =~ /^jquery-ui             #/   # match
      ok {actual} !~ /^jquery\.ui /
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
      ok {actual} !~ /^jquery-datepicker /        # not match
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
      ok {actual} =~ /^jasmine-jquery /
      ok {actual} =~ /^jquery-form /
      ok {actual} !~ /^angularjs/
      ok {actual} !~ /^react/
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
desc:  JavaScript library for DOM operations
tags:  jquery, javascript, browser, library
site:  https://jquery.com
license: MIT
versions:
END
      ok {actual}.start_with?(text1)
      text2 = <<END
  - 1.8.2
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

    it "(unpkg) lists versions of library." do
      actual = CDNGet::Main.new().run("unpkg", "jquery")
      text1 = <<END
name:  jquery
desc:  JavaScript library for DOM operations
tags:  jquery, javascript, browser, library
site:  https://jquery.com
license: MIT
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
      pr = proc { CDNGet::Main.new().run("jsdelivr", "jquery-foobar") }
      ok {pr}.raise?(CDNGet::CommandError, "jquery-foobar: Library not found.")
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
desc:     JavaScript library for DOM operations
tags:     jquery, javascript, browser, library
site:     https://jquery.com
default:  /dist/jquery.min.js
license:  MIT
urls:
  - https://cdn.jsdelivr.net/npm/jquery@2.2.0/AUTHORS.txt
  - https://cdn.jsdelivr.net/npm/jquery@2.2.0/bower.json
  - https://cdn.jsdelivr.net/npm/jquery@2.2.0/dist/jquery.js
  - https://cdn.jsdelivr.net/npm/jquery@2.2.0/dist/jquery.min.js
  - https://cdn.jsdelivr.net/npm/jquery@2.2.0/dist/jquery.min.map
  - https://cdn.jsdelivr.net/npm/jquery@2.2.0/LICENSE.txt
END
      actual = CDNGet::Main.new().run("jsdelivr", "jquery", "2.2.0")
      ok {actual}.start_with?(expected)
    end

    it "(unpkg) lists files." do
      expected = <<END
name:     jquery
version:  3.6.0
desc:     JavaScript library for DOM operations
tags:     jquery, javascript, browser, library
site:     https://jquery.com
default:  /dist/jquery.min.js
license:  MIT
urls:
  - https://unpkg.com/jquery@3.6.0/AUTHORS.txt
  - https://unpkg.com/jquery@3.6.0/bower.json
  - https://unpkg.com/jquery@3.6.0/dist/jquery.js
  - https://unpkg.com/jquery@3.6.0/dist/jquery.min.js
  - https://unpkg.com/jquery@3.6.0/dist/jquery.min.map
  - https://unpkg.com/jquery@3.6.0/dist/jquery.slim.js
  - https://unpkg.com/jquery@3.6.0/dist/jquery.slim.min.js
  - https://unpkg.com/jquery@3.6.0/dist/jquery.slim.min.map
  - https://unpkg.com/jquery@3.6.0/external/sizzle/dist/sizzle.js
  - https://unpkg.com/jquery@3.6.0/external/sizzle/dist/sizzle.min.js
  - https://unpkg.com/jquery@3.6.0/external/sizzle/dist/sizzle.min.map
  - https://unpkg.com/jquery@3.6.0/external/sizzle/LICENSE.txt
  - https://unpkg.com/jquery@3.6.0/LICENSE.txt
  - https://unpkg.com/jquery@3.6.0/package.json
  - https://unpkg.com/jquery@3.6.0/README.md
  - https://unpkg.com/jquery@3.6.0/src/ajax.js
  - https://unpkg.com/jquery@3.6.0/src/ajax/jsonp.js
  - https://unpkg.com/jquery@3.6.0/src/ajax/load.js
  - https://unpkg.com/jquery@3.6.0/src/ajax/script.js
  - https://unpkg.com/jquery@3.6.0/src/ajax/var/location.js
  - https://unpkg.com/jquery@3.6.0/src/ajax/var/nonce.js
  - https://unpkg.com/jquery@3.6.0/src/ajax/var/rquery.js
  - https://unpkg.com/jquery@3.6.0/src/ajax/xhr.js
  - https://unpkg.com/jquery@3.6.0/src/attributes.js
  - https://unpkg.com/jquery@3.6.0/src/attributes/attr.js
  - https://unpkg.com/jquery@3.6.0/src/attributes/classes.js
  - https://unpkg.com/jquery@3.6.0/src/attributes/prop.js
  - https://unpkg.com/jquery@3.6.0/src/attributes/support.js
  - https://unpkg.com/jquery@3.6.0/src/attributes/val.js
  - https://unpkg.com/jquery@3.6.0/src/callbacks.js
  - https://unpkg.com/jquery@3.6.0/src/core.js
  - https://unpkg.com/jquery@3.6.0/src/core/access.js
  - https://unpkg.com/jquery@3.6.0/src/core/camelCase.js
  - https://unpkg.com/jquery@3.6.0/src/core/DOMEval.js
  - https://unpkg.com/jquery@3.6.0/src/core/init.js
  - https://unpkg.com/jquery@3.6.0/src/core/isAttached.js
  - https://unpkg.com/jquery@3.6.0/src/core/nodeName.js
  - https://unpkg.com/jquery@3.6.0/src/core/parseHTML.js
  - https://unpkg.com/jquery@3.6.0/src/core/parseXML.js
  - https://unpkg.com/jquery@3.6.0/src/core/ready.js
  - https://unpkg.com/jquery@3.6.0/src/core/ready-no-deferred.js
  - https://unpkg.com/jquery@3.6.0/src/core/readyException.js
  - https://unpkg.com/jquery@3.6.0/src/core/stripAndCollapse.js
  - https://unpkg.com/jquery@3.6.0/src/core/support.js
  - https://unpkg.com/jquery@3.6.0/src/core/toType.js
  - https://unpkg.com/jquery@3.6.0/src/core/var/rsingleTag.js
  - https://unpkg.com/jquery@3.6.0/src/css.js
  - https://unpkg.com/jquery@3.6.0/src/css/addGetHookIf.js
  - https://unpkg.com/jquery@3.6.0/src/css/adjustCSS.js
  - https://unpkg.com/jquery@3.6.0/src/css/curCSS.js
  - https://unpkg.com/jquery@3.6.0/src/css/finalPropName.js
  - https://unpkg.com/jquery@3.6.0/src/css/hiddenVisibleSelectors.js
  - https://unpkg.com/jquery@3.6.0/src/css/showHide.js
  - https://unpkg.com/jquery@3.6.0/src/css/support.js
  - https://unpkg.com/jquery@3.6.0/src/css/var/cssExpand.js
  - https://unpkg.com/jquery@3.6.0/src/css/var/getStyles.js
  - https://unpkg.com/jquery@3.6.0/src/css/var/isHiddenWithinTree.js
  - https://unpkg.com/jquery@3.6.0/src/css/var/rboxStyle.js
  - https://unpkg.com/jquery@3.6.0/src/css/var/rnumnonpx.js
  - https://unpkg.com/jquery@3.6.0/src/css/var/swap.js
  - https://unpkg.com/jquery@3.6.0/src/data.js
  - https://unpkg.com/jquery@3.6.0/src/data/Data.js
  - https://unpkg.com/jquery@3.6.0/src/data/var/acceptData.js
  - https://unpkg.com/jquery@3.6.0/src/data/var/dataPriv.js
  - https://unpkg.com/jquery@3.6.0/src/data/var/dataUser.js
  - https://unpkg.com/jquery@3.6.0/src/deferred.js
  - https://unpkg.com/jquery@3.6.0/src/deferred/exceptionHook.js
  - https://unpkg.com/jquery@3.6.0/src/deprecated.js
  - https://unpkg.com/jquery@3.6.0/src/deprecated/ajax-event-alias.js
  - https://unpkg.com/jquery@3.6.0/src/deprecated/event.js
  - https://unpkg.com/jquery@3.6.0/src/dimensions.js
  - https://unpkg.com/jquery@3.6.0/src/effects.js
  - https://unpkg.com/jquery@3.6.0/src/effects/animatedSelector.js
  - https://unpkg.com/jquery@3.6.0/src/effects/Tween.js
  - https://unpkg.com/jquery@3.6.0/src/event.js
  - https://unpkg.com/jquery@3.6.0/src/event/focusin.js
  - https://unpkg.com/jquery@3.6.0/src/event/support.js
  - https://unpkg.com/jquery@3.6.0/src/event/trigger.js
  - https://unpkg.com/jquery@3.6.0/src/exports/amd.js
  - https://unpkg.com/jquery@3.6.0/src/exports/global.js
  - https://unpkg.com/jquery@3.6.0/src/jquery.js
  - https://unpkg.com/jquery@3.6.0/src/manipulation.js
  - https://unpkg.com/jquery@3.6.0/src/manipulation/_evalUrl.js
  - https://unpkg.com/jquery@3.6.0/src/manipulation/buildFragment.js
  - https://unpkg.com/jquery@3.6.0/src/manipulation/getAll.js
  - https://unpkg.com/jquery@3.6.0/src/manipulation/setGlobalEval.js
  - https://unpkg.com/jquery@3.6.0/src/manipulation/support.js
  - https://unpkg.com/jquery@3.6.0/src/manipulation/var/rscriptType.js
  - https://unpkg.com/jquery@3.6.0/src/manipulation/var/rtagName.js
  - https://unpkg.com/jquery@3.6.0/src/manipulation/wrapMap.js
  - https://unpkg.com/jquery@3.6.0/src/offset.js
  - https://unpkg.com/jquery@3.6.0/src/queue.js
  - https://unpkg.com/jquery@3.6.0/src/queue/delay.js
  - https://unpkg.com/jquery@3.6.0/src/selector.js
  - https://unpkg.com/jquery@3.6.0/src/selector-native.js
  - https://unpkg.com/jquery@3.6.0/src/selector-sizzle.js
  - https://unpkg.com/jquery@3.6.0/src/serialize.js
  - https://unpkg.com/jquery@3.6.0/src/traversing.js
  - https://unpkg.com/jquery@3.6.0/src/traversing/findFilter.js
  - https://unpkg.com/jquery@3.6.0/src/traversing/var/dir.js
  - https://unpkg.com/jquery@3.6.0/src/traversing/var/rneedsContext.js
  - https://unpkg.com/jquery@3.6.0/src/traversing/var/siblings.js
  - https://unpkg.com/jquery@3.6.0/src/var/arr.js
  - https://unpkg.com/jquery@3.6.0/src/var/class2type.js
  - https://unpkg.com/jquery@3.6.0/src/var/document.js
  - https://unpkg.com/jquery@3.6.0/src/var/documentElement.js
  - https://unpkg.com/jquery@3.6.0/src/var/flat.js
  - https://unpkg.com/jquery@3.6.0/src/var/fnToString.js
  - https://unpkg.com/jquery@3.6.0/src/var/getProto.js
  - https://unpkg.com/jquery@3.6.0/src/var/hasOwn.js
  - https://unpkg.com/jquery@3.6.0/src/var/indexOf.js
  - https://unpkg.com/jquery@3.6.0/src/var/isFunction.js
  - https://unpkg.com/jquery@3.6.0/src/var/isWindow.js
  - https://unpkg.com/jquery@3.6.0/src/var/ObjectFunctionString.js
  - https://unpkg.com/jquery@3.6.0/src/var/pnum.js
  - https://unpkg.com/jquery@3.6.0/src/var/push.js
  - https://unpkg.com/jquery@3.6.0/src/var/rcheckableType.js
  - https://unpkg.com/jquery@3.6.0/src/var/rcssNum.js
  - https://unpkg.com/jquery@3.6.0/src/var/rnothtmlwhite.js
  - https://unpkg.com/jquery@3.6.0/src/var/slice.js
  - https://unpkg.com/jquery@3.6.0/src/var/support.js
  - https://unpkg.com/jquery@3.6.0/src/var/toString.js
  - https://unpkg.com/jquery@3.6.0/src/wrap.js
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
      ok {pr}.raise?(CDNGet::CommandError, "jquery-ui@1.9.2: Library or version not found.")
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
      _do_download_test1("jsdelivr", "chibijs", "3.0.9") do |tmpdir, sout, serr|
        ok {"#{tmpdir}/chibijs@3.0.9/.jshintrc"        }.file_exist?
        ok {"#{tmpdir}/chibijs@3.0.9/.npmignore"       }.file_exist?
        ok {"#{tmpdir}/chibijs@3.0.9/chibi.js"         }.file_exist?
        ok {"#{tmpdir}/chibijs@3.0.9/chibi-min.js"     }.file_exist?
        ok {"#{tmpdir}/chibijs@3.0.9/gulpfile.js"      }.file_exist?
        ok {"#{tmpdir}/chibijs@3.0.9/package.json"     }.file_exist?
        ok {"#{tmpdir}/chibijs@3.0.9/README.md"        }.file_exist?
        ok {"#{tmpdir}/chibijs@3.0.9/tests/runner.html"}.file_exist?
        ok {sout} == <<END
#{tmpdir}/chibijs@3.0.9/.jshintrc ... Done (5,323 byte)
#{tmpdir}/chibijs@3.0.9/.npmignore ... Done (46 byte)
#{tmpdir}/chibijs@3.0.9/chibi.js ... Done (18,429 byte)
#{tmpdir}/chibijs@3.0.9/chibi-min.js ... Done (7,321 byte)
#{tmpdir}/chibijs@3.0.9/gulpfile.js ... Done (1,395 byte)
#{tmpdir}/chibijs@3.0.9/package.json ... Done (756 byte)
#{tmpdir}/chibijs@3.0.9/README.md ... Done (21,283 byte)
#{tmpdir}/chibijs@3.0.9/tests/runner.html ... Done (14,302 byte)
END
      end
    end

    it "(unpkg) downloads files into dir." do
      _do_download_test1("unpkg", "chibijs", "3.0.9") do |tmpdir, sout, serr|
        ok {"#{tmpdir}/chibijs@3.0.9/.jshintrc"        }.file_exist?
        ok {"#{tmpdir}/chibijs@3.0.9/.npmignore"       }.file_exist?
        ok {"#{tmpdir}/chibijs@3.0.9/chibi.js"         }.file_exist?
        ok {"#{tmpdir}/chibijs@3.0.9/chibi-min.js"     }.file_exist?
        ok {"#{tmpdir}/chibijs@3.0.9/gulpfile.js"      }.file_exist?
        ok {"#{tmpdir}/chibijs@3.0.9/package.json"     }.file_exist?
        ok {"#{tmpdir}/chibijs@3.0.9/README.md"        }.file_exist?
        ok {"#{tmpdir}/chibijs@3.0.9/tests/runner.html"}.file_exist?
        ok {sout} == <<END
#{tmpdir}/chibijs@3.0.9/.jshintrc ... Done (5,323 byte)
#{tmpdir}/chibijs@3.0.9/.npmignore ... Done (46 byte)
#{tmpdir}/chibijs@3.0.9/chibi.js ... Done (18,429 byte)
#{tmpdir}/chibijs@3.0.9/chibi-min.js ... Done (7,321 byte)
#{tmpdir}/chibijs@3.0.9/gulpfile.js ... Done (1,395 byte)
#{tmpdir}/chibijs@3.0.9/package.json ... Done (756 byte)
#{tmpdir}/chibijs@3.0.9/README.md ... Done (21,283 byte)
#{tmpdir}/chibijs@3.0.9/tests/runner.html ... Done (14,302 byte)
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
      _do_download_test2("jsdelivr", "zepto", "1.2.0") do |tmpdir, sout, serr|
        ok {"#{tmpdir}/zepto@1.2.0/dist/zepto.js"    }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/dist/zepto.min.js"}.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/MIT-LICENSE"      }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/package.json"     }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/README.md"        }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/src/ajax.js"      }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/src/assets.js"    }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/src/callbacks.js" }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/src/data.js"      }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/src/deferred.js"  }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/src/detect.js"    }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/src/event.js"     }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/src/form.js"      }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/src/fx.js"        }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/src/fx_methods.js"}.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/src/gesture.js"   }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/src/ie.js"        }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/src/ios3.js"      }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/src/selector.js"  }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/src/stack.js"     }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/src/touch.js"     }.file_exist?
        ok {"#{tmpdir}/zepto@1.2.0/src/zepto.js"     }.file_exist?
        ok {sout} == <<END
#{tmpdir}/zepto@1.2.0/dist/zepto.js ... Done (58,707 byte)
#{tmpdir}/zepto@1.2.0/dist/zepto.min.js ... Done (26,386 byte)
#{tmpdir}/zepto@1.2.0/MIT-LICENSE ... Done (1,081 byte)
#{tmpdir}/zepto@1.2.0/package.json ... Done (435 byte)
#{tmpdir}/zepto@1.2.0/README.md ... Done (6,711 byte)
#{tmpdir}/zepto@1.2.0/src/ajax.js ... Done (13,843 byte)
#{tmpdir}/zepto@1.2.0/src/assets.js ... Done (581 byte)
#{tmpdir}/zepto@1.2.0/src/callbacks.js ... Done (4,208 byte)
#{tmpdir}/zepto@1.2.0/src/data.js ... Done (2,789 byte)
#{tmpdir}/zepto@1.2.0/src/deferred.js ... Done (3,846 byte)
#{tmpdir}/zepto@1.2.0/src/detect.js ... Done (3,754 byte)
#{tmpdir}/zepto@1.2.0/src/event.js ... Done (9,546 byte)
#{tmpdir}/zepto@1.2.0/src/form.js ... Done (1,253 byte)
#{tmpdir}/zepto@1.2.0/src/fx.js ... Done (4,843 byte)
#{tmpdir}/zepto@1.2.0/src/fx_methods.js ... Done (2,102 byte)
#{tmpdir}/zepto@1.2.0/src/gesture.js ... Done (1,138 byte)
#{tmpdir}/zepto@1.2.0/src/ie.js ... Done (530 byte)
#{tmpdir}/zepto@1.2.0/src/ios3.js ... Done (1,140 byte)
#{tmpdir}/zepto@1.2.0/src/selector.js ... Done (3,187 byte)
#{tmpdir}/zepto@1.2.0/src/stack.js ... Done (560 byte)
#{tmpdir}/zepto@1.2.0/src/touch.js ... Done (6,067 byte)
#{tmpdir}/zepto@1.2.0/src/zepto.js ... Done (33,889 byte)
END
      end
    end

    it "(unpkg) downloads files (containing subdir) into dir." do
      _do_download_test2("unpkg", "react", "17.0.2") do |tmpdir, sout, serr|
        ok {"#{tmpdir}/react@17.0.2/build-info.json"            }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/cjs/react.development.js"   }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/cjs/react.production.min.js"}.file_exist?
        ok {"#{tmpdir}/react@17.0.2/cjs/react-jsx-dev-runtime.development.js"   }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/cjs/react-jsx-dev-runtime.production.min.js"}.file_exist?
        ok {"#{tmpdir}/react@17.0.2/cjs/react-jsx-dev-runtime.profiling.min.js" }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/cjs/react-jsx-runtime.development.js"       }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/cjs/react-jsx-runtime.production.min.js"    }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/cjs/react-jsx-runtime.profiling.min.js"     }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/index.js"                   }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/jsx-dev-runtime.js"         }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/jsx-runtime.js"             }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/LICENSE"                    }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/package.json"               }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/README.md"                  }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/umd/react.development.js"   }.file_exist?
        ok {"#{tmpdir}/react@17.0.2/umd/react.production.min.js"}.file_exist?
        ok {"#{tmpdir}/react@17.0.2/umd/react.profiling.min.js" }.file_exist?
        expected = <<END
#{tmpdir}/react@17.0.2/build-info.json ... Done (167 byte)
#{tmpdir}/react@17.0.2/cjs/react.development.js ... Done (72,141 byte)
#{tmpdir}/react@17.0.2/cjs/react.production.min.js ... Done (6,450 byte)
#{tmpdir}/react@17.0.2/cjs/react-jsx-dev-runtime.development.js ... Done (37,753 byte)
#{tmpdir}/react@17.0.2/cjs/react-jsx-dev-runtime.production.min.js ... Done (456 byte)
#{tmpdir}/react@17.0.2/cjs/react-jsx-dev-runtime.profiling.min.js ... Done (455 byte)
#{tmpdir}/react@17.0.2/cjs/react-jsx-runtime.development.js ... Done (38,352 byte)
#{tmpdir}/react@17.0.2/cjs/react-jsx-runtime.production.min.js ... Done (962 byte)
#{tmpdir}/react@17.0.2/cjs/react-jsx-runtime.profiling.min.js ... Done (961 byte)
#{tmpdir}/react@17.0.2/index.js ... Done (190 byte)
#{tmpdir}/react@17.0.2/jsx-dev-runtime.js ... Done (222 byte)
#{tmpdir}/react@17.0.2/jsx-runtime.js ... Done (214 byte)
#{tmpdir}/react@17.0.2/LICENSE ... Done (1,086 byte)
#{tmpdir}/react@17.0.2/package.json ... Done (777 byte)
#{tmpdir}/react@17.0.2/README.md ... Done (737 byte)
#{tmpdir}/react@17.0.2/umd/react.development.js ... Done (105,096 byte)
#{tmpdir}/react@17.0.2/umd/react.production.min.js ... Done (11,440 byte)
#{tmpdir}/react@17.0.2/umd/react.profiling.min.js ... Done (13,668 byte)
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
#{tmpdir}/chibijs@3.0.9/.jshintrc ... Done (5,323 byte)
#{tmpdir}/chibijs@3.0.9/.npmignore ... Done (46 byte)
#{tmpdir}/chibijs@3.0.9/chibi.js ... Done (18,429 byte)
#{tmpdir}/chibijs@3.0.9/chibi-min.js ... Done (7,321 byte)
#{tmpdir}/chibijs@3.0.9/gulpfile.js ... Done (1,395 byte)
#{tmpdir}/chibijs@3.0.9/package.json ... Done (756 byte)
#{tmpdir}/chibijs@3.0.9/README.md ... Done (21,283 byte)
#{tmpdir}/chibijs@3.0.9/tests/runner.html ... Done (14,302 byte)
END
      _do_download_test3("jsdelivr", "chibijs", "3.0.9", expected)
    end

    it "(unpkg) doesn't override existing files when they are identical to downloaded files." do
      tmpdir = "tmpdir1"
      expected = <<END
#{tmpdir}/chibijs@3.0.9/.jshintrc ... Done (5,323 byte)
#{tmpdir}/chibijs@3.0.9/.npmignore ... Done (46 byte)
#{tmpdir}/chibijs@3.0.9/chibi.js ... Done (18,429 byte)
#{tmpdir}/chibijs@3.0.9/chibi-min.js ... Done (7,321 byte)
#{tmpdir}/chibijs@3.0.9/gulpfile.js ... Done (1,395 byte)
#{tmpdir}/chibijs@3.0.9/package.json ... Done (756 byte)
#{tmpdir}/chibijs@3.0.9/README.md ... Done (21,283 byte)
#{tmpdir}/chibijs@3.0.9/tests/runner.html ... Done (14,302 byte)
END
      _do_download_test3("unpkg", "chibijs", "3.0.9", expected)
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
