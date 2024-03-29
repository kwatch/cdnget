#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# frozen_string_literal: true

##
## Download JS/CSS files from public CDN.
##
## * CDNJS    (https://cdnjs.com/)
## * jsDelivr (https://www.jsdelivr.com/)
## * UNPKG    (https://unpkg.com/)
## * Google   (https://developers.google.com/speed/libraries/)
##
## Example:
##  $ cdnget                                # list public CDN
##  $ cdnget [-q] cdnjs                     # list libraries (except jsdelivr/unpkg)
##  $ cdnget [-q] cdnjs '*jquery*'          # search libraries
##  $ cdnget [-q] cdnjs jquery              # list versions
##  $ cdnget [-q] cdnjs jquery latest       # detect latest version
##  $ cdnget [-q] cdnjs jquery 3.6.0        # list files
##  $ mkdir -p static/lib                   # create a directory
##  $ cdnget [-q] cdnjs jquery 3.6.0 static/lib  # download files
##

require 'open-uri'
require 'uri'
require 'net/http'
require 'openssl'
require 'json'
require 'fileutils'
require 'pp'


module CDNGet


  RELEASE = '$Release: 1.1.0 $'.split()[1]


  class HttpConnection

    def initialize(uri, headers=nil)
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      http.start()
      @http = http
      @headers = headers
    end

    def self.open(uri, headers=nil)
      http = self.new(uri, headers)
      return http unless block_given?()
      begin
        return yield http
      ensure
        http.close()
      end
    end

    def get(uri)
      resp = request('GET', uri.path, uri.query)
      return _get_resp_body(resp)
    end

    def post(uri, payload)
      resp = request('POST', uri.path, uri.query, payload: payload)
      return _get_resp_body(resp)
    end

    def request(meth, path, query=nil, payload: nil, headers: nil)
      path += "?" + query if query
      if @headers
        headers ||= {}
        headers.update(@headers)
      end
      resp = @http.send_request(meth, path, payload, headers)
      return resp
    end

    def _get_resp_body(resp)
      case resp
      when Net::HTTPSuccess
        return resp.body
      else
        raise HttpError.new(resp.code.to_i, resp.message)
      end
    end

    def close()
      @http.finish()
    end

  end


  class HttpError < StandardError
    def initialize(code, msgtext)
      super("#{code} #{msgtext}")
      @code = code
      @msgtext = msgtext
    end
    attr_reader :code, :msgtext
  end


  CLASSES = []


  class Base

    def self.inherited(klass)
      CLASSES << klass
    end

    def initialize(debug_mode: false)
      @debug_mode = debug_mode
    end
    attr_reader :debug_mode

    def list()
      raise NotImplementedError.new("#{self.class.name}#list(): not implemented yet.")
    end

    def search(pattern)
      return list().select {|d| File.fnmatch(pattern, d[:name], File::FNM_CASEFOLD) }
      #rexp_str = pattern.split('*', -1).collect {|x| Regexp.escape(x) }.join('.*')
      #rexp = Regexp.compile("\\A#{rexp_str}\\z", Regexp::IGNORECASE)
      #return list().select {|d| d[:name] =~ rexp }
    end

    def find(library)
      raise NotImplementedError.new("#{self.class.name}#find(): not implemented yet.")
    end

    def get(library, version)
      raise NotImplementedError.new("#{self.class.name}#get(): not implemented yet.")
    end

    def download(library, version, basedir=".", quiet: false)
      validate(library, version)
      File.exist?(basedir)  or
        raise CommandError.new("#{basedir}: not exist.")
      File.directory?(basedir)  or
        raise CommandError.new("#{basedir}: not a directory.")
      d = get(library, version)
      target_dir = d[:destdir] ? File.join(basedir, d[:destdir]) \
                               : File.join(basedir, library, version)
      http = nil
      skipfile = d[:skipfile]   # ex: /\.DS_Store\z/
      d[:files].each do |file|
        filepath = File.join(target_dir, file)
        #
        if skipfile && file =~ skipfile
          puts "#{filepath} ... Skipped"   # for example, skip '.DS_Store' files
          next
        end
        #
        if filepath.end_with?('/')
          if File.exist?(filepath)
            puts "#{filepath} ... Done (Already exists)" unless quiet
          else
            print "#{filepath} ..." unless quiet
            FileUtils.mkdir_p(filepath)
            puts " Done (Created)" unless quiet
          end
          next
        end
        #
        dirpath  = File.dirname(filepath)
        print "#{filepath} ..." unless quiet
        url = File.join(d[:baseurl], file)   # not use URI.join!
        uri = URI.parse(url)
        http ||= HttpConnection.new(uri)
        content = http.get(uri)
        content = content.force_encoding('ascii-8bit')
        print " Done (#{format_integer(content.bytesize)} byte)" unless quiet
        FileUtils.mkdir_p(dirpath) unless File.exist?(dirpath)
        unchanged = File.exist?(filepath) && File.read(filepath, mode: 'rb') == content
        if unchanged
          print " (Unchanged)" unless quiet
        else
          File.open(filepath, 'wb') {|f| f.write(content) }
        end
        puts() unless quiet
      end
      http.close() if http
      nil
    end

    def latest_version(library)
      validate(library, nil)
      d = self.find(library)
      return d[:versions].first
    end

    protected

    def http_get(url)
      ## * `open()` on Ruby 3.X can't open http url
      ## * `URI.open()` on Ruby <= 2.4 raises NoMethodError (private method `open' called)
      ## * `URI.__send__(:open)` is a hack to work on both Ruby 2.X and 3.X
      return URI.__send__(:open, url, 'rb') {|f| f.read() }
    end

    def fetch(url, library=nil)
      begin
        html = http_get(url)
        return html
      rescue OpenURI::HTTPError => exc
        if ! (exc.message == "404 Not Found" && library)
          raise CommandError.new("GET #{url} : #{exc.message}")
        elsif ! library.end_with?('js')
          raise CommandError.new("#{library}: Library not found.")
        else
          maybe = library.end_with?('.js') ? library.sub('.js', 'js') : library.sub(/js$/, '.js')
          raise CommandError.new("#{library}: Library not found (maybe '#{maybe}'?).")
        end
      end
    end

    LIBRARY_REXP = /\A[-.\w]+\z/
    VERSION_REXP = /\A\d+(\.\d+)+([-.\w]+)?/

    def validate(library, version)
      if library
        rexp = self.class.const_get(:LIBRARY_REXP)
        library =~ self.class.const_get(:LIBRARY_REXP)  or
          raise CommandError.new("#{library}: Invalid library name.")
      end
      if version
        version =~ self.class.const_get(:VERSION_REXP)  or
          raise CommandError.new("#{version}: Invalid version number.")
      end
    end

    def npmpkg_url(library, version)
      pkg  = library.sub(/^@[-\w]+/, '')
      path = "/#{library.gsub('/', '%2f')}/-/#{pkg}-#{version}.tgz"
      return "https://registry.npmjs.org#{path}"
    end

    def format_integer(value)
      return value.to_s.reverse.scan(/..?.?/).collect {|s| s.reverse }.reverse.join(',')
    end

    def _debug_print(x)
      if @debug_mode
        $stderr.puts "\e[0;35m*** #{PP.pp(x,String.new)}\e[0m"
      end
    end

  end


  class CDNJS < Base
    CODE = "cdnjs"
    SITE_URL = "https://cdnjs.com/"
    API_URL  = "https://api.cdnjs.com/libraries"
    CDN_URL  = "https://cdnjs.cloudflare.com/ajax/libs"

    def fetch(url, library=nil)
      json_str = super
      if json_str == "{}" && library
        if library.end_with?('js')
          maybe = library.end_with?('.js') \
                ? library.sub('.js', 'js') \
                : library.sub(/js$/, '.js')
          raise CommandError.new("#{library}: Library not found (maybe '#{maybe}'?).")
        else
          raise CommandError.new("#{library}: Library not found.")
        end
      end
      return json_str
    end
    protected :fetch

    def list()
      jstr = fetch("#{API_URL}?fields=name,description")
      jdata = JSON.parse(jstr)
      _debug_print(jdata)
      libs = jdata['results'].collect {|d| {name: d['name'], desc: d['description']} }
      return libs.sort_by {|d| d[:name] }.uniq
    end

    def find(library)
      validate(library, nil)
      jstr = fetch("#{API_URL}/#{library}", library)
      jdata = JSON.parse(jstr)
      _debug_print(jdata)
      versions = jdata['assets'].collect {|d| d['version'] }\
                   .sort_by {|v| v.split(/[-.]/).map(&:to_i) }
      return {
        name: library,
        desc: jdata['description'],
        tags: (jdata['keywords'] || []).join(", "),
        site: jdata['homepage'],
        info: File.join(SITE_URL, "/libraries/#{library}"),
        license: jdata['license'],
        versions: versions.reverse(),
      }
    end

    def get(library, version)
      validate(library, version)
      jstr = fetch("#{API_URL}/#{library}", library)
      jdata = JSON.parse(jstr)
      _debug_print(jdata)
      d = jdata['assets'].find {|d| d['version'] == version }  or
        raise CommandError.new("#{library}/#{version}: Library or version not found.")
      baseurl = "#{CDN_URL}/#{library}/#{version}/"
      return {
        name:     library,
        version:  version,
        desc:     jdata['description'],
        tags:     (jdata['keywords'] || []).join(", "),
        site:     jdata['homepage'],
        info:     File.join(SITE_URL, "/libraries/#{library}/#{version}"),
        urls:     d['files'].collect {|s| baseurl + s },
        files:    d['files'],
        baseurl:  baseurl,
        license:  jdata['license'],
      }
    end

  end


  class JSDelivr < Base
    CODE = "jsdelivr"
    SITE_URL = "https://www.jsdelivr.com/"
    #API_URL  = "https://api.jsdelivr.com/v1/jsdelivr/libraries"
    API_URL  = "https://data.jsdelivr.com/v1"
    CDN_URL  = "https://cdn.jsdelivr.net/npm"
    HEADERS = {
      "x-algo""lia-app""lication-id"=>"OFCNC""OG2CU",
      "x-algo""lia-api""-key"=>"f54e21fa3a2""a0160595bb05""8179bfb1e",
    }
    LIBRARY_REXP = /\A([-.\w]+|\@[-\w]+\/[-.\w]+)\z/

    def list()
      return nil    # nil means that this CDN can't list libraries without pattern
    end

    def search(pattern)
      form_data = {
        query:        pattern,
        page:         "0",
        hitsPerPage:  "1000",
        attributesToHighlight: '[]',
        attributesToRetrieve:  '["name","description","version"]'
      }
      payload = JSON.dump({"params"=>URI.encode_www_form(form_data)})
      url = "https://ofcncog2cu-3.algolianet.com/1/indexes/npm-search/query"
      uri = URI.parse(url)
      json = HttpConnection.open(uri, HEADERS) {|http| http.post(uri, payload) }
      jdata = JSON.load(json)
      _debug_print(jdata)
      return jdata["hits"].select {|d|
        File.fnmatch(pattern, d["name"], File::FNM_CASEFOLD)
      }.collect {|d|
        {name: d["name"], desc: d["description"], version: d["version"]}
      }
    end

    def find(library)
      validate(library, nil)
      url = "https://ofcncog2cu-dsn.algolia.net/1/indexes/npm-search/#{library.sub('/', '%2f')}"
      uri = URI.parse(url)
      begin
        json = HttpConnection.open(uri, HEADERS) {|http| http.get(uri) }
      rescue HttpError
        raise CommandError, "#{library}: Library not found."
      end
      dict1 = JSON.load(json)
      _debug_print(dict1)
      #
      json = fetch("#{API_URL}/package/npm/#{library}")
      dict2 = JSON.load(json)
      _debug_print(dict2)
      #
      d = dict1
      return {
        name:      d['name'],
        desc:      d['description'],
        #versions: d['versions'].collect {|k,v| k },
        versions:  dict2['versions'],
        tags:      (d['keywords'] || []).join(", "),
        site:      d['homepage'],
        info:      File.join(SITE_URL, "/package/npm/#{library}"),
        license:   d['license'],
      }
    end

    def get(library, version)
      validate(library, version)
      url = File.join(API_URL, "/package/npm/#{library}@#{version}/flat")
      begin
        json = fetch(url, library)
      rescue CommandError
        raise CommandError.new("#{library}@#{version}: Library or version not found.")
      end
      jdata   = JSON.load(json)
      files   = jdata["files"].collect {|d| d["name"] }
      baseurl = "#{CDN_URL}/#{library}@#{version}"
      _debug_print(jdata)
      #
      dict = find(library)
      dict.delete(:versions)
      dict.update({
        version: version,
        info:    File.join(SITE_URL, "/package/npm/#{library}?version=#{version}"),
        npmpkg:  npmpkg_url(library, version),
        urls:    files.collect {|x| baseurl + x },
        files:   files,
        baseurl: baseurl,
        default: jdata["default"],
        destdir: "#{library}@#{version}",
      })
      return dict
    end

    def latest_version(library)
      validate(library, nil)
      json = fetch("#{API_URL}/package/npm/#{library}")
      jdict = JSON.load(json)
      return jdict["tags"]["latest"]
    end

  end


  class Unpkg < Base
    CODE = "unpkg"
    SITE_URL = "https://unpkg.com/"
    #API_URL  = "https://www.npmjs.com"
    API_URL  = "https://api.npms.io/v2"
    LIBRARY_REXP = /\A([-.\w]+|\@[-\w]+\/[-.\w]+)\z/

    protected

    def http_get(url)
      return URI.__send__(:open, url, 'rb', {"x-spiferack"=>"1"}) {|f| f.read() }
    end

    public

    def list()
      return nil    # nil means that this CDN can't list libraries without pattern
    end

    def search(pattern)
      #json = fetch("#{API_URL}/search?q=#{pattern}")
      json = fetch("#{API_URL}/search?q=#{pattern}&size=250")
      jdata = JSON.load(json)
      _debug_print(jdata)
      #arr = jdata["objects"]   # www.npmjs.com
      arr = jdata["results"]    # api.npms.io
      return arr.select {|dict|
        File.fnmatch(pattern, dict["package"]["name"], File::FNM_CASEFOLD)
      }.collect {|dict|
        d = dict["package"]
        {name: d["name"], desc: d["description"], version: d["version"]}
      }
    end

    def find(library)
      validate(library, nil)
      json = fetch("#{API_URL}/package/#{library.sub('/', '%2f')}", library)
      jdata = JSON.load(json)
      _debug_print(jdata)
      dict = jdata["collected"]["metadata"]
      versions = [dict["version"]]
      #
      url = File.join(SITE_URL, "/browse/#{library}/")
      html = fetch(url, library)
      _debug_print(html)
      if html =~ /<script>window.__DATA__\s*=\s*(.*?)<\/script>/m
        jdata2 = JSON.load($1)
        versions = jdata2["availableVersions"].reverse()
      end
      #
      return {
        name:      dict["name"],
        desc:      dict["description"],
        tags:      (dict["keywords"] || []).join(", "),
        site:      dict["links"] ? dict["links"]["homepage"] : dict["links"]["npm"],
        info:      File.join(SITE_URL, "/browse/#{library}/"),
        versions:  versions,
        license:   dict["license"],
      }
    end

    def get(library, version)
      validate(library, version)
      dict = find(library)
      dict.delete(:versions)
      #
      url = "#{SITE_URL}#{library}@#{version}/?meta"
      begin
        json = fetch(url, library)
      rescue CommandError
        raise CommandError.new("#{library}@#{version}: Version not found.")
      end
      jdata = JSON.load(json)
      _debug_print(jdata)
      pr = proc do |jdata, files|
        jdata['files'].each do |d|
          d['type'] == "directory" ? pr.call(d, files) \
                                   : (files << d['path'])
        end if jdata['files']
        files
      end
      files = pr.call(jdata, [])
      #files = files.sort_by {|s| s.downcase }
      baseurl = File.join(SITE_URL, "/#{library}@#{version}")
      #
      dict.update({
        name:     library,
        version:  version,
        info:     File.join(SITE_URL, "/browse/#{library}@#{version}/"),
        npmpkg:   npmpkg_url(library, version),
        urls:     files.collect {|x| baseurl+x },
        files:    files,
        baseurl:  baseurl,
        #default:  jdata["default"],
        destdir:  "#{library}@#{version}",
        skipfile: /\.DS_Store\z/,  # downloading '.DS_Store' from UNPKG results in 403
      })
      return dict
    end

    def latest_version(library)
      validate(library, nil)
      version = nil
      url = File.join(SITE_URL, "/browse/#{library}/")
      uri = URI.parse(url)
      HttpConnection.open(URI.parse(SITE_URL)) do |http|
        resp = http.request('HEAD', "/browse/#{library}/")
        if resp.code == "302"    # 302 Found
          location = resp.header['Location']
          location =~ /@([^@\/]+)\/\z/
          version = $1
        end
      end
      version ||= super(library)
      return version
    end

  end


  class GoogleCDN < Base
    CODE = "google"
    SITE_URL = "https://developers.google.com/speed/libraries/"
    CDN_URL  = "https://ajax\.googleapis\.com/ajax/libs"

    def list()
      html = fetch(SITE_URL)
      _debug_print(html)
      rexp = %r`"#{Regexp.escape(CDN_URL)}/([^/]+)/([^/]+)/([^"]+)"`
      libs = []
      html.scan(rexp) do |lib, ver, file|
        libs << {name: lib, desc: "latest version: #{ver}" }
      end
      return libs.sort_by {|d| d[:name] }.uniq
    end

    def find(library)
      validate(library, nil)
      html = fetch(SITE_URL)
      _debug_print(html)
      rexp = %r`"#{Regexp.escape(CDN_URL)}/#{library}/`
      site_url = nil
      versions = []
      urls = []
      found = false
      html.scan(/<h3\b.*?>.*?<\/h3>\s*<dl>(.*?)<\/dl>/m) do |text,|
        if text =~ rexp
          found = true
          if text =~ /<dt>.*?snippet:<\/dt>\s*<dd>(.*?)<\/dd>/m
            s = $1
            s.scan(/\b(?:src|href)="([^"]*?)"/) {|href,| urls << href }
          end
          if text =~ /<dt>site:<\/dt>\s*<dd>(.*?)<\/dd>/m
            s = $1
            if s =~ %r`href="([^"]+)"`
              site_url = $1
            end
          end
          text.scan(/<dt>(?:stable |unstable )?versions:<\/dt>\s*<dd\b.*?>(.*?)<\/dd>/m) do
            s = $1
            vers = s.split(/,/).collect {|x| x.strip() }
            versions.concat(vers)
          end
          break
        end
      end
      found  or
        raise CommandError.new("#{library}: Library not found.")
      return {
        name: library,
        site: site_url,
        info: "#{SITE_URL}\##{library}",
        urls: urls,
        versions: versions,
      }
    end

    def get(library, version)
      validate(library, version)
      d = find(library)
      d[:versions].find {|s| s == version }  or
        raise CommandError.new("#{library} #{version}: Version not found.")
      urls = d[:urls]
      if urls
        rexp = /(\/libs\/#{library})\/[^\/]+/
        urls = urls.collect {|x| x.gsub(rexp, "\\1/#{version}") }
      end
      baseurl = "#{CDN_URL}/#{library}/#{version}"
      files = urls ? urls.collect {|x| x[baseurl.length..-1] } : nil
      return {
        name:    d[:name],
        site:    d[:site],
        info:    "#{SITE_URL}\##{library}",
        urls:    urls,
        files:   files,
        baseurl: baseurl,
        version: version,
      }
    end

  end


  #class JQueryCDN < Base
  #  CODE = "jquery"
  #  SITE_URL = 'https://code.jquery.com/'
  #end


  #class ASPNetCDN < Base
  #  CODE = "aspnet"
  #  SITE_URL = 'https://www.asp.net/ajax/cdn/'
  #end


  class CommandError < StandardError
  end


  class Main

    def initialize(script=nil)
      @script = script || File.basename($0)
    end

    def help_message()
      script = @script
      return <<END
#{script}  -- download files from public CDN (cdnjs/jsdelivr/unpkg/google)

Usage: #{script} [<options>] [<CDN> [<library> [<version> [<directory>]]]]

Options:
  -h, --help        : help
  -v, --version     : version
  -q, --quiet       : minimal output
      --debug       : (debug mode)

Example:
  $ #{script}                              # list public CDN names
  $ #{script} [-q] cdnjs                   # list libraries (except jsdelivr/unpkg)
  $ #{script} [-q] cdnjs 'jquery*'         # search libraries
  $ #{script} [-q] cdnjs jquery            # list versions
  $ #{script} [-q] cdnjs jquery latest     # show latest version
  $ #{script} [-q] cdnjs jquery 2.2.0      # list files
  $ mkdir -p static/lib                    # create a directory
  $ #{script} [-q] cdnjs jquery 2.2.0 static/lib  # download files
  static/lib/jquery/2.2.0/jquery.js ... Done (258,388 byte)
  static/lib/jquery/2.2.0/jquery.min.js ... Done (85,589 byte)
  static/lib/jquery/2.2.0/jquery.min.map ... Done (129,544 byte)
  $ ls static/lib/jquery/2.2.0
  jquery.js       jquery.min.js   jquery.min.map

END
    end

    def self.main(args=nil)
      args ||= ARGV
      s = self.new().run(*args)
      puts s if s
      exit 0
    rescue CommandError => ex
      $stderr.puts ex.message
      exit 1
    end

    def run(*args)
      cmdopts = parse_cmdopts(args, "hvq", ["help", "version", "quiet", "debug"])
      return help_message() if cmdopts['h'] || cmdopts['help']
      return RELEASE + "\n" if cmdopts['v'] || cmdopts['version']
      @quiet = cmdopts['quiet'] || cmdopts['q']
      @debug_mode = cmdopts['debug']
      case args.length
      when 0
        return do_list_cdns()
      when 1
        cdn_code = args[0]
        return do_list_libraries(cdn_code)
      when 2
        cdn_code, library = args
        return library.include?('*') \
               ? do_search_libraries(cdn_code, library) \
               : do_find_library(cdn_code, library)
      when 3
        cdn_code, library, version = args
        return do_get_library(cdn_code, library, version)
      when 4
        cdn_code, library, version, basedir = args
        do_download_library(cdn_code, library, version, basedir)
        return ""
      else
        raise CommandError.new("'#{args[4]}': Too many arguments.")
      end
    end

    def parse_cmdopts(cmdargs, short_opts, long_opts)
      cmdopts = {}
      while cmdargs[0] && cmdargs[0].start_with?('-')
        cmdarg = cmdargs.shift
        if cmdarg == '--'
          break
        elsif cmdarg.start_with?('--')
          cmdarg =~ /\A--(\w[-\w]+)(=.*?)?/  or
            raise CommandError.new("#{cmdarg}: invalid command option.")
          name  = $1
          value = $2 ? $2[1..-1] : true
          long_opts.include?(name)  or
            raise CommandError.new("#{cmdarg}: unknown command option.")
          cmdopts[name] = value
        elsif cmdarg.start_with?('-')
          cmdarg[1..-1].each_char do |c|
            short_opts.include?(c)  or
              raise CommandError.new("-#{c}: unknown command option.")
            cmdopts[c] = true
          end
        else
          raise "unreachable"
        end
      end
      return cmdopts
    end

    def find_cdn(cdn_code)
      klass = CLASSES.find {|c| c::CODE == cdn_code }  or
        raise CommandError.new("#{cdn_code}: no such CDN.")
      return klass.new(debug_mode: @debug_mode)
    end

    def render_list(list)
      return list.collect {|d| "#{d[:name]}\n" }.join() if @quiet
      return list.collect {|d| "%-20s  # %s\n" % [d[:name], d[:desc]] }.join()
    end

    def do_list_cdns()
      return CLASSES.map {|c| "#{c::CODE}\n" }.join() if @quiet
      return CLASSES.map {|c| "%-10s  # %s\n" % [c::CODE, c::SITE_URL] }.join()
    end

    def do_list_libraries(cdn_code)
      cdn = find_cdn(cdn_code)
      list = cdn.list()  or
        raise CommandError.new("#{cdn_code}: cannot list libraries; please specify pattern such as 'jquery*'.")
      return render_list(list)
    end

    def do_search_libraries(cdn_code, pattern)
      cdn = find_cdn(cdn_code)
      return render_list(cdn.search(pattern))
    end

    def do_find_library(cdn_code, library)
      cdn = find_cdn(cdn_code)
      d = cdn.find(library)
      buf = []
      if @quiet
        d[:versions].each do |ver|
          buf << "#{ver}\n"
        end unless empty?(d[:versions])
      else
        buf << "name:     #{d[:name]}\n"
        buf << "desc:     #{d[:desc]}\n"    unless empty?(d[:desc])
        buf << "tags:     #{d[:tags]}\n"    unless empty?(d[:tags])
        buf << "site:     #{d[:site]}\n"    unless empty?(d[:site])
        buf << "info:     #{d[:info]}\n"    unless empty?(d[:info])
        buf << "license:  #{d[:license]}\n" unless empty?(d[:license])
        buf << "snippet: |\n" << d[:snippet].gsub(/^/, '    ') unless empty?(d[:snippet])
        buf << "versions:\n"
        d[:versions].each do |ver|
          buf << "  - #{ver}\n"
        end unless empty?(d[:versions])
      end
      return buf.join()
    end

    def do_get_library(cdn_code, library, version)
      cdn = find_cdn(cdn_code)
      version = cdn.latest_version(library) if version == 'latest'
      d = cdn.get(library, version)
      buf = []
      if @quiet
        d[:urls].each do |url|
          buf << "#{url}\n"
        end if d[:urls]
      else
        buf << "name:     #{d[:name]}\n"
        buf << "version:  #{d[:version]}\n"
        buf << "desc:     #{d[:desc]}\n"    unless empty?(d[:desc])
        buf << "tags:     #{d[:tags]}\n"    unless empty?(d[:tags])
        buf << "site:     #{d[:site]}\n"    unless empty?(d[:site])
        buf << "info:     #{d[:info]}\n"    unless empty?(d[:info])
        buf << "npmpkg:   #{d[:npmpkg]}\n"  unless empty?(d[:npmpkg])
        buf << "default:  #{d[:default]}\n" unless empty?(d[:default])
        buf << "license:  #{d[:license]}\n" unless empty?(d[:license])
        buf << "snippet: |\n" << d[:snippet].gsub(/^/, '    ') unless empty?(d[:snippet])
        buf << "urls:\n" unless empty?(d[:urls])
        d[:urls].each do |url|
          buf << "  - #{url}\n"
        end unless empty?(d[:urls])
      end
      return buf.join()
    end

    def do_download_library(cdn_code, library, version, basedir)
      cdn = find_cdn(cdn_code)
      version = cdn.latest_version(library) if version == 'latest'
      cdn.download(library, version, basedir, quiet: @quiet)
      return nil
    end

    private

    def empty?(x)
      return x.nil? || x.empty?
    end

  end


end


if __FILE__ == $0
  CDNGet::Main.main()
end
