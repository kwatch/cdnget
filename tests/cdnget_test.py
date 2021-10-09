# -*- coding: utf-8 -*-

import sys, os
import unittest
import shutil

import oktest
from oktest import ok, test, subject, situation, at_end
#from oktest.dummy import dummy_io

import cdnget
from cdnget import S


def _run(argstr, input=None):
    from subprocess import Popen, PIPE
    command = "./bin/cdnget %s" % argstr
    p = Popen(command, shell=True, stdin=PIPE, stdout=PIPE, stderr=PIPE, close_fds=True)
    stdin, stdout, stderr = p.stdin, p.stdout, p.stderr
    try:
        if input:
            stdin.write(input)
        stdin.close()
        sout = stdout.read()
        serr = stderr.read()
        return S(sout), S(serr)
    finally:
        stdout.close()


class Script_TC(unittest.TestCase):


    with subject("common"):

        @test("cdnget")
        def _(self):
            sout, serr = _run("")
            ok (serr) == ""
            ok (sout) == r"""
cdnjs       # https://cdnjs.com/
jsdelivr    # https://www.jsdelivr.com/
unpkg       # https://unpkg.com/
google      # https://developers.google.com/speed/libraries/
"""[1:]

        @test("cdnget -h, --help")
        def _(self):
            expected = r"""
cdnget  -- download files from public CDN (cdnjs/jsdelivr/unpkg/google)

Usage: cdnget [<options>] [<CDN> [<library> [<version> [<directory>]]]]

Options:
    -h, --help        : help
    -v, --version     : version
    -q, --quiet       : minimal output
        --debug       : (debug mode)

Example:
    $ cdnget                                # list public CDN names
    $ cdnget [-q] cdnjs                     # list libraries
    $ cdnget [-q] cdnjs 'jquery*'           # search libraries
    $ cdnget [-q] cdnjs jquery              # list versions
    $ cdnget [-q] cdnjs jquery latest       # show latest version
    $ cdnget [-q] cdnjs jquery 2.2.4        # list files
    $ mkdir -p static/lib                     # create a directory
    $ cdnget [-q] cdnjs jquery 2.2.4 /static/lib  # download files
    static/lib/jquery/2.2.4/jquery.js ... Done (257,551 byte)
    static/lib/jquery/2.2.4/jquery.min.js ... Done (85,578 byte)
    static/lib/jquery/2.2.4/jquery.min.map ... Done (129,572 byte)
    $ ls static/lib/jquery/2.2.4
    jquery.js       jquery.min.js   jquery.min.map

"""[1:]
            #
            sout, serr = _run("-h")
            ok (serr) == ""
            ok (sout) == expected
            #
            sout, serr = _run("--help")
            ok (serr) == ""
            ok (sout) == expected

        @test("cdnget -v, --version")
        def _(self):
            from cdnget import RELEASE
            expected = "%s\n" % RELEASE
            #
            sout, serr = _run("-v")
            ok (serr) == ""
            ok (sout) == expected
            #
            sout, serr = _run("--version")
            ok (serr) == ""
            ok (sout) == expected

        @test("cdnget blablabla")
        def _(self):
            sout, serr = _run("blablabla")
            ok (serr) == "blablabla: no such CDN.\n"
            ok (sout) == ""

        @test("cdnget -xh")
        def _(self):
            sout, serr = _run("-xh")
            ok (serr) == "-x: unknown command option.\n"
            ok (sout) == ""

        @test("cdnget --blabla")
        def _(self):
            sout, serr = _run("--blabla")
            ok (serr) == "--blabla: unknown command option.\n"
            ok (sout) == ""


    with subject("cdnjs"):

        @test("cdnget cdnjs")
        def _(self):
            sout, serr = _run("cdnjs")
            ok (serr) == ""
            for line in sout.splitlines():
                ok (line).matches(r'^\w+([-.]\w+)* *\# .*$')
            expected = "jquery                # JavaScript library for DOM operations"
            ok (sout).contains("\n%s\n" % expected)

        @test("cdnget cdnjs <library>")
        def _(self):
            sout, serr = _run("cdnjs jquery")
            ok (serr) == ""
            expected = r"""
name:     jquery
desc:     JavaScript library for DOM operations
tags:     jquery, library, ajax, framework, toolkit, popular
site:     http://jquery.com/
info:     https://cdnjs.com//libraries/jquery
license:  MIT
versions:
"""[1:]
            ok (sout.startswith(expected)) == True
            expected2 = r"""
  - 1.4.4
  - 1.4.3
  - 1.4.2
  - 1.4.1
  - 1.4.0
  - 1.3.2
  - 1.3.1
  - 1.3.0
  - 1.2.6
  - 1.2.3
"""[1:]
            ok (sout.endswith(expected2)) == True

        @test("cdnget cdnjs <library> <version>")
        def _(self):
            sout, serr = _run("cdnjs jquery 2.2.4")
            ok (serr) == ""
            expected = r"""
name:     jquery
version:  2.2.4
desc:     JavaScript library for DOM operations
tags:     jquery, library, ajax, framework, toolkit, popular
site:     http://jquery.com/
info:     https://cdnjs.com//libraries/jquery/2.2.4
license:  MIT
urls:
  - https://cdnjs.cloudflare.com/ajax/libs/jquery/2.2.4/jquery.js
  - https://cdnjs.cloudflare.com/ajax/libs/jquery/2.2.4/jquery.min.js
  - https://cdnjs.cloudflare.com/ajax/libs/jquery/2.2.4/jquery.min.map
"""[1:]
            ok (sout) == expected

        @test("cdnget cdnjs <library> <version> <directory>")
        def _(self):
            dir = './test.d/lib1'
            at_end(lambda: shutil.rmtree('./test.d'))
            os.makedirs(dir)
            #
            expected = r"""
./test.d/lib1/jquery/2.2.4/jquery.js ... Done (257,551 byte)
./test.d/lib1/jquery/2.2.4/jquery.min.js ... Done (85,578 byte)
./test.d/lib1/jquery/2.2.4/jquery.min.map ... Done (129,572 byte)
"""[1:]
            sout, serr = _run("cdnjs jquery 2.2.4 %s" % dir)
            ok (serr) == ""
            ok (sout) == expected
            #
            ok ("./test.d/lib1/jquery/2.2.4/jquery.js").is_file()
            ok ("./test.d/lib1/jquery/2.2.4/jquery.min.js").is_file()
            ok ("./test.d/lib1/jquery/2.2.4/jquery.min.map").is_file()
            from glob import glob
            ok (sorted(glob("./test.d/lib1/jquery/2.2.4/*"))) == [
              "./test.d/lib1/jquery/2.2.4/jquery.js",
              "./test.d/lib1/jquery/2.2.4/jquery.min.js",
              "./test.d/lib1/jquery/2.2.4/jquery.min.map",
            ]

        @test("cdnget --quiet cdnjs <library> <version> <directory>")
        def _(self):
            dir = './test.d/lib1'
            at_end(lambda: shutil.rmtree('./test.d'))
            os.makedirs(dir)
            for opt in ["-q", "--quiet"]:
                sout, serr = _run(opt + " cdnjs jquery 2.2.4 %s" % dir)
                ok (serr) == ""
                ok (sout) == ""
                ok ("./test.d/lib1/jquery/2.2.4/jquery.js").is_file()
                ok ("./test.d/lib1/jquery/2.2.4/jquery.min.js").is_file()
                ok ("./test.d/lib1/jquery/2.2.4/jquery.min.map").is_file()

        @test("cdnget cdnjs blablabla")
        def _(self):
            sout, serr = _run("cdnjs blablabla")
            ok (serr) == "blablabla: library not found.\n"
            ok (sout) == ""

        @test("cdnget cdnjs jquery 999.999.999")
        def _(self):
            sout, serr = _run("cdnjs jquery 999.999.999")
            ok (serr) == "jquery 999.999.999: version not found.\n"
            ok (sout) == ""


    with subject("jsdelivr"):

        @test("cdnget jsdelivr")
        def _(self):
            sout, serr = _run("jsdelivr")
            ok (sout) == ""
            ok (serr) == "jsdelivr: cannot list libraries; please specify pattern such as 'jquery*'.\n"

        @test("cdnget jsdelivr <library>")
        def _(self):
            sout, serr = _run("jsdelivr jquery")
            ok (serr) == ""
            expected = """
name:     jquery
desc:     JavaScript library for DOM operations
tags:     jquery, javascript, browser, library
site:     https://jquery.com
info:     https://www.jsdelivr.com/package/npm/jquery
license:  MIT
versions:
"""[1:]
            ok (sout.startswith(expected)) == True
            expected2 = """
  - 1.11.1-rc2
  - 1.11.1-rc1
  - 1.11.1-beta1
  - 1.11.0-rc1
  - 1.11.0-beta3
  - 1.11.0
  - 1.9.1
  - 1.8.3
  - 1.8.2
  - 1.7.3
  - 1.7.2
  - 1.6.3
  - 1.6.2
  - 1.5.1
"""
            ok (sout.endswith(expected2)) == True

        @test("cdnget jsdelivr <library> <version>")
        def _(self):
            sout, serr = _run("jsdelivr jquery 2.2.4")
            ok (serr) == ""
            expected = r"""
name:     jquery
version:  2.2.4
desc:     JavaScript library for DOM operations
tags:     jquery, javascript, browser, library
site:     https://jquery.com
info:     https://www.jsdelivr.com/package/npm/jquery?version=2.2.4
npmpkg:   https://registry.npmjs.org/jquery/-/jquery-2.2.4.tgz
default:  /dist/jquery.min.js
license:  MIT
urls:
  - https://cdn.jsdelivr.net/npm/jquery@2.2.4/AUTHORS.txt
  - https://cdn.jsdelivr.net/npm/jquery@2.2.4/bower.json
  - https://cdn.jsdelivr.net/npm/jquery@2.2.4/dist/jquery.js
  - https://cdn.jsdelivr.net/npm/jquery@2.2.4/dist/jquery.min.js
  - https://cdn.jsdelivr.net/npm/jquery@2.2.4/dist/jquery.min.map
  - https://cdn.jsdelivr.net/npm/jquery@2.2.4/external/sizzle/dist/sizzle.js
"""[1:]
            ok (sout.startswith(expected)) == True

        @test("cdnget jsdelivr <library> <version> <directory>")
        def _(self):
            dir = './test.d/lib2'
            at_end(lambda: shutil.rmtree('./test.d'))
            os.makedirs(dir)
            #
            expected = r"""
./test.d/lib2/chibijs@3.0.9/.jshintrc ... Done (5,323 byte)
./test.d/lib2/chibijs@3.0.9/.npmignore ... Done (46 byte)
./test.d/lib2/chibijs@3.0.9/chibi.js ... Done (18,429 byte)
./test.d/lib2/chibijs@3.0.9/chibi-min.js ... Done (7,321 byte)
./test.d/lib2/chibijs@3.0.9/gulpfile.js ... Done (1,395 byte)
./test.d/lib2/chibijs@3.0.9/package.json ... Done (756 byte)
./test.d/lib2/chibijs@3.0.9/README.md ... Done (21,283 byte)
./test.d/lib2/chibijs@3.0.9/tests/runner.html ... Done (14,302 byte)
"""[1:]
            sout, serr = _run("jsdelivr chibijs 3.0.9 %s" % dir)
            ok (serr) == ""
            ok (sout) == expected
            #
            ok ("./test.d/lib2/chibijs@3.0.9/.jshintrc"        ).is_file()
            ok ("./test.d/lib2/chibijs@3.0.9/.npmignore"       ).is_file()
            ok ("./test.d/lib2/chibijs@3.0.9/chibi.js"         ).is_file()
            ok ("./test.d/lib2/chibijs@3.0.9/chibi-min.js"     ).is_file()
            ok ("./test.d/lib2/chibijs@3.0.9/gulpfile.js"      ).is_file()
            ok ("./test.d/lib2/chibijs@3.0.9/package.json"     ).is_file()
            ok ("./test.d/lib2/chibijs@3.0.9/README.md"        ).is_file()
            ok ("./test.d/lib2/chibijs@3.0.9/tests/runner.html").is_file()
            from glob import glob
            ok (sorted(glob("./test.d/lib2/chibijs@3.0.9/*"))) == [
                "./test.d/lib2/chibijs@3.0.9/README.md",
                "./test.d/lib2/chibijs@3.0.9/chibi-min.js",
                "./test.d/lib2/chibijs@3.0.9/chibi.js",
                "./test.d/lib2/chibijs@3.0.9/gulpfile.js",
                "./test.d/lib2/chibijs@3.0.9/package.json",
                "./test.d/lib2/chibijs@3.0.9/tests",
            ]

        @test("cdnget --quiet jsdelivr <library> <version> <directory>")
        def _(self):
            dir = './test.d/lib2'
            at_end(lambda: shutil.rmtree('./test.d'))
            os.makedirs(dir)
            for opt in ["-q", "--quiet"]:
                sout, serr = _run(opt + " jsdelivr chibijs 3.0.9 %s" % dir)
                ok (serr) == ""
                ok (sout) == ""
                ok ("./test.d/lib2/chibijs@3.0.9/chibi.js"    ).is_file()
                ok ("./test.d/lib2/chibijs@3.0.9/chibi-min.js").is_file()
                ok ("./test.d/lib2/chibijs@3.0.9/README.md"   ).is_file()

        @test("cdnget jsdelivr non-exist-package", tag="curr")
        def _(self):
            sout, serr = _run("jsdelivr txamwxzp5")
            ok (serr) == "txamwxzp5: library not found.\n"
            ok (sout) == ""

        @test("cdnget jsdelivr jquery 999.999.999", tag="curr")
        def _(self):
            sout, serr = _run("jsdelivr jquery 999.999.999")
            #ok (serr) == "jquery 999.999.999: version not found.\n"
            ok (serr) == "jquery@999.999.999: library or version not found.\n"
            ok (sout) == ""


    with subject("unpkg"):

        @test("cdnget unpkg")
        def _(self):
            sout, serr = _run("unpkg")
            ok (sout) == ""
            ok (serr) == "unpkg: cannot list libraries; please specify pattern such as 'jquery*'.\n"

        @test("cdnget unpkg <library>")
        def _(self):
            sout, serr = _run("unpkg jquery")
            ok (serr) == ""
            expected = """
name:     jquery
desc:     JavaScript library for DOM operations
tags:     jquery, javascript, browser, library
site:     https://jquery.com
info:     https://unpkg.com/browse/jquery/
license:  MIT
versions:
"""[1:]
            ok (sout.startswith(expected)) == True
            expected2 = """
  - 1.11.1
  - 1.11.1-rc2
  - 1.11.1-rc1
  - 1.11.1-beta1
  - 1.11.0
  - 1.11.0-rc1
  - 1.11.0-beta3
  - 1.9.1
  - 1.8.3
  - 1.8.2
  - 1.7.3
  - 1.7.2
  - 1.6.3
  - 1.6.2
  - 1.5.1
"""
            ok (sout.endswith(expected2)) == True

        @test("cdnget unpkg <library> <version>")
        def _(self):
            sout, serr = _run("unpkg jquery 3.6.0")
            ok (serr) == ""
            expected = r"""
name:     jquery
version:  3.6.0
desc:     JavaScript library for DOM operations
tags:     jquery, javascript, browser, library
site:     https://jquery.com
info:     https://unpkg.com/browse/jquery@3.6.0/
npmpkg:   https://registry.npmjs.org/jquery/-/jquery-3.6.0.tgz
default:  /dist/jquery.min.js
license:  MIT
urls:
  - https://unpkg.com/jquery@3.6.0/AUTHORS.txt
  - https://unpkg.com/jquery@3.6.0/bower.json
  - https://unpkg.com/jquery@3.6.0/dist/jquery.js
  - https://unpkg.com/jquery@3.6.0/dist/jquery.min.js
  - https://unpkg.com/jquery@3.6.0/dist/jquery.min.map
"""[1:]
            ok (sout.startswith(expected)) == True

        @test("cdnget unpkg <library> <version> <directory>")
        def _(self):
            dir = './test.d/lib2'
            at_end(lambda: shutil.rmtree('./test.d'))
            os.makedirs(dir)
            #
            expected = r"""
./test.d/lib2/chibijs@3.0.9/.jshintrc ... Done (5,323 byte)
./test.d/lib2/chibijs@3.0.9/.npmignore ... Done (46 byte)
./test.d/lib2/chibijs@3.0.9/chibi.js ... Done (18,429 byte)
./test.d/lib2/chibijs@3.0.9/chibi-min.js ... Done (7,321 byte)
./test.d/lib2/chibijs@3.0.9/gulpfile.js ... Done (1,395 byte)
./test.d/lib2/chibijs@3.0.9/package.json ... Done (756 byte)
./test.d/lib2/chibijs@3.0.9/README.md ... Done (21,283 byte)
./test.d/lib2/chibijs@3.0.9/tests/runner.html ... Done (14,302 byte)
"""[1:]
            sout, serr = _run("unpkg chibijs 3.0.9 %s" % dir)
            ok (serr) == ""
            ok (sout) == expected
            #
            ok ("./test.d/lib2/chibijs@3.0.9/.jshintrc"        ).is_file()
            ok ("./test.d/lib2/chibijs@3.0.9/.npmignore"       ).is_file()
            ok ("./test.d/lib2/chibijs@3.0.9/chibi.js"         ).is_file()
            ok ("./test.d/lib2/chibijs@3.0.9/chibi-min.js"     ).is_file()
            ok ("./test.d/lib2/chibijs@3.0.9/gulpfile.js"      ).is_file()
            ok ("./test.d/lib2/chibijs@3.0.9/package.json"     ).is_file()
            ok ("./test.d/lib2/chibijs@3.0.9/README.md"        ).is_file()
            ok ("./test.d/lib2/chibijs@3.0.9/tests/runner.html").is_file()
            from glob import glob
            ok (sorted(glob("./test.d/lib2/chibijs@3.0.9/*"))) == [
                "./test.d/lib2/chibijs@3.0.9/README.md",
                "./test.d/lib2/chibijs@3.0.9/chibi-min.js",
                "./test.d/lib2/chibijs@3.0.9/chibi.js",
                "./test.d/lib2/chibijs@3.0.9/gulpfile.js",
                "./test.d/lib2/chibijs@3.0.9/package.json",
                "./test.d/lib2/chibijs@3.0.9/tests",
            ]

        @test("cdnget --quiet unpkg <library> <version> <directory>")
        def _(self):
            dir = './test.d/lib2'
            at_end(lambda: shutil.rmtree('./test.d'))
            os.makedirs(dir)
            for opt in ["-q", "--quiet"]:
                sout, serr = _run(opt + " unpkg chibijs 3.0.9 %s" % dir)
                ok (serr) == ""
                ok (sout) == ""
                ok ("./test.d/lib2/chibijs@3.0.9/chibi.js"    ).is_file()
                ok ("./test.d/lib2/chibijs@3.0.9/chibi-min.js").is_file()
                ok ("./test.d/lib2/chibijs@3.0.9/README.md"   ).is_file()

        @test("cdnget unpkg non-exist-package", tag="curr")
        def _(self):
            sout, serr = _run("unpkg txamwxzp5")
            ok (serr) == "txamwxzp5: library not found.\n"
            ok (sout) == ""

        @test("cdnget unpkg jquery 999.999.999", tag="curr")
        def _(self):
            sout, serr = _run("unpkg jquery 999.999.999")
            #ok (serr) == "jquery 999.999.999: version not found.\n"
            ok (serr) == "jquery@999.999.999: library or version not found.\n"
            ok (sout) == ""


    with subject("google"):

        @test("cdnget google")
        def _(self):
            sout, serr = _run("google")
            ok (serr) == ""
            libs = []
            for line in sout.splitlines():
                ok (line).matches(r'^\w+([-.]\w+)* *\# latest version: r?\d+(\.\d+)*$')
                libs.append(line.split(' ')[0])
            s = r"""
#angular_material
#angularjs
cesiumjs
d3js
dojo
ext-core
hammerjs
indefinite-observable
jquery
jquery
jquery
jquerymobile
jqueryui
material-motion
mootools
myanmar-tools
prototype
scriptaculous
shaka-player
spf
swfobject
threejs
webfont
"""[1:-1]
            for x in s.split("\n"):
                if x.startswith('#'):
                    continue
                ok (libs).contains(x)

        @test("cdnget google <library>")
        def _(self):
            sout, serr = _run("google jquery")
            ok (serr) == ""
            expected = r"""
name:     jquery
site:     http://jquery.com/
info:     https://developers.google.com/speed/libraries/#jquery
versions:
"""[1:]
            ok (sout.startswith(expected)) == True
            expected2 = r"""
  - 1.4.0
  - 1.3.2
  - 1.3.1
  - 1.3.0
  - 1.2.6
  - 1.2.3
"""[1:]
            ok (sout.endswith(expected2)) == True

        @test("cdnget google <library> <version>")
        def _(self):
            sout, serr = _run("google jquery 2.2.4")
            ok (serr) == ""
            expected = r"""
name:     jquery
version:  2.2.4
site:     http://jquery.com/
info:     https://developers.google.com/speed/libraries/#jquery
urls:
  - https://ajax.googleapis.com/ajax/libs/jquery/2.2.4/jquery.min.js
"""[1:]
            ok (sout) == expected

        @test("cdnget google <library> <version> <directory>")
        def _(self):
            dir = './test.d/lib3'
            at_end(lambda: shutil.rmtree('./test.d'))
            os.makedirs(dir)
            #
            expected = r"""
./test.d/lib3/jquery/2.2.4/jquery.min.js ... Done (85,578 byte)
"""[1:]
            sout, serr = _run("google jquery 2.2.4 %s" % dir)
            ok (serr) == ""
            ok (sout) == expected
            #
            ok ("./test.d/lib3/jquery/2.2.4/jquery.min.js").is_file()
            from glob import glob
            ok (glob("./test.d/lib3/jquery/2.2.4/*")) == [
              "./test.d/lib3/jquery/2.2.4/jquery.min.js",
            ]

        @test("cdnget --quiet google <library> <version> <directory>")
        def _(self):
            dir = './test.d/lib3'
            at_end(lambda: shutil.rmtree('./test.d'))
            os.makedirs(dir)
            for opt in ["-q", "--quiet"]:
                sout, serr = _run(opt + " google jquery 2.2.4 %s" % dir)
                ok (serr) == ""
                ok (sout) == ""
                ok ("./test.d/lib3/jquery/2.2.4/jquery.min.js").is_file()


if __name__ == '__main__':
    oktest.main()
