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
require 'json'
require 'fileutils'


module CDNGet


  RELEASE = '$Release: 0.0.0 $'.split()[1]

  CLASSES = []


  class Base

    def self.inherited(klass)
      CLASSES << klass
    end

    def list()
      raise NotImplementedError.new("#{self.class.name}#list(): not implemented yet.")
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
      target_dir = File.join(basedir, library, version)
      d = get(library, version)
      d[:files].each do |file|
        filepath = File.join(target_dir, file)
        dirpath  = File.dirname(filepath)
        print "#{filepath} ..." unless quiet
        url = File.join(d[:baseurl], file)   # not use URI.join!
        content = fetch(url)
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
      nil
    end

    protected

    def fetch(url, library=nil)
      begin
        html = open(url, 'rb') {|f| f.read() }
        return html
      rescue OpenURI::HTTPError => ex
        raise CommandError.new("GET #{url} : #{ex.message}")
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


  class HttpError < StandardError
  end


  class CDNJS < Base    # TODO: use jsdelivr api
    CODE = "cdnjs"
    SITE_URL = 'https://cdnjs.com/'

    def fetch(url, library=nil)
      begin
        html = open(url, 'rb') {|f| f.read() }
        if library
          html =~ /<h1\b.*?>(.*?)<\/h1>/  or
            raise CommandError.new("#{library}: Library not found.")
          library == $1.strip()  or
            raise CommandError.new("#{library}: Library not found (maybe '#{$1.strip()}'?).")
        end
        return html
      rescue OpenURI::HTTPError => ex
        raise HttpError.new("GET #{url} : #{ex.message}")
      end
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
      jstr = fetch("https://api.cdnjs.com/libraries/#{library}")
      jdata = JSON.parse(jstr)
      return {
        name: library,
        desc: jdata['description'],
        tags: (jdata['keywords'] || []).join(", "),
        versions: jdata['assets'].collect {|d| d['version'] },
      }
    end

    def get(library, version)
      validate(library, version)
      jstr = fetch("https://api.cdnjs.com/libraries/#{library}")
      jdata = JSON.parse(jstr)
      d = jdata['assets'].find {|d| d['version'] == version }  or
        raise CommandError.new("#{library}/#{version}: Library or version not found.")
      baseurl = "https://cdnjs.cloudflare.com/ajax/libs/#{library}/#{version}/"
      return {
        name:     library,
        desc:     jdata['description'],
        tags:     (jdata['keywords'] || []).join(", "),
        version:  version,
        urls:     d['files'].collect {|s| baseurl + s },
        files:    d['files'],
        baseurl:  baseurl,
      }
    end

  end


  class JSDelivr < Base
    CODE = "jsdelivr"
    SITE_URL = "https://www.jsdelivr.com/"
    API_URL  = "https://api.jsdelivr.com/v1/jsdelivr/libraries"

    def list
      json = fetch("#{API_URL}?fields=name,description,homepage")
      arr = JSON.load(json)
      return arr.collect {|d|
        {name: d["name"], desc: d["description"], site: d["homepage"] }
      }
    end

    def find(library)
      validate(library, nil)
      json = fetch("#{API_URL}?name=#{library}&fields=name,description,homepage,versions")
      arr = JSON.load(json)
      d = arr.first  or
        raise CommandError.new("#{library}: Library not found.")
      return {
        name:     d['name'],
        desc:     d['description'],
        site:     d['homepage'],
        versions: d['versions'],
      }
    end

    def get(library, version)
      validate(library, version)
      baseurl = "https://cdn.jsdelivr.net/#{library}/#{version}"
      url = "#{API_URL}/#{library}/#{version}"
      json  = fetch("#{API_URL}/#{library}/#{version}")
      files = JSON.load(json)
      ! files.empty?  or
        raise CommandError.new("#{library}: Library not found.")
      urls  = files.collect {|x| "#{baseurl}/#{x}" }
      return {
        name:     library,
        version:  version,
        urls:     urls,
        files:    files,
        baseurl:  baseurl,
      }
    end

  end


  class GoogleCDN < Base    # TODO: use jsdelivr api
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
#{script}  -- download files from public CDN

Usage: #{script} [options] [CDN] [library] [version] [directory]

Options:
  -h, --help        : help
  -v, --version     : version
  -q, --quiet       : minimal output

Example:
  $ #{script}                                # list public CDN
  $ #{script} [-q] cdnjs                     # list libraries
  $ #{script} [-q] cdnjs jquery              # list versions
  $ #{script} [-q] cdnjs jquery 2.2.0        # list files
  $ #{script} [-q] cdnjs jquery 2.2.0 /tmp   # download files
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
      return render_list(cdn.list)
    end

    def do_search_libraries(cdn_code, pattern)
      cdn = find_cdn(cdn_code)
      rexp_str = pattern.split('*', -1).collect {|x| Regexp.escape(x) }.join('.*')
      rexp = Regexp.compile("\\A#{rexp_str}\\z", Regexp::IGNORECASE)
      return render_list(cdn.list.select {|a| a[:name] =~ rexp })
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
        s << "name:  #{d[:name]}\n"
        s << "desc:  #{d[:desc]}\n" if d[:desc]
        s << "tags:  #{d[:tags]}\n" if d[:tags]
        s << "site:  #{d[:site]}\n" if d[:site]
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
      d = cdn.get(library, version)
      s = ""
      if @quiet
        d[:urls].each do |url|
          s << "#{url}\n"
        end if d[:urls]
      else
        s << "name:     #{d[:name]}\n"
        s << "version:  #{d[:version]}\n"
        s << "tags:     #{d[:tags]}\n" if d[:tags]
        s << "site:     #{d[:site]}\n" if d[:site]
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
      cdn.download(library, version, basedir, quiet: @quiet)
      return nil
    end

  end


end


if __FILE__ == $0
  CDNGet::Main.main()
end
