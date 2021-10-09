#!/usr/bin/env python
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
import gzip

RELEASE = '$Release: 0.0.0 $'.split()[1]

PY2 = sys.version_info[0] == 2
PY3 = sys.version_info[0] == 3
if not (PY2 or PY3):
    raise RuntimeError("unexpeted python version")

if PY3:
    unicode    = str
    basestring = str
    from urllib.request import urlopen, Request
    from urllib.error import HTTPError
    from urllib.parse import urlencode, urlparse, urljoin
    from http.client import HTTPConnection, HTTPSConnection
    stdout     = sys.stdout.buffer
    stderr     = sys.stderr.buffer
elif PY2:
    bytes      = str
    from urllib2 import urlopen, Request, HTTPError
    from urllib import urlencode
    from urlparse import urlparse, urljoin
    from httplib import HTTPConnection, HTTPSConnection
    stdout     = sys.stdout
    stderr     = sys.stderr
else:
    assert False, "** failed to detect Python version (2 or 3)."

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


def to_i(s):
    try:
        return int(s)
    except:
        return 0

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

def sort_versions(versions, reverse=False):
    versions.sort()
    versions.sort(key=lambda x: tuple( to_i(s) for s in x.split('.') ))
    if reverse:
        versions.reverse()
    return versions

def json_dump(x):
    return json.dumps(x, ensure_ascii=False, indent=4, separators=(', ', ': '))

_debug_mode = False

def _debug_print(x):
    if not _debug_mode:
        return
    if isinstance(x, dict):
        stderr.write(B("\033[0;35m*** %s\033[0m\n" % json_dump(x)))
    else:
        stderr.write(B("\033[0;35m*** %r\033[0m\n" % (x,)))


class HttpConn(object):

    def __init__(self, uri, default_headers=None):
        if   uri.scheme == 'http':   klass = HTTPConnection
        elif uri.scheme == 'https':  klass = HTTPSConnection
        else:
            raise TypeError("expected only http or https.")
        self.conn = klass(uri.netloc, uri.port)
        self.default_headers = default_headers

    def close(self):
        self.conn.close()

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.conn.close()

    def get(self, uri, headers=None, data=None):
        resp = self.request('GET', uri.path, uri.query, data, headers)
        i = 10
        while resp.status == 302:
            location = resp.getheader('location')
            if not (location and location.startswith('/')):
                break
            _ = resp.read()            # to avoid http.client.ResponseNotReady
            uri = urlparse(location)   # todo: support port etc
            resp = self.request('GET', uri.path, uri.query, data, headers)
            i -= 1
            if i <= 0:
                break
        return self._get_resp_body(resp, uri)

    def post(self, uri, headers=None, data=None):
        resp = self.request('POST', uri.path, uri.query, data, headers)
        return self._get_resp_body(resp, uri)

    def request(self, method, path, query=None, headers=None, data=None):
        headers_ = self._build_req_headers(headers)
        if query:
            path += "?"+query
        #self.conn.request(method, path, data=data, headers=headers_)  # TypeError: request() got an unexpected keyword argument 'data'
        self.conn.request(method, path, data, headers=headers_)
        resp = self.conn.getresponse()
        return resp

    def _build_req_headers(self, headers):
        headers_ = {}
        if self.default_headers:
            headers_.update(self.default_headers)
        if hasattr(gzip, 'decompress'):
            headers_['accept-encoding'] = 'gzip'
        if headers:
            headers_.update(headers)
        return headers_

    def _get_resp_body(self, resp, uri):
        if 200 <= resp.status < 300:
            return self._read_resp_body(resp)
        else:
            raise HTTPError(uri.geturl(), resp.status, resp.reason, resp.getheader, resp.fp)

    def _read_resp_body(self, resp):
        binary = resp.read()
        if resp.getheader('content-encoding') == 'gzip':
            binary = gzip.decompress(binary)
        return binary


class Base(object):

    def list(self):
        raise NotImplementedError("%s.list(): not implemented yet." % self.__class__.__name__)

    def search(self, pattern):
        rexp = self.pattern2rexp(pattern)
        return [ d for d in self.list() if rexp.match(d['name']) ]

    def find(self, library):
        raise NotImplementedError("%s.find(): not implemented yet." % self.__class__.__name__)

    def get(self, library, version):
        raise NotImplementedError("%s.get(): not implemented yet." % self.__class__.__name__)

    def download(self, library, version, basedir=".", quiet=False):
        self.validate(library, version)
        if not os.path.exists(basedir):
            raise CommandError("%s: not exist." % basedir)
        if not os.path.isdir(basedir):
            raise CommandError("%s: not a directory." % basedir)
        d = self.get(library, version)
        target_dir = (os.path.join(basedir, d['destdir']) if d.get('destdir') else
                      os.path.join(basedir, library, version))
        http_conn = None
        skipfile = d.get('skipfile')
        for file in d['files']:
            #filepath = os.path.join(target_dir, file)   # wrong!
            filepath = "%s%s" % (target_dir, file)
            #
            if skipfile and skipfile.match(file):
                print("%s ... Skipped" % file)   # for example, skip '.DS_Store' files
                continue
            #
            if filepath.endswith('/'):
                if os.path.exists(filepath):
                    if not quiet:
                        print("%s ... Done (Already exists)" % filepath)
                else:
                    if not quiet:
                        stdout.write("%s ..." % filepath)
                    os.makedirs(filepath)
                    if not quiet:
                        print("Done (Created)")
                continue
            #
            dirpath  = os.path.dirname(filepath)
            if not quiet:
                echo_n("%s ..." % filepath)
            #url = urljoin(d['baseurl'], file)    # wrong!
            url = "%s%s" % (d['baseurl'], file)
            uri = urlparse(url)
            #content = self.fetch(url)
            #content = B(content)
            if http_conn is None:
                http_conn = HttpConn(uri)
            content = http_conn.get(uri)
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
        if http_conn is not None:
            http_conn.close()

    def http_get(self, url):
        resp = urlopen(url)
        resp_body = resp.read()
        resp.close()
        return resp_body

    def fetch(self, url, library=None):
        try:
            return self.http_get(url)
        except HTTPError as exc:
            if not (exc.code == 404 and library):
                raise CommandError("GET %s: %s" % (url, exc))
            elif not library.endswith('js'):
                raise CommandError("%s: library not found." % library)
            else:
                maybe = (re.sub(r'\.js$', 'js', library) if library.endswith('.js') else
                         re.sub(r'js$', '.js', library))
                raise CommandError("%s: library not found (maybe '%s'?)" % (library, maybe))

    def validate(self, library, version):
        if library:
            if not re.match(r'^[-.\w]+$', library):
                raise ValueError("%r: unexpected library name.")
        if version:
            if not re.match(r'^\d+(\.\d+)+([-.\w]+)?$', version):
                raise ValueError("%r: unexpected version number." % version)

    def latest_version(self, library):
        d = self.find(library)
        return None if d is None else d['versions'][0]

    @staticmethod
    def pattern2rexp(pattern):
        rexp_str = '.*'.join( re.escape(x) for x in pattern.split('*') )
        return re.compile(r'^%s$' % rexp_str, re.I)


class CDNJS(Base):
    CODE = "cdnjs"
    SITE_URL = "https://cdnjs.com/"
    API_URL  = "https://api.cdnjs.com/libraries"
    CDN_URL  = "https://cdnjs.cloudflare.com/ajax/libs"

    def fetch(self, url, library=None):
        json_str = Base.fetch(self, url, library)
        if json_str == "{}" and library:
            if library.endswith('js'):
                maybe = (re.sub(r'\.js$', 'js', library) if library.endswith('.js') else
                         re.sub(r'js$', '.js', library))
                raise CommandError("%s: library not found (maybe '%s'?)." % (library, maybe))
            else:
                raise CommandError("%s: library not found." % (library,))
        return json_str

    def list(self):
        jstr = self.fetch("%s?fields=name,description" % self.API_URL)
        jdata = json.loads(S(jstr))
        _debug_print(jdata)
        libs = [ dict(name=d['name'], desc=d['description']) for d in jdata['results'] ]
        return list(uniq(sorted(libs, key=lambda d: d['name'])))

    def find(self, library):
        self.validate(library, None)
        jstr = self.fetch("%s/%s" % (self.API_URL, library), library)
        jdata = json.loads(S(jstr))
        _debug_print(jdata)
        sep = re.compile(r'[-.]')
        versions = sort_versions([ d['version'] for d in jdata['assets'] ], reverse=True)
        return {
            'name': library,
            'desc': jdata.get('description'),
            'tags': ", ".join(jdata.get('keywords') or []),
            'site': jdata.get('homepage'),
            'info': "%s/libraries/%s" % (self.SITE_URL, library),
            'license': jdata.get('license'),
            'versions': versions,
        }

    def get(self, library, version):
        self.validate(library, version)
        jstr = self.fetch("%s/%s" % (self.API_URL, library), library)
        jdata = json.loads(S(jstr))
        _debug_print(jdata)
        if jdata == {}:
            return None
        d = find_one(jdata['assets'], lambda d: d['version'] == version)
        if d is None:
            return None
        baseurl = "%s/%s/%s" % (self.CDN_URL, library, version)
        return {
            'name'   :  library,
            'version':  version,
            'desc'   :  jdata.get('description'),
            'tags'   :  ", ".join(jdata.get('keywords', [])),
            'site'   :  jdata.get('homepage'),
            'info'   :  "%s/libraries/%s/%s" % (self.SITE_URL, library, version),
            'urls'   :  [ "%s/%s" % (baseurl, x) for x in d['files'] ],
            'files'  :  [ "/"+x for x in d['files'] ],
            'baseurl':  baseurl,
            'license': jdata.get('license'),
        }


class JSDelivr(Base):
    CODE     = "jsdelivr"
    SITE_URL = "https://www.jsdelivr.com/"
    #API_URL  = "https://api.jsdelivr.com/v1/jsdelivr/libraries"
    API_URL  = "https://data.jsdelivr.com/v1"
    CDN_URL  = "https://cdn.jsdelivr.net/npm"
    HEADERS  = {
        "x-algo""lia-app""lication-id": "OFCNC""OG2CU",
        "x-algo""lia-api""-key": "f54e21fa3a2""a0160595bb05""8179bfb1e",
    }

    def list(self):
        return None    # None means that this CDN can't list libraries without pattern

    def search(self, pattern):
        form_data = {
            "query":      pattern,
            "page":       "0",
            "hitsPerPage": "1000",
            "attributesToHighlight": '[]',
            "attributesToRetrieve": '["name","description","version"]',
        }
        payload = json.dumps({"params": urlencode(form_data)}, separators=(',', ':'))
        url = "https://ofcncog2cu-3.algolianet.com/1/indexes/npm-search/query"
        resp = urlopen(Request(url, payload, self.HEADERS))
        jstr = resp.read()
        jdata = json.loads(jstr)
        _debug_print(jdata)
        rexp = self.pattern2rexp(pattern)
        return [ {"name": d["name"], "desc": d["description"], "version": d["version"]}
                     for d in jdata["hits"] if rexp.match(d["name"]) ]

    def find(self, library):
        self.validate(library, None)
        url = "https://ofcncog2cu-dsn.algolia.net/1/indexes/npm-search/%s" % (library,)
        try:
            resp = urlopen(Request(url, None, self.HEADERS))
            jstr = resp.read()
        except HTTPError as exc:
            if exc.code == 404:
                raise CommandError("%s: library not found." % (library,))
            else:
                raise CommandError("GET %s: %s" % (url, exc))
        dict1 = json.loads(jstr)
        _debug_print(dict1)
        versions = sort_versions(list(dict1['versions'].keys()), reverse=True)
        #
        url = "%s/package/npm/%s" % (self.API_URL, library)
        jstr = self.fetch("%s/package/npm/%s" % (self.API_URL, library), library)
        dict2 = json.loads(jstr)
        _debug_print(dict2)
        #
        d = dict1
        return {
            "name":     d['name'],
            "desc":     d.get('description'),
            "versions": versions,
            "tags":     ", ".join(d.get('keywords', [])),
            "site":     d.get('homepage'),
            "info":     urljoin(self.SITE_URL, "/package/npm/%s" % library),
            "license":  d.get('license'),
        }

    def get(self, library, version):
        self.validate(library, version)
        url = "%s/package/npm/%s@%s/flat" % (self.API_URL, library, version)
        try:
            jstr = self.fetch(url, library)
        except CommandError:
            raise CommandError("%s@%s: library or version not found." % (library, version))
        jdata = json.loads(jstr)
        files = [ d["name"] for d in jdata.get('files', []) ]
        baseurl = "%s/%s@%s" % (self.CDN_URL, library, version)
        _debug_print(jdata)
        #
        dct = self.find(library)
        del dct["versions"]
        dct.update({
            "version": version,
            "info":    urljoin(self.SITE_URL, "/package/npm/%s?version=%s" % (library, version)),
            "npmpkg":  "https://registry.npmjs.org/%s/-/%s-%s.tgz" % (library, library, version),
            "urls":    [ baseurl + x for x in files ],
            "files":   files,
            "baseurl": baseurl,
            "default": jdata["default"],
            "destdir": "%s@%s" % (library, version),
        })
        return dct


class Unpkg(Base):
    CODE = "unpkg"
    SITE_URL = "https://unpkg.com/"
    #API_URL  = "https://www.npmjs.com"
    API_URL  = "https://api.npms.io/v2"

    def http_get(self, url):
        #req = Request(url, None, {"x-spiferack": "1"})
        #resp = urlopen(req)
        #resp_body = resp.read()
        #resp.close()
        uri = urlparse(url)
        with HttpConn(uri) as http_conn:
            resp_body = http_conn.get(uri, None, {"x-spiferack": "1"})
        return resp_body

    def list(self):
        return None    # None means that this CDN can't list libraries without pattern

    def search(self, pattern):
        url = "%s/search?q=%s&size=250" % (self.API_URL, pattern)
        jstr = self.fetch(url)
        jdata = json.loads(jstr)
        _debug_print(jdata)
        rexp = self.pattern2rexp(pattern)
        #arr = jdata["objects"]   # www.npmjs.com
        arr = jdata["results"]    # api.npms.io
        arr = [ d["package"] for d in arr if rexp.search(d["package"]["name"]) ]
        return [ {"name": d["name"], "desc": d.get("description"), "version": d["version"]}
                     for d in arr ]

    def find(self, library):
        self.validate(library, None)
        url  = "%s/package/%s" % (self.API_URL, library)
        jstr = self.fetch(url, library)  # 403 Forbidden. Why?
        jdata = json.loads(jstr)
        _debug_print(jdata)
        dct = jdata["collected"]["metadata"]
        versions = [dct["version"]]
        #
        url  = self.SITE_URL + "browse/%s/" % library
        html = self.fetch(url, library)
        html = S(html)
        _debug_print(html)
        rexp = re.compile(r'<script>window.__DATA__\s*=\s*(.*?)<\/script>', re.M)
        m = rexp.search(html)
        if m:
            jdata2 = json.loads(m.group(1))
            versions = jdata2["availableVersions"]
            versions.reverse()
        #
        site = None
        if dct.get("links"):
            if dct["links"].get("homepage"):
                site = dct["links"].get("homepage")
            else:
                site = dct["links"].get("npm")
        return {
            "name":      dct.get("name"),
            "desc":      dct.get("description"),
            "tags":      ", ".join(dct.get("keywords", [])),
            "site":      site,
            "info":      self.SITE_URL + "browse/%s/" % library,
            "versions":  versions,
            "license":   dct.get("license"),
        }

    def get(self, library, version):
        self.validate(library, version)
        dct = self.find(library)
        del dct["versions"]
        #
        url = "https://data.jsdelivr.com/v1/package/npm/%s@%s/flat" % (library, version)
        try:
            jstr = self.fetch(url, library)
        except CommandError:
            raise CommandError("%s@%s: library or version not found." % (library, version))
        jdata   = json.loads(jstr)
        files   = [ d["name"] for d in jdata["files"] ]
        baseurl = self.SITE_URL + "%s@%s" % (library, version)
        _debug_print(jdata)
        #
        dct.update({
            "name":     library,
            "version":  version,
            "info":     self.SITE_URL + "browse/%s@%s/" % (library, version),
            "npmpkg":   "https://registry.npmjs.org/%s/-/%s-%s.tgz" % (library, library, version),
            "urls":     [ "%s%s" % (baseurl, x) for x in files ],
            "files":    files,
            "baseurl":  baseurl,
            "default":  jdata.get("default"),
            "destdir":  "%s@%s" % (library, version),
            "skipfile": re.compile(r'\.DS_Store$'),  # downloading '.DS_Store' from UNPKG results in 403
        })
        return dct

    def latest_version(self, library):
        url = self.SITE_URL + "browse/%s/" % library
        uri = urlparse(url)
        with HttpConn(uri) as http_conn:
            resp = http_conn.request('HEAD', uri.path)
            if resp.status >= 400:
                raise CommandError("%s: library not found." % library)
            assert resp.status == 302    # 302 Found
            location = resp.getheader('location')
        assert location
        assert location.startswith('/'), "** location=%s" % location
        tupl = location.split("/browse/%s@" % library)
        assert len(tupl) == 2, "** location=%s" % location
        version = tupl[1]
        return version.rstrip('/')


class GoogleCDN(Base):
    CODE     = "google"
    SITE_URL = "https://developers.google.com/speed/libraries/"
    API_URL  = None
    CDN_URL  = "https://ajax.googleapis.com/ajax/libs"

    def list(self):
        html = S(self.fetch(self.SITE_URL))
        _debug_print(html)
        rexp = self.CDN_URL.replace('.', r'\.') + '/([^/]+)/([^/]+)/([^"]+)'
        libs = []
        for m in re.finditer(rexp, html):
            lib, ver, file = m.groups()
            libs.append({"name": lib, "desc": "latest version: %s" % ver})
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
            'info'    : "%s#%s" % (self.SITE_URL, library),
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
        baseurl = "%s/%s/%s" % (self.CDN_URL, library, version)
        files = [ s[len(baseurl):] for s in urls ] or None
        return {
            'name'   :  d['name'],
            'site'   :  d['site'],
            'info'    : "%s#%s" % (self.SITE_URL, library),
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

    def help_message(self):
        return r'''
{script}  -- download files from public CDN (cdnjs/jsdelivr/unpkg/google)

Usage: {script} [<options>] [<CDN> [<library> [<version> [<directory>]]]]

Options:
    -h, --help        : help
    -v, --version     : version
    -q, --quiet       : minimal output
        --debug       : (debug mode)

Example:
    $ {script}                                # list public CDN names
    $ {script} [-q] cdnjs                     # list libraries
    $ {script} [-q] cdnjs 'jquery*'           # search libraries
    $ {script} [-q] cdnjs jquery              # list versions
    $ {script} [-q] cdnjs jquery latest       # show latest version
    $ {script} [-q] cdnjs jquery 2.2.4        # list files
    $ mkdir -p static/lib                     # create a directory
    $ {script} [-q] cdnjs jquery 2.2.4 /static/lib  # download files
    static/lib/jquery/2.2.4/jquery.js ... Done (257,551 byte)
    static/lib/jquery/2.2.4/jquery.min.js ... Done (85,578 byte)
    static/lib/jquery/2.2.4/jquery.min.map ... Done (129,572 byte)
    $ ls static/lib/jquery/2.2.4
    jquery.js       jquery.min.js   jquery.min.map

'''[1:].format(script=self.script)

    @classmethod
    def main(cls, argv=None):
        if argv is None:
            argv = sys.argv[1:]
        try:
            output = cls().run(*argv)
        except CommandError as exc:
            stderr.write(B(str(exc)))
            stderr.write(b"\n")
            sys.exit(1)
        else:
            if output:
                stdout.write(B(output))
            sys.exit(0)

    def run(self, *args):
        args = list(args)
        cmdopts = self.parse_cmdopts(args, "hvq", ["help", "version", "quiet", "debug"])
        opt = cmdopts.get
        if opt('h') or opt('help'):
            return self.help_message()
        if opt('v') or opt('version'):
            return "%s\n" % RELEASE
        self.quiet = bool(opt('q') or opt('quiet'))
        global _debug_mode
        if opt('debug'):
            _debug_mode = True
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
            if not re.match(r'^[-.\w]+$', version):
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
        lst = cdn.list()
        if lst is None:
            raise CommandError("%s: cannot list libraries; please specify pattern such as 'jquery*'." % cdn_code)
        return self.render_list(lst)

    def do_search_libraries(self, cdn_code, pattern):
        cdn = self.find_cdn(cdn_code)
        return self.render_list(cdn.search(pattern))

    def do_find_library(self, cdn_code, library):
        cdn = self.find_cdn(cdn_code)
        d = cdn.find(library)
        if d is None:
            raise CommandError("%s: library not found." % library)
        buf = []; add = buf.append
        if self.quiet:
            if d.get('versions'):
                for ver in d['versions']:
                    add("%s\n" % ver)
        else:
            keys = "name desc tags site info license"
            for key in keys.split():
                if d.get(key):
                    add("%-9s %s\n" % (key+":", d[key]))
            if d.get('snippet'):
                add("snippet: |\n")
                add(re.sub(r'^', "    ", d['snippet']))
            if d.get('versions'):
                add("versions:\n")
                buf.extend( "  - %s\n" % ver for ver in d['versions'] )
        return "".join(buf)

    def do_get_library(self, cdn_code, library, version):
        cdn = self.find_cdn(cdn_code)
        if version == 'latest':
            version = cdn.latest_version(library)
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
            keys = "name version desc tags site info npmpkg default license"
            for key in keys.split():
                if d.get(key):
                    add("%-9s %s\n" % (key+":", d[key]))
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
        if version == 'latest':
            version = cdn.latest_version(library)
        cdn.download(library, version, basedir, quiet=self.quiet)
        return None


def main(argv=None):
    MainApp.main(argv)


if __name__ == '__main__':
    main()
