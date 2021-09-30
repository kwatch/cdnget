# -*- coding: utf-8 -*-

###

RELEASE   = '$Release: 0.3.1 $'.split()[1]
COPYRIGHT = 'copyright(c) 2016 kuwata-lab.com all rights reserved'
LICENSE   = 'MIT License'

PROJECT   = 'cdnget'


### helpers

def run(command)
  print '[rake]$ '; sh command
end

def edit_content(content, release=RELEASE)
  s = content
  s = s.gsub /\$Release\:.*?\$/,   "$Release\: #{release} $"
  s = s.gsub /\$Copyright\:.*?\$/, "$Copyright\: #{COPYRIGHT} $"
  s = s.gsub /\$License\:.*?\$/,   "$License\: #{LICENSE} $"
  s = s.gsub /\$Release\$/,   release
  s = s.gsub /\$Copyright\$/, COPYRIGHT
  s = s.gsub /\$License\$/,   LICENSE
  s
end

def load_gemspec
  spec = eval File.read("#{PROJECT}.gemspec", encoding: 'utf-8')
  return spec
end


### tasks


#task :default => :test

desc "run test scripts"
task :test do
  #sh "ruby -r minitest/autorun test/*_test.rb"
  run "ruby -I ./lib test/#{PROJECT}_test.rb"
end


desc "remove *.rbc"
task :clean do
  rm_f [Dir.glob("lib/**/*.rbc"), Dir.glob("test/**/*.rbc")]
end


desc "how to release"
task :howtorelease do
  rel = ENV['rel'] || RELEASE
  ver = rel.sub(/\.\d+$/,'')
  patch_zero = !! (rel =~ /\.0$/)
  puts <<END
$ git branch | grep '\*'
* ruby-dev
$ git checkout #{patch_zero ? '-b ': ''}ruby-#{ver}
$ rake edit rel=#{rel}
$ git diff
$ git commit -a -m "ruby: release preparation for #{rel}"
$ rake package
$ rake publish
END
end


desc "create 'bin/cdnget'"
task :bin do
  material = "lib/cdnget.rb"
  product  = "bin/cdnget"
  run %Q`cat #{material} | awk '{c=""}/if __FILE__/{f=1;c="#"}f&&/end/{c="#"}{print c $0}' > #{product}`
  run %Q`chmod a+x #{product}`
end


desc "edit '$Release\:...$' in files"
task :edit => :bin do
  rel = ENV['rel']
  unless rel
    $stderr.puts "*** Release number is not speicified"
    $stderr.puts "*** Usage: rake edit rel=X.X.X"
    raise StandardError
  end
  spec = load_gemspec()
  spec.files.each do |fpath|
    if fpath =~ /\.(gz|jpg|png|form)\z/
      puts "[ignore] #{fpath}"
      next
    end
    s1 = File.open(fpath, encoding: 'utf-8') {|f| f.read() }
    s2 = edit_content(s1, rel)
    if s1 == s2
      puts "[skip] #{fpath}"
    else
      puts "[Edit] #{fpath}"
      File.open(fpath, 'w', encoding: 'utf-8') {|f| f.write(s2) }
    end
  end
end


desc "create rubygem pacakge"
task :package do
  spec = load_gemspec()
  name = spec.name
  ver  = spec.version
  run "gem build #{name}.gemspec"
  puts ""
  puts "## files"
  puts spec.files.collect {|x| "- #{x}" }
end


desc "release gem"
task :publish do
  diff = `git diff --stat`
  if diff && ! diff.empty?
    raise "[ERROR] Please commit changes before publishing gem."
  end
  #
  spec = load_gemspec()
  name = spec.name
  ver  = spec.version
  #
  gem = "#{name}-#{ver}.gem"
  File.exist?(gem)  or
    raise "[ERROR] run 'rake package' before publishing gem."
  mtime = File.mtime(gem)
  ! spec.files.any? {|fpath| File.mtime(fpath) >= mtime }  or
    raise "[ERROR] run 'rake package' again because gem file seems obsoleted."
  #
  print "Upload #{gem}. OK? [y/N]: "
  if $stdin.gets() =~ /[yY]/
    run "gem push #{gem}"
    run "git push -u origin `git rev-parse --abbrev-ref HEAD`"
    run "git push -f origin HEAD:ruby-release"
    run "git tag ruby-#{ver}"
    run "git push --tags"
  end
end
