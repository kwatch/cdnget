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

        @test("cdnget cdnjs @babel/core")
        def _(self):
            sout, serr = _run("cdnjs @babel/core")
            ok (serr) == "@babel/core: unexpected library name.\n"
            ok (sout) == ""

        @test("cdnget cdnjs @babel/core <version>")
        def _(self):
            sout, serr = _run("cdnjs @babel/core 7.15.5")
            ok (serr) == "@babel/core: unexpected library name.\n"
            ok (sout) == ""

        @test("cdnget cdnjs @babel/core <version> <dir>")
        def _(self):
            dir = './test.d'
            at_end(lambda: shutil.rmtree('./test.d'))
            os.makedirs(dir)
            sout, serr = _run("cdnjs @babel/core 7.15.5 %s" % dir)
            ok (serr) == "@babel/core: unexpected library name.\n"
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

        @test("cdnget jsdelivr non-exist-package")
        def _(self):
            sout, serr = _run("jsdelivr txamwxzp5")
            ok (serr) == "txamwxzp5: library not found.\n"
            ok (sout) == ""

        @test("cdnget jsdelivr jquery 999.999.999")
        def _(self):
            sout, serr = _run("jsdelivr jquery 999.999.999")
            #ok (serr) == "jquery 999.999.999: version not found.\n"
            ok (serr) == "jquery@999.999.999: library or version not found.\n"
            ok (sout) == ""

        @test("cdnget jsdelivr @babel/core")
        def _(self):
            sout, serr = _run("jsdelivr @babel/core")
            ok (serr) == ""
            ok (sout.startswith(r"""
name:     @babel/core
desc:     Babel compiler core.
tags:     6to5, babel, classes, const, es6, harmony, let, modules, transpile, transpiler, var, babel-core, compiler
site:     https://babel.dev/docs/en/next/babel-core
info:     https://www.jsdelivr.com/package/npm/@babel/core
license:  MIT
versions:
"""[1:])) == True

        @test("cdnget jsdelivr @babel/core <version>")
        def _(self):
            sout, serr = _run("jsdelivr @babel/core 7.15.5")
            ok (serr) == ""
            ok (sout.startswith(r"""
name:     @babel/core
version:  7.15.5
desc:     Babel compiler core.
tags:     6to5, babel, classes, const, es6, harmony, let, modules, transpile, transpiler, var, babel-core, compiler
site:     https://babel.dev/docs/en/next/babel-core
info:     https://www.jsdelivr.com/package/npm/@babel/core?version=7.15.5
npmpkg:   https://registry.npmjs.org/@babel%2fcore/-/core-7.15.5.tgz
default:  /lib/index.min.js
license:  MIT
urls:
"""[1:])) == True

        @test("cdnget jsdelivr @babel/core <version> <dir>")
        def _(self):
            dir = './test.d'
            at_end(lambda: shutil.rmtree('./test.d'))
            os.makedirs(dir)
            sout, serr = _run("jsdelivr @babel/core 7.15.5 %s" % dir)
            ok (serr) == ""
            ok (sout) == r"""
{dir}/@babel/core@7.15.5/lib/config/cache-contexts.js ... Done (0 byte)
{dir}/@babel/core@7.15.5/lib/config/caching.js ... Done (7,327 byte)
{dir}/@babel/core@7.15.5/lib/config/config-chain.js ... Done (17,871 byte)
{dir}/@babel/core@7.15.5/lib/config/config-descriptors.js ... Done (6,756 byte)
{dir}/@babel/core@7.15.5/lib/config/files/configuration.js ... Done (9,975 byte)
{dir}/@babel/core@7.15.5/lib/config/files/import.js ... Done (165 byte)
{dir}/@babel/core@7.15.5/lib/config/files/index.js ... Done (1,760 byte)
{dir}/@babel/core@7.15.5/lib/config/files/index-browser.js ... Done (1,550 byte)
{dir}/@babel/core@7.15.5/lib/config/files/module-types.js ... Done (2,731 byte)
{dir}/@babel/core@7.15.5/lib/config/files/package.js ... Done (1,509 byte)
{dir}/@babel/core@7.15.5/lib/config/files/plugins.js ... Done (6,287 byte)
{dir}/@babel/core@7.15.5/lib/config/files/types.js ... Done (0 byte)
{dir}/@babel/core@7.15.5/lib/config/files/utils.js ... Done (856 byte)
{dir}/@babel/core@7.15.5/lib/config/full.js ... Done (9,211 byte)
{dir}/@babel/core@7.15.5/lib/config/helpers/config-api.js ... Done (2,593 byte)
{dir}/@babel/core@7.15.5/lib/config/helpers/environment.js ... Done (227 byte)
{dir}/@babel/core@7.15.5/lib/config/index.js ... Done (2,462 byte)
{dir}/@babel/core@7.15.5/lib/config/item.js ... Done (1,802 byte)
{dir}/@babel/core@7.15.5/lib/config/partial.js ... Done (5,647 byte)
{dir}/@babel/core@7.15.5/lib/config/pattern-to-regex.js ... Done (1,143 byte)
{dir}/@babel/core@7.15.5/lib/config/plugin.js ... Done (744 byte)
{dir}/@babel/core@7.15.5/lib/config/printer.js ... Done (2,893 byte)
{dir}/@babel/core@7.15.5/lib/config/resolve-targets.js ... Done (1,430 byte)
{dir}/@babel/core@7.15.5/lib/config/resolve-targets-browser.js ... Done (945 byte)
{dir}/@babel/core@7.15.5/lib/config/util.js ... Done (887 byte)
{dir}/@babel/core@7.15.5/lib/config/validation/option-assertions.js ... Done (9,985 byte)
{dir}/@babel/core@7.15.5/lib/config/validation/options.js ... Done (7,749 byte)
{dir}/@babel/core@7.15.5/lib/config/validation/plugins.js ... Done (1,982 byte)
{dir}/@babel/core@7.15.5/lib/config/validation/removed.js ... Done (2,374 byte)
{dir}/@babel/core@7.15.5/lib/gensync-utils/async.js ... Done (1,775 byte)
{dir}/@babel/core@7.15.5/lib/gensync-utils/fs.js ... Done (576 byte)
{dir}/@babel/core@7.15.5/lib/index.js ... Done (5,697 byte)
{dir}/@babel/core@7.15.5/lib/parse.js ... Done (1,085 byte)
{dir}/@babel/core@7.15.5/lib/parser/index.js ... Done (2,260 byte)
{dir}/@babel/core@7.15.5/lib/parser/util/missing-plugin-helper.js ... Done (7,985 byte)
{dir}/@babel/core@7.15.5/lib/tools/build-external-helpers.js ... Done (4,331 byte)
{dir}/@babel/core@7.15.5/lib/transform.js ... Done (1,059 byte)
{dir}/@babel/core@7.15.5/lib/transform-ast.js ... Done (1,257 byte)
{dir}/@babel/core@7.15.5/lib/transform-file.js ... Done (1,059 byte)
{dir}/@babel/core@7.15.5/lib/transform-file-browser.js ... Done (692 byte)
{dir}/@babel/core@7.15.5/lib/transformation/block-hoist-plugin.js ... Done (1,802 byte)
{dir}/@babel/core@7.15.5/lib/transformation/file/file.js ... Done (5,864 byte)
{dir}/@babel/core@7.15.5/lib/transformation/file/generate.js ... Done (1,903 byte)
{dir}/@babel/core@7.15.5/lib/transformation/file/merge-map.js ... Done (5,412 byte)
{dir}/@babel/core@7.15.5/lib/transformation/index.js ... Done (3,296 byte)
{dir}/@babel/core@7.15.5/lib/transformation/normalize-file.js ... Done (3,796 byte)
{dir}/@babel/core@7.15.5/lib/transformation/normalize-opts.js ... Done (1,543 byte)
{dir}/@babel/core@7.15.5/lib/transformation/plugin-pass.js ... Done (1,035 byte)
{dir}/@babel/core@7.15.5/lib/transformation/util/clone-deep.js ... Done (453 byte)
{dir}/@babel/core@7.15.5/lib/transformation/util/clone-deep-browser.js ... Done (599 byte)
{dir}/@babel/core@7.15.5/LICENSE ... Done (1,106 byte)
{dir}/@babel/core@7.15.5/package.json ... Done (2,395 byte)
{dir}/@babel/core@7.15.5/README.md ... Done (404 byte)
{dir}/@babel/core@7.15.5/src/config/files/index.ts ... Done (735 byte)
{dir}/@babel/core@7.15.5/src/config/files/index-browser.ts ... Done (2,846 byte)
{dir}/@babel/core@7.15.5/src/config/resolve-targets.ts ... Done (1,612 byte)
{dir}/@babel/core@7.15.5/src/config/resolve-targets-browser.ts ... Done (1,074 byte)
{dir}/@babel/core@7.15.5/src/transform-file.ts ... Done (1,475 byte)
{dir}/@babel/core@7.15.5/src/transform-file-browser.ts ... Done (716 byte)
{dir}/@babel/core@7.15.5/src/transformation/util/clone-deep.ts ... Done (223 byte)
{dir}/@babel/core@7.15.5/src/transformation/util/clone-deep-browser.ts ... Done (500 byte)
"""[1:].format(dir=dir)


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

        @test("cdnget unpkg non-exist-package")
        def _(self):
            sout, serr = _run("unpkg txamwxzp5")
            ok (serr) == "txamwxzp5: library not found.\n"
            ok (sout) == ""

        @test("cdnget unpkg jquery 999.999.999")
        def _(self):
            sout, serr = _run("unpkg jquery 999.999.999")
            #ok (serr) == "jquery 999.999.999: version not found.\n"
            ok (serr) == "jquery@999.999.999: library or version not found.\n"
            ok (sout) == ""

        @test("cdnget unpkg @babel/core")
        def _(self):
            sout, serr = _run("unpkg @babel/core")
            ok (serr) == ""
            ok (sout.startswith(r"""
name:     @babel/core
desc:     Babel compiler core.
tags:     6to5, babel, classes, const, es6, harmony, let, modules, transpile, transpiler, var, babel-core, compiler
site:     https://babel.dev/docs/en/next/babel-core
info:     https://unpkg.com/browse/@babel/core/
license:  MIT
versions:
"""[1:])) == True

        @test("cdnget unpkg @babel/core <version>")
        def _(self):
            sout, serr = _run("unpkg @babel/core 7.15.5")
            ok (serr) == ""
            ok (sout.startswith(r"""
name:     @babel/core
version:  7.15.5
desc:     Babel compiler core.
tags:     6to5, babel, classes, const, es6, harmony, let, modules, transpile, transpiler, var, babel-core, compiler
site:     https://babel.dev/docs/en/next/babel-core
info:     https://unpkg.com/browse/@babel/core@7.15.5/
npmpkg:   https://registry.npmjs.org/@babel%2fcore/-/core-7.15.5.tgz
default:  /lib/index.min.js
license:  MIT
urls:
"""[1:])) == True

        @test("cdnget unpkg @babel/core <version> <dir>")
        def _(self):
            dir = './test.d'
            at_end(lambda: shutil.rmtree('./test.d'))
            os.makedirs(dir)
            sout, serr = _run("unpkg @babel/core 7.15.5 %s" % dir)
            ok (serr) == ""
            ok (sout) == r"""
{dir}/@babel/core@7.15.5/lib/config/cache-contexts.js ... Done (0 byte)
{dir}/@babel/core@7.15.5/lib/config/caching.js ... Done (7,327 byte)
{dir}/@babel/core@7.15.5/lib/config/config-chain.js ... Done (17,871 byte)
{dir}/@babel/core@7.15.5/lib/config/config-descriptors.js ... Done (6,756 byte)
{dir}/@babel/core@7.15.5/lib/config/files/configuration.js ... Done (9,975 byte)
{dir}/@babel/core@7.15.5/lib/config/files/import.js ... Done (165 byte)
{dir}/@babel/core@7.15.5/lib/config/files/index.js ... Done (1,760 byte)
{dir}/@babel/core@7.15.5/lib/config/files/index-browser.js ... Done (1,550 byte)
{dir}/@babel/core@7.15.5/lib/config/files/module-types.js ... Done (2,731 byte)
{dir}/@babel/core@7.15.5/lib/config/files/package.js ... Done (1,509 byte)
{dir}/@babel/core@7.15.5/lib/config/files/plugins.js ... Done (6,287 byte)
{dir}/@babel/core@7.15.5/lib/config/files/types.js ... Done (0 byte)
{dir}/@babel/core@7.15.5/lib/config/files/utils.js ... Done (856 byte)
{dir}/@babel/core@7.15.5/lib/config/full.js ... Done (9,211 byte)
{dir}/@babel/core@7.15.5/lib/config/helpers/config-api.js ... Done (2,593 byte)
{dir}/@babel/core@7.15.5/lib/config/helpers/environment.js ... Done (227 byte)
{dir}/@babel/core@7.15.5/lib/config/index.js ... Done (2,462 byte)
{dir}/@babel/core@7.15.5/lib/config/item.js ... Done (1,802 byte)
{dir}/@babel/core@7.15.5/lib/config/partial.js ... Done (5,647 byte)
{dir}/@babel/core@7.15.5/lib/config/pattern-to-regex.js ... Done (1,143 byte)
{dir}/@babel/core@7.15.5/lib/config/plugin.js ... Done (744 byte)
{dir}/@babel/core@7.15.5/lib/config/printer.js ... Done (2,893 byte)
{dir}/@babel/core@7.15.5/lib/config/resolve-targets.js ... Done (1,430 byte)
{dir}/@babel/core@7.15.5/lib/config/resolve-targets-browser.js ... Done (945 byte)
{dir}/@babel/core@7.15.5/lib/config/util.js ... Done (887 byte)
{dir}/@babel/core@7.15.5/lib/config/validation/option-assertions.js ... Done (9,985 byte)
{dir}/@babel/core@7.15.5/lib/config/validation/options.js ... Done (7,749 byte)
{dir}/@babel/core@7.15.5/lib/config/validation/plugins.js ... Done (1,982 byte)
{dir}/@babel/core@7.15.5/lib/config/validation/removed.js ... Done (2,374 byte)
{dir}/@babel/core@7.15.5/lib/gensync-utils/async.js ... Done (1,775 byte)
{dir}/@babel/core@7.15.5/lib/gensync-utils/fs.js ... Done (576 byte)
{dir}/@babel/core@7.15.5/lib/index.js ... Done (5,697 byte)
{dir}/@babel/core@7.15.5/lib/parse.js ... Done (1,085 byte)
{dir}/@babel/core@7.15.5/lib/parser/index.js ... Done (2,260 byte)
{dir}/@babel/core@7.15.5/lib/parser/util/missing-plugin-helper.js ... Done (7,985 byte)
{dir}/@babel/core@7.15.5/lib/tools/build-external-helpers.js ... Done (4,331 byte)
{dir}/@babel/core@7.15.5/lib/transform.js ... Done (1,059 byte)
{dir}/@babel/core@7.15.5/lib/transform-ast.js ... Done (1,257 byte)
{dir}/@babel/core@7.15.5/lib/transform-file.js ... Done (1,059 byte)
{dir}/@babel/core@7.15.5/lib/transform-file-browser.js ... Done (692 byte)
{dir}/@babel/core@7.15.5/lib/transformation/block-hoist-plugin.js ... Done (1,802 byte)
{dir}/@babel/core@7.15.5/lib/transformation/file/file.js ... Done (5,864 byte)
{dir}/@babel/core@7.15.5/lib/transformation/file/generate.js ... Done (1,903 byte)
{dir}/@babel/core@7.15.5/lib/transformation/file/merge-map.js ... Done (5,412 byte)
{dir}/@babel/core@7.15.5/lib/transformation/index.js ... Done (3,296 byte)
{dir}/@babel/core@7.15.5/lib/transformation/normalize-file.js ... Done (3,796 byte)
{dir}/@babel/core@7.15.5/lib/transformation/normalize-opts.js ... Done (1,543 byte)
{dir}/@babel/core@7.15.5/lib/transformation/plugin-pass.js ... Done (1,035 byte)
{dir}/@babel/core@7.15.5/lib/transformation/util/clone-deep.js ... Done (453 byte)
{dir}/@babel/core@7.15.5/lib/transformation/util/clone-deep-browser.js ... Done (599 byte)
{dir}/@babel/core@7.15.5/LICENSE ... Done (1,106 byte)
{dir}/@babel/core@7.15.5/package.json ... Done (2,395 byte)
{dir}/@babel/core@7.15.5/README.md ... Done (404 byte)
{dir}/@babel/core@7.15.5/src/config/files/index.ts ... Done (735 byte)
{dir}/@babel/core@7.15.5/src/config/files/index-browser.ts ... Done (2,846 byte)
{dir}/@babel/core@7.15.5/src/config/resolve-targets.ts ... Done (1,612 byte)
{dir}/@babel/core@7.15.5/src/config/resolve-targets-browser.ts ... Done (1,074 byte)
{dir}/@babel/core@7.15.5/src/transform-file.ts ... Done (1,475 byte)
{dir}/@babel/core@7.15.5/src/transform-file-browser.ts ... Done (716 byte)
{dir}/@babel/core@7.15.5/src/transformation/util/clone-deep.ts ... Done (223 byte)
{dir}/@babel/core@7.15.5/src/transformation/util/clone-deep-browser.ts ... Done (500 byte)
"""[1:].format(dir=dir)


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

        @test("cdnget google @babel/core")
        def _(self):
            sout, serr = _run("google @babel/core")
            ok (serr) == "@babel/core: unexpected library name.\n"
            ok (sout) == ""

        @test("cdnget google @babel/core <version>")
        def _(self):
            sout, serr = _run("google @babel/core 7.15.5")
            ok (serr) == "@babel/core: unexpected library name.\n"
            ok (sout) == ""

        @test("cdnget google @babel/core <version> <dir>")
        def _(self):
            dir = './test.d'
            at_end(lambda: shutil.rmtree('./test.d'))
            os.makedirs(dir)
            sout, serr = _run("google @babel/core 7.15.5 %s" % dir)
            ok (serr) == "@babel/core: unexpected library name.\n"
            ok (sout) == ""


if __name__ == '__main__':
    oktest.main()
