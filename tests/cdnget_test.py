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
google      # https://developers.google.com/speed/libraries/
"""[1:]

        @test("cdnget -h, --help")
        def _(self):
            expected = r"""
cdnget  -- download files from public CDN

Usage: cdnget [<options>] [<CDN>] [<library>] [<version>] [<directory>]

Options:
    -h, --help        : help
    -v, --version     : version
    -q, --quiet       : minimal output

Example:
    $ cdnget                           # list public CDN
    $ cdnget cdnjs                     # list libraries
    $ cdnget cdnjs jquery              # list versions
    $ cdnget cdnjs jquery 2.2.4        # list files
    $ cdnget cdnjs jquery 2.2.4 /tmp   # download files
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
            lines = sout.splitlines(True)
            ok (lines[0]) == "name:  jquery\n"
            ok (lines[1]) == "desc:  JavaScript library for DOM operations\n"
            ok (lines[2]) == "tags:  jquery, library, ajax, framework, toolkit, popular\n"
            ok (lines[3]) == "versions:\n"
            for line in lines[4:]:
                ok (line).matches(r'  - \d+(\.\d+)+')

        @test("cdnget cdnjs <library> <version>")
        def _(self):
            sout, serr = _run("cdnjs jquery 2.2.4")
            ok (serr) == ""
            expected = r"""
name:     jquery
version:  2.2.4
desc:     JavaScript library for DOM operations
tags:     jquery, library, ajax, framework, toolkit, popular
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
            ok (glob("./test.d/lib1/jquery/2.2.4/*")) == [
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

        jquery_desc = (
            "jQuery is a fast and concise JavaScript Library that simplifies "
            "HTML document traversing, event handling, animating, and Ajax "
            "interactions for rapid web development. jQuery is designed to "
            "change the way that you write JavaScript."
        )

        @test("cdnget jsdelivr")
        def _(self):
            sout, serr = _run("jsdelivr")
            ok (serr) == ""
            for line in sout.splitlines():
                ok (line).matches(r'^\w+([-.]\w+)* *\# .*$')
            expected = ("jquery                # " + self.jquery_desc)
            ok (sout).contains("\n%s\n" % expected)

        @test("cdnget jsdelivr <library>")
        def _(self):
            sout, serr = _run("jsdelivr jquery")
            ok (serr) == ""
            lines = sout.splitlines(True)
            ok (lines[0]) == "name:  jquery\n"
            ok (lines[1]) == "desc:  %s\n" % self.jquery_desc
            ok (lines[2]) == "site:  http://jquery.com/\n"
            ok (lines[3]) == "versions:\n"
            for line in lines[4:]:
                ok (line).matches(r'  - \d+(\.\d+)+')

        @test("cdnget jsdelivr <library> <version>")
        def _(self):
            sout, serr = _run("jsdelivr jquery 2.2.4")
            ok (serr) == ""
            expected = r"""
name:     jquery
version:  2.2.4
urls:
  - https://cdn.jsdelivr.net/jquery/2.2.4/jquery.js
  - https://cdn.jsdelivr.net/jquery/2.2.4/jquery.min.js
  - https://cdn.jsdelivr.net/jquery/2.2.4/jquery.min.map
"""[1:]
            ok (sout) == expected

        @test("cdnget jsdelivr <library> <version> <directory>")
        def _(self):
            dir = './test.d/lib2'
            at_end(lambda: shutil.rmtree('./test.d'))
            os.makedirs(dir)
            #
            expected = r"""
./test.d/lib2/jquery/2.2.4/jquery.js ... Done (257,551 byte)
./test.d/lib2/jquery/2.2.4/jquery.min.js ... Done (85,578 byte)
./test.d/lib2/jquery/2.2.4/jquery.min.map ... Done (129,572 byte)
"""[1:]
            sout, serr = _run("jsdelivr jquery 2.2.4 %s" % dir)
            ok (serr) == ""
            ok (sout) == expected
            #
            ok ("./test.d/lib2/jquery/2.2.4/jquery.js").is_file()
            ok ("./test.d/lib2/jquery/2.2.4/jquery.min.js").is_file()
            ok ("./test.d/lib2/jquery/2.2.4/jquery.min.map").is_file()
            from glob import glob
            ok (glob("./test.d/lib2/jquery/2.2.4/*")) == [
              "./test.d/lib2/jquery/2.2.4/jquery.js",
              "./test.d/lib2/jquery/2.2.4/jquery.min.js",
              "./test.d/lib2/jquery/2.2.4/jquery.min.map",
            ]

        @test("cdnget --quiet jsdelivr <library> <version> <directory>")
        def _(self):
            dir = './test.d/lib2'
            at_end(lambda: shutil.rmtree('./test.d'))
            os.makedirs(dir)
            for opt in ["-q", "--quiet"]:
                sout, serr = _run(opt + " jsdelivr jquery 2.2.4 %s" % dir)
                ok (serr) == ""
                ok (sout) == ""
                ok ("./test.d/lib2/jquery/2.2.4/jquery.js").is_file()
                ok ("./test.d/lib2/jquery/2.2.4/jquery.min.js").is_file()
                ok ("./test.d/lib2/jquery/2.2.4/jquery.min.map").is_file()

        @test("cdnget jsdelivr blablabla", tag="curr")
        def _(self):
            sout, serr = _run("jsdelivr blablabla")
            ok (serr) == "blablabla: library not found.\n"
            ok (sout) == ""

        @test("cdnget jsdelivr jquery 999.999.999", tag="curr")
        def _(self):
            sout, serr = _run("jsdelivr jquery 999.999.999")
            ok (serr) == "jquery 999.999.999: version not found.\n"
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
angular_material
angularjs
dojo
ext-core
hammerjs
indefinite-observable
jquery
jquery
jquery
jquerymobile
jqueryui
mootools
prototype
scriptaculous
spf
swfobject
threejs
webfont
"""[1:-1]
            for x in s.split("\n"):
                ok (libs).contains(x)

        @test("cdnget google <library>")
        def _(self):
            sout, serr = _run("google jquery")
            ok (serr) == ""
            lines = sout.splitlines(True)
            ok (lines[0]) == "name:  jquery\n"
            ok (lines[1]) == "site:  http://jquery.com/\n"
            ok (lines[2]) == "versions:\n"
            for line in lines[3:]:
                ok (line).matches(r'  - \d+(\.\d+)+')

        @test("cdnget google <library> <version>")
        def _(self):
            sout, serr = _run("google jquery 2.2.4")
            ok (serr) == ""
            expected = r"""
name:     jquery
version:  2.2.4
site:     http://jquery.com/
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
