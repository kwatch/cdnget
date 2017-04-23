#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

##
## Download files from CDN (CDNJS, Google, jsDelivr).
##
## - CDNJS    (https://cdnjs.com/)
## - Google   (https://developers.google.com/speed/libraries/)
## - jsDelivr (https://www.jsdelivr.com/)
##
## Example:
##  $ cdnget                           # list public CDN
##  $ cdnget cdnjs                     # list libraries
##  $ cdnget cdnjs jquery              # list versions
##  $ cdnget cdnjs jquery 2.2.4        # list files
##  $ cdnget cdnjs jquery 2.2.4 /tmp   # download files
##

import sys, os, re
import json

RELEASE = '$Release: 1.0.0 $'.split()[1]

PY2 = sys.version_info[0] == 2
PY3 = sys.version_info[0] == 3
assert PY2 or PY3, "unexpeted python version"

if PY3:
    unicode    = str
    basestring = str
    from urllib.request import urlopen
    from urllib.error import HTTPError
    stdout     = sys.stdout.buffer
    stderr     = sys.stderr.buffer
elif PY2:
    bytes      = str
    from urllib2 import urlopen, HTTPError
    stdout     = sys.stdout
    stderr     = sys.stderr

def U(s, encoding='utf-8'):
    if isinstance(s, bytes):
        return s.decode(encoding)
    return s

def B(s, encoding='utf-8'):
    if isinstance(s, unicode):
        return s.encode(encoding)
    return s

if PY3:
    S = U
elif PY2:
    S = B
else:
    assert False


def echo_n(string):
    stdout.write(B(string))
    stdout.flush()

def read_url(url):
    try:
        req = urlopen(url)
    except HTTPError as ex:
        return None
    else:
        s = req.read()
        req.close()
        return s

def uniq(xs):
    prev = None
    for x in xs:
        if prev != x:
            yield x
            prev = x

def find_one(xs, cond, default=None):
    for x in xs:
        if cond(x):
            return x
    return default

def item_at(arr, i, default=None):
    try:
        return arr[i]
    except IndexError:
        return default

def format_integer(value):
    #return "{:,}".format(value)
    ss = [ m.group(0)[::-1] for m in re.finditer(r'..?.?', str(value)[::-1]) ]
    return ",".join(reversed(ss))


class Base(object):

    def list(self):
        raise NotImplementedError("%s.list(): not implemented yet." % self.__class__.__name__)

    def find(self, library):
        raise NotImplementedError("%s.find(): not implemented yet." % self.__class__.__name__)

    def get(self, library, version):
        raise NotImplementedError("%s.get(): not implemented yet." % self.__class__.__name__)

    def fetch(self, url, library=None):
        return read_url(url)

    def validate(self, library, version):
        if library:
            if not re.match(r'^[-.\w]+$', library):
                raise ValueError("%r: Unexpected library name.")
        if version:
            if not re.match(r'^\d+(\.\d+)+([-.\w]+)?$', version):
                raise ValueError("%r: Unexpected version number." % version)


class CDNJS(Base):
    CODE = "cdnjs"
    SITE_URL = "https://cdnjs.com/"
    API_URL  = "https://api.cdnjs.com/libraries"
    CDN_URL  = "https://cdnjs.cloudflare.com/ajax/libs"

    def list(self):
        jstr = self.fetch("%s?fields=name,description" % self.API_URL)
        jdata = json.loads(S(jstr))
        libs = [ dict(name=d['name'], desc=d['description']) for d in jdata['results'] ]
        return list(uniq(sorted(libs, key=lambda d: d['name'])))

    def find(self, library):
        self.validate(library, None)
        jstr = self.fetch("%s/%s" % (self.API_URL, library))
        jdata = json.loads(S(jstr))
        if jdata == {}:
            return None
        return {
            'name': library,
            'desc': jdata['description'],
            'tags': ", ".join(jdata['keywords'] or []),
            'versions': [ d['version'] for d in jdata['assets'] ],
        }

    def get(self, library, version):
        self.validate(library, version)
        jstr = self.fetch("%s/%s" % (self.API_URL, library))
        jdata = json.loads(S(jstr))
        if jdata == {}:
            return None
        d = find_one(jdata['assets'], lambda d: d['version'] == version)
        if d is None:
            return None
        baseurl = "%s/%s/%s/" % (self.CDN_URL, library, version)
        return {
            'name'   :  library,
            'desc'   :  jdata['description'],
            'tags'   :  ", ".join(jdata['keywords'] or []),
            'version':  version,
            'urls'   :  [ baseurl + s for s in d['files'] ],
            'files'  :  d['files'],
            'baseurl':  baseurl,
        }


class JSDelivr(Base):
    CODE     = "jsdelivr"
    SITE_URL = "https://www.jsdelivr.com/"
    API_URL  = "https://api.jsdelivr.com/v1/jsdelivr/libraries"
    CDN_URL  = "https://cdn.jsdelivr.net/"

    def list(self):
        jstr = self.fetch("%s?fields=name,description,homepage" % self.API_URL)
        arr = json.loads(S(jstr))
        dicts = [ dict(name=d['name'], desc=d['description'], site=d['homepage'])
                      for d in arr ]
        dicts.sort(key=lambda d: d['name'])
        return dicts

    def find(self, library):
        self.validate(library, None)
        jstr = self.fetch("%s?name=%s&fields=name,description,homepage,versions" % (self.API_URL, library))
        if jstr is None:
            return None
        arr = json.loads(S(jstr))
        d = item_at(arr, 0)
        if not d:
            return None
        return {
            'name'    :  d['name'],
            'desc'    :  d['description'],
            'site'    :  d['homepage'],
            'versions':  d['versions'],
        }

    def get(self, library, version):
        self.validate(library, version)
        baseurl = "%s%s/%s" % (self.CDN_URL, library, version)
        jstr  = self.fetch("%s/%s/%s" % (self.API_URL, library, version))
        if jstr is None:
            return None
        files = json.loads(S(jstr))
        if not files:
            raise CommandError("%s: Library not found." % library)
        urls  = [ "%s/%s" % (baseurl, x) for x in files ]
        return {
            'name'   :  library,
            'version':  version,
            'urls'   :  urls,
            'files'  :  files,
            'baseurl':  baseurl,
        }


class GoogleCDN(Base):
    CODE     = "google"
    SITE_URL = "https://developers.google.com/speed/libraries/"
    API_URL  = None
    CDN_URL  = "https://ajax.googleapis.com/ajax/libs"

    def list(self):
        libs = []
        html = S(self.fetch(self.SITE_URL))
        rexp = self.CDN_URL.replace('.', r'\.') + '/([^/]+)/([^/]+)/([^"]+)'
        for m in re.finditer(rexp, html):
            lib, ver, file = m.groups()
            libs.append(dict(name=lib, desc="latest version: %s" % ver))
        return uniq(sorted(libs, key=lambda d: d['name']))

    def find(self, library):    # TODO: use scraping library such as lxml
        self.validate(library, None)
        html = S(self.fetch(self.SITE_URL))
        rexp = self.CDN_URL.replace('.', r'\.') + '/%s' % library
        site_url = None
        versions = []
        urls = []
        found = False
        for m in re.finditer(r'<h3\b.*?>.*?<\/h3>\s*<dl>(.*?)<\/dl>', html, re.S):
            text = m.group(1)
            if not re.search(rexp, text):
                continue
            found = True
            m2 = re.search(r'<dt>.*?snippet:<\/dt>\s*<dd>(.*?)<\/dd>', text, re.S)
            if m2:
                s = m2.group(1)
                for m3 in re.finditer(r'\b(?:src|href)="([^"]*?)"', s):
                    href = m3.group(1)
                    urls.append(href)
            m4 = re.search(r'<dt>site:<\/dt>\s*<dd>(.*?)<\/dd>', text, re.S)
            if m4:
                s = m4.group(1)
                m5 = re.search(r'href="([^"]+)"', s)
                if m5:
                    href = m5.group(1)
                    site_url = href
            for m6 in re.finditer(r'<dt>(?:stable |unstable )?versions:<\/dt>\s*<dd\b.*?>(.*?)<\/dd>', text, re.S):
                s = m6.group(1)
                vers = [ x.strip() for x in s.split(',') ]
                versions.extend(vers)
            break
        if not found:
            return None
        return {
            'name'    : library,
            'site'    : site_url,
            'urls'    : urls,
            'versions': versions,
        }

    def get(self, library, version):
        self.validate(library, version)
        d = self.find(library)
        if version not in d['versions']:
            return None
        urls = d['urls']
        if urls:
            rexp = r'(/libs/%s)/[^/]+' % library
            urls = [ re.sub(rexp, r'\1/%s' % version, s) for s in urls ]
        baseurl = "%s/%s/%s/" % (self.CDN_URL, library, version)
        files = [ s[len(baseurl):] for s in urls ] or None
        return {
            'name'   :  d['name'],
            'site'   :  d['site'],
            'urls'   :  urls,
            'files'  :  files,
            'baseurl':  baseurl,
            'version':  version,
        }


#class JQueryCDN < Base
#  CODE = "jquery"
#  SITE_URL = 'https://code.jquery.com/'
#end


#class ASPNetCDN < Base
#  CODE = "aspnet"
#  SITE_URL = 'https://www.asp.net/ajax/cdn/'
#end


class CommandError(Exception):
    pass


class MainApp(object):

    def __init__(self, script=None):
        self.script = script or os.path.basename(sys.argv[0])

    def help_message(self, ):
        return r'''
{script}  -- download files from public CDN

Usage: {script} [<options>] [<CDN>] [<library>] [<version>] [<directory>]

Options:
    -h, --help        : help
    -v, --version     : version
    -q, --quiet       : minimal output

Example:
    $ {script}                           # list public CDN
    $ {script} cdnjs                     # list libraries
    $ {script} cdnjs jquery              # list versions
    $ {script} cdnjs jquery 2.2.4        # list files
    $ {script} cdnjs jquery 2.2.4 /tmp   # download files
'''[1:].format(script=self.script)

    def run(self, *args):
        args = list(args)
        cmdopts = self.parse_cmdopts(args, "hvq", ["help", "version", "quiet"])
        opt = cmdopts.get
        if opt('h') or opt('help'):
            return self.help_message()
        if opt('v') or opt('version'):
            return "%s\n" % RELEASE
        self.quiet = bool(opt('q') or opt('quiet'))
        #
        self.validate(item_at(args, 1), item_at(args, 2))
        #
        n = len(args)
        if n == 0:
            return self.do_list_cdns()
        elif n == 1:
            cdn_code = args[0]
            return self.do_list_libraries(cdn_code)
        elif n == 2:
            cdn_code, library = args
            if '*' in library:
                return self.do_search_libraries(cdn_code, library)
            else:
                return self.do_find_library(cdn_code, library)
        elif n == 3:
            cdn_code, library, version = args
            return self.do_get_library(cdn_code, library, version)
        elif n == 4:
            cdn_code, library, version, basedir = args
            self.do_download_library(cdn_code, library, version, basedir)
            return ""
        else:
            raise CommandError("%r: Too many arguments." % args[4])

    def validate(self, library, version):
        if library and '*' not in library:
            if not re.match(r'^[-.\w]+$', library):
                raise CommandError("%s: Unexpected library name." % library)
        if version:
            if not re.match(r'[-.\w]+', version):
                raise CommandError("%s: Unexpected version number." % version)

    def parse_cmdopts(self, cmdargs, short_opts, long_opts):
        options = {}
        while cmdargs and cmdargs[0].startswith('-'):
            optstr = cmdargs.pop(0)
            if optstr == '--':
                break
            elif optstr.startswith('--'):
                m = re.match(r'^--(\w[-\w]+)(=.*?)?$', optstr)
                if not m:
                    raise CommandError("%s: invalid command option." % optstr)
                name, value = m.groups()
                if name not in long_opts:
                    raise CommandError("%s: unknown command option." % optstr)
                options[name] = value[1:] if value else True
            elif optstr.startswith('-'):
                for c in optstr[1:]:
                    if c not in short_opts:
                        raise CommandError("-%s: unknown command option." % c)
                    options[c] = True
            else:
                assert False, "unreachable"
        return options

    def find_cdn(self, cdn_code):
        classes = Base.__subclasses__()
        klass = find_one(classes, lambda c: c.CODE == cdn_code)
        if klass is None:
            raise CommandError("%s: no such CDN." % cdn_code)
        return klass()

    def render_list(self, list):
        if self.quiet:
            fn = lambda d: "%s\n" % d['name']
        else:
            f = lambda s: (s or "").replace("\n", " ").replace("\r", " ")
            fn = lambda d, f=f: "%-20s  # %s\n" % (d['name'], f(d['desc']))
        return "".join( fn(d) for d in list )

    def do_list_cdns(self):
        if self.quiet:
            fn = lambda c: "%s\n" % c.CODE
        else:
            fn = lambda c: "%-10s  # %s\n" % (c.CODE, c.SITE_URL)
        classes = Base.__subclasses__()
        return "".join( fn(c) for c in classes )

    def do_list_libraries(self, cdn_code):
        cdn = self.find_cdn(cdn_code)
        return self.render_list(cdn.list())

    def do_search_libraries(self, cdn_code, pattern):
        cdn = self.find_cdn(cdn_code)
        rexp_str = '.*'.join( re.escape(x) for x in pattern.split('*') )
        rexp = re.compile(r'^%s$' % rexp_str, re.I)
        return self.render_list( a for a in cdn.list if rexp.match(a['name']) )

    def do_find_library(self, cdn_code, library):
        cdn = self.find_cdn(cdn_code)
        d = cdn.find(library)
        if d is None:
            raise CommandError("%s: library not found." % library)
        buf = []; add = buf.append
        if self.quiet:
            if d['versions']:
                for ver in d['versions']:
                    add("\n" % ver)
        else:
            add("name:  %s\n" % d['name'])
            if d.get('desc'):  add("desc:  %s\n" % d['desc'])
            if d.get('tags'):  add("tags:  %s\n" % d['tags'])
            if d.get('site'):  add("site:  %s\n" % d['site'])
            if d.get('snippet'):
                add("snippet: |\n")
                add(re.sub(r'^', "    ", d['snippet']))
            if d.get('versions'):
                add("versions:\n")
                buf.extend( "  - %s\n" % ver for ver in d['versions'] )
        return "".join(buf)

    def do_get_library(self, cdn_code, library, version):
        cdn = self.find_cdn(cdn_code)
        d = cdn.get(library, version)
        if d is None:
            if cdn.find(library) is None:
                raise CommandError("%s: library not found." % library)
            else:
                raise CommandError("%s %s: version not found." % (library, version))
        buf = []; add = buf.append
        if self.quiet:
            if d.get('urls'):
                for url in d['urls']:
                    add("%s\n" % url)
        else:
            add("name:     %s\n" % d['name'])
            add("version:  %s\n" % d['version'])
            if d.get('desc'):  add("desc:     %s\n" % d['desc'])
            if d.get('tags'):  add("tags:     %s\n" % d['tags'])
            if d.get('site'):  add("site:     %s\n" % d['site'])
            if d.get('snippet'):
                add("snippet: |\n")
                add(re.sub(r'^', "    ", d['snippet']))
            if d.get('urls'):
                add("urls:\n")
                for url in d['urls']:
                    add("  - %s\n" % url)
        return "".join(buf)

    def do_download_library(self, cdn_code, library, version, basedir):
        cdn = self.find_cdn(cdn_code)
        cdn.validate(library, version)
        if not os.path.exists(basedir):
            raise CommandError("%s: not exist." % basedir)
        if not os.path.isdir(basedir):
            raise CommandError("%s: not a directory." % basedir)
        quiet = self.quiet
        target_dir = os.path.join(basedir, library, version)
        d = cdn.get(library, version)
        for file in d['files']:
            filepath = os.path.join(target_dir, file)
            dirpath  = os.path.dirname(filepath)
            if not quiet:
                echo_n("%s ..." % filepath)
            url = os.path.join(d['baseurl'], file)
            content = cdn.fetch(url)
            content = B(content)
            if not quiet:
                echo_n(" Done (%s byte)" % format_integer(len(content)))
            if not os.path.exists(dirpath):
                os.makedirs(dirpath)
            unchanged = False
            if os.path.exists(filepath):
                with open(filepath, 'rb') as f:
                    unchanged = f.read() == content
            if unchanged:
                if not quiet:
                    echo_n(" (Unchanged)")
            else:
                with open(filepath, 'wb') as f:
                    f.write(content)
            if not quiet:
                echo_n("\n")


def main(args=None):
    if args is None:
        args = sys.argv[1:]
    try:
        output = MainApp().run(*args)
    except CommandError as ex:
        stderr.write(B(str(ex)))
        stderr.write(b"\n")
        sys.exit(1)
    else:
        if output:
            stdout.write(B(output))
        sys.exit(0)


if __name__ == '__main__':
    main()
