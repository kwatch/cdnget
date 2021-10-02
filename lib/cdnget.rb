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
##  $ cdnget                                # list public CDN
##  $ cdnget [-q] cdnjs                     # list libraries
##  $ cdnget [-q] cdnjs jquery              # list versions
##  $ cdnget [-q] cdnjs jquery 2.2.0        # list files
##  $ cdnget [-q] cdnjs jquery 2.2.0 /tmp   # download files
##

require 'open-uri'
require 'uri'
require 'net/http'
require 'openssl'
require 'json'
require 'fileutils'


module CDNGet


  RELEASE = '$Release: 0.0.0 $'.split()[1]


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
      resp = @http.send_request('GET', uri.path, nil, @headers)
      case resp
      when Net::HTTPSuccess
        return resp.body
      #when HTTPInformation, Net::HTTPRedirection, HTTPClientError, HTTPServerError
      else
        raise HttpError.new(resp.code.to_i, resp.message)
      end
    end

    def post(uri, payload)
      path = uri.path
      path += "?"+uri.query if uri.query && !uri.query.empty?
      resp = @http.send_request('POST', path, payload, @headers)
      case resp
      when Net::HTTPSuccess ; return resp.body
      else                  ; raise HttpError.new(resp.code.to_i, resp.message)
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

    def list()
      raise NotImplementedError.new("#{self.class.name}#list(): not implemented yet.")
    end

    def search(pattern)
      #return list().select {|a| File.fnmatch(pattern, a[:name], File::FNM_CASEFOLD) }
      rexp_str = pattern.split('*', -1).collect {|x| Regexp.escape(x) }.join('.*')
      rexp = Regexp.compile("\\A#{rexp_str}\\z", Regexp::IGNORECASE)
      return list().select {|a| a[:name] =~ rexp }
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
      d[:files].each do |file|
        filepath = File.join(target_dir, file)
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

    def validate(library, version)
      if library
        library =~ /\A[-.\w]+\z/  or
          raise ArgumentError.new("#{library.inspect}: Unexpected library name.")
      end
      if version
        version =~ /\A\d+(\.\d+)+([-.\w]+)?/  or
          raise ArgumentError.new("#{version.inspect}: Unexpected version number.")
      end
    end

    def format_integer(value)
      return value.to_s.reverse.scan(/..?.?/).collect {|s| s.reverse }.reverse.join(',')
    end

  end


  class CDNJS < Base
    CODE = "cdnjs"
    SITE_URL = 'https://cdnjs.com/'

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

    def list
      libs = []
      jstr = fetch("https://api.cdnjs.com/libraries?fields=name,description")
      jdata = JSON.parse(jstr)
      libs = jdata['results'].collect {|d| {name: d['name'], desc: d['description']} }
      return libs.sort_by {|d| d[:name] }.uniq
    end

    def find(library)
      validate(library, nil)
      jstr = fetch("https://api.cdnjs.com/libraries/#{library}", library)
      jdata = JSON.parse(jstr)
      versions = jdata['assets'].collect {|d| d['version'] }\
                   .sort_by {|v| v.split(/[-.]/).map(&:to_i) }
      return {
        name: library,
        desc: jdata['description'],
        tags: (jdata['keywords'] || []).join(", "),
        site: jdata['homepage'],
        license: jdata['license'],
        versions: versions.reverse(),
      }
    end

    def get(library, version)
      validate(library, version)
      jstr = fetch("https://api.cdnjs.com/libraries/#{library}", library)
      jdata = JSON.parse(jstr)
      d = jdata['assets'].find {|d| d['version'] == version }  or
        raise CommandError.new("#{library}/#{version}: Library or version not found.")
      baseurl = "https://cdnjs.cloudflare.com/ajax/libs/#{library}/#{version}/"
      return {
        name:     library,
        version:  version,
        desc:     jdata['description'],
        tags:     (jdata['keywords'] || []).join(", "),
        site:     jdata['homepage'],
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
    HEADERS = {
      "x-algo""lia-app""lication-id"=>"OFCNC""OG2CU",
      "x-algo""lia-api""-key"=>"f54e21fa3a2""a0160595bb05""8179bfb1e",
    }

    def list
      return nil
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
      return jdata["hits"].select {|d|
        File.fnmatch(pattern, d["name"], File::FNM_CASEFOLD)
      }.collect {|d|
        {name: d["name"], desc: d["description"], version: d["version"]}
      }
    end

    def find(library)
      validate(library, nil)
      url = "https://ofcncog2cu-dsn.algolia.net/1/indexes/npm-search/#{library}"
      uri = URI.parse(url)
      begin
        json = HttpConnection.open(uri, HEADERS) {|http| http.get(uri) }
      rescue HttpError
        raise CommandError, "#{library}: Library not found."
      end
      dict1 = JSON.load(json)
      #
      json = fetch("#{API_URL}/package/npm/#{library}")
      dict2 = JSON.load(json)
      #
      d = dict1
      return {
        name:      d['name'],
        desc:      d['description'],
        #versions: d['versions'].collect {|k,v| k },
        versions:  dict2['versions'],
        tags:      (d['keywords'] || []).join(", "),
        site:      d['homepage'],
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
      baseurl = "https://cdn.jsdelivr.net/npm/#{library}@#{version}"
      #
      dict = find(library)
      dict.delete(:versions)
      dict.update({
        version: version,
        urls:    files.collect {|x| baseurl + x },
        files:   files,
        baseurl: baseurl,
        default: jdata["default"],
        destdir: "#{library}@#{version}",
      })
      return dict
    end

  end


  class GoogleCDN < Base
    CODE = "google"
    SITE_URL = 'https://developers.google.com/speed/libraries/'

    def list
      libs = []
      html = fetch("https://developers.google.com/speed/libraries/")
      rexp = %r`"https://ajax\.googleapis\.com/ajax/libs/([^/]+)/([^/]+)/([^"]+)"`
      html.scan(rexp) do |lib, ver, file|
        libs << {name: lib, desc: "latest version: #{ver}" }
      end
      return libs.sort_by {|d| d[:name] }.uniq
    end

    def find(library)
      validate(library, nil)
      html = fetch("https://developers.google.com/speed/libraries/")
      rexp = %r`"https://ajax\.googleapis\.com/ajax/libs/#{library}/`
      site_url = nil
      versions = []
      urls = []
      found = false
      html.scan(/<h3\b.*?>.*?<\/h3>\s*<dl>(.*?)<\/dl>/m) do |text,|
        if text =~ rexp
          found = true
          if text =~ /<dt>.*?snippet:<\/dt>\s*<dd>(.*?)<\/dd>/m
            s = $1
            s.scan(/\b(?:src|href)="([^"]*?)"/) do |href,|
              urls << href
            end
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
        urls: urls,
        versions: versions,
      }
    end

    def get(library, version)
      validate(library, version)
      d = find(library)
      d[:versions].find(version)  or
        raise CommandError.new("#{version}: No such version of #{library}.")
      urls = d[:urls]
      if urls
        rexp = /(\/libs\/#{library})\/[^\/]+/
        urls = urls.collect {|x| x.gsub(rexp, "\\1/#{version}") }
      end
      baseurl = "https://ajax.googleapis.com/ajax/libs/#{library}/#{version}"
      files = urls ? urls.collect {|x| x[baseurl.length..-1] } : nil
      return {
        name:    d[:name],
        site:    d[:site],
        urls:    urls,
        files:   files,
        baseurl: baseurl,
        version: version,
      }
    end

  end


  class Unpkg < Base
    CODE = "unpkg"
    SITE_URL = "https://unpkg.com/"
    #API_URL  = "https://www.npmjs.com"
    API_URL  = "https://api.npms.io/v2"

    protected

    def http_get(url)
      return URI.__send__(:open, url, 'rb', {"x-spiferack"=>"1"}) {|f| f.read() }
    end

    public

    def list
      return nil
    end

    def search(pattern)
      #json = fetch("#{API_URL}/search?q=#{pattern}")
      json = fetch("#{API_URL}/search?q=#{pattern}&size=250")
      jdata = JSON.load(json)
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
      json = fetch("#{API_URL}/package/#{library}", library)
      jdata = JSON.load(json)
      dict = jdata["collected"]["metadata"]
      versions = [dict["version"]]
      #
      url = File.join(SITE_URL, "/browse/#{library}/")
      html = fetch(url, library)
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
        versions:  versions,
        license:   dict["license"],
      }
    end

    def get(library, version)
      validate(library, version)
      dict = find(library)
      dict.delete(:versions)
      #
      url = "https://data.jsdelivr.com/v1/package/npm/#{library}@#{version}/flat"
      begin
        json = fetch(url, library)
      rescue CommandError
        raise CommandError.new("#{library}@#{version}: Library or version not found.")
      end
      jdata   = JSON.load(json)
      files   = jdata["files"].collect {|d| d["name"] }
      baseurl = File.join(SITE_URL, "/#{library}@#{version}")
      #
      dict.update({
        name:     library,
        version:  version,
        urls:     files.collect {|x| baseurl+x },
        files:    files,
        baseurl:  baseurl,
        default:  jdata["default"],
        destdir:  "#{library}@#{version}",
      })
      return dict
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

    def help_message
      script = @script
      return <<END
#{script}  -- download files from public CDN (cdnjs/google/jsdelivr/unpkg)

Usage: #{script} [<options>] [<CDN> [<library> [<version> [<directory>]]]]

Options:
  -h, --help        : help
  -v, --version     : version
  -q, --quiet       : minimal output

Example:
  $ #{script}                                # list public CDN names
  $ #{script} [-q] cdnjs                     # list libraries
  $ #{script} [-q] cdnjs 'jquery*'           # search libraries
  $ #{script} [-q] cdnjs jquery              # list versions
  $ #{script} [-q] cdnjs jquery latest       # show latest version
  $ #{script} [-q] cdnjs jquery 3.6.0        # list files
  $ #{script} [-q] cdnjs jquery 3.6.0 /tmp   # download files into directory

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
      cmdopts = parse_cmdopts(args, "hvq", ["help", "version", "quiet"])
      return help_message() if cmdopts['h'] || cmdopts['help']
      return RELEASE + "\n" if cmdopts['v'] || cmdopts['version']
      @quiet = cmdopts['quiet'] || cmdopts['q']
      #
      validate(args[1], args[2])
      #
      case args.length
      when 0
        return do_list_cdns()
      when 1
        cdn_code = args[0]
        return do_list_libraries(cdn_code)
      when 2
        cdn_code, library = args
        if library.include?('*')
          return do_search_libraries(cdn_code, library)
        else
          return do_find_library(cdn_code, library)
        end
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

    def validate(library, version)
      if library && ! library.include?('*')
        library =~ /\A[-.\w]+\z/  or
          raise CommandError.new("#{library}: Unexpected library name.")
      end
      if version
        version =~ /\A[-.\w]+\z/  or
          raise CommandError.new("#{version}: Unexpected version number.")
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
      return klass.new
    end

    def render_list(list)
      if @quiet
        return list.collect {|d| "#{d[:name]}\n" }.join()
      else
        return list.collect {|d| "%-20s  # %s\n" % [d[:name], d[:desc]] }.join()
      end
    end

    def do_list_cdns
      if @quiet
        return CLASSES.map {|c| "#{c::CODE}\n" }.join()
      else
        return CLASSES.map {|c| "%-10s  # %s\n" % [c::CODE, c::SITE_URL] }.join()
      end
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
      s = ""
      if @quiet
        d[:versions].each do |ver|
          s << "#{ver}\n"
        end if d[:versions]
      else
        s << "name:     #{d[:name]}\n"
        s << "desc:     #{d[:desc]}\n" if d[:desc]
        s << "tags:     #{d[:tags]}\n" if d[:tags]
        s << "site:     #{d[:site]}\n" if d[:site]
        s << "license:  #{d[:license]}\n" if d[:license]
        s << "snippet: |\n" << d[:snippet].gsub(/^/, '    ') if d[:snippet]
        s << "versions:\n"
        d[:versions].each do |ver|
          s << "  - #{ver}\n"
        end if d[:versions]
      end
      return s
    end

    def do_get_library(cdn_code, library, version)
      cdn = find_cdn(cdn_code)
      version = _latest_version(cdn, library) if version == 'latest'
      d = cdn.get(library, version)
      s = ""
      if @quiet
        d[:urls].each do |url|
          s << "#{url}\n"
        end if d[:urls]
      else
        s << "name:     #{d[:name]}\n"
        s << "version:  #{d[:version]}\n"
        s << "desc:     #{d[:desc]}\n" if d[:desc]
        s << "tags:     #{d[:tags]}\n" if d[:tags]
        s << "site:     #{d[:site]}\n" if d[:site]
        s << "default:  #{d[:default]}\n" if d[:default]
        s << "license:  #{d[:license]}\n" if d[:license]
        s << "snippet: |\n" << d[:snippet].gsub(/^/, '    ') if d[:snippet]
        s << "urls:\n"  if d[:urls]
        d[:urls].each do |url|
          s << "  - #{url}\n"
        end if d[:urls]
      end
      return s
    end

    def do_download_library(cdn_code, library, version, basedir)
      cdn = find_cdn(cdn_code)
      version = _latest_version(cdn, library) if version == 'latest'
      cdn.download(library, version, basedir, quiet: @quiet)
      return nil
    end

    private

    def _latest_version(cdn, library)
      d = cdn.find(library)
      return d[:versions].first
    end

  end


end


if __FILE__ == $0
  CDNGet::Main.main()
end
