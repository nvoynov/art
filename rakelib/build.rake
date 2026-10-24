require 'pathname'
require 'rake/clean'
require_relative 'context'

# rake clean
CLEAN.include(
  File.join(WWW, 'sitemap.xml'),
  File.join(WWW, 'robots.txt'),
  File.join(WWW, 'cachemap.json'),
  File.join(WWW, 'seriesmap.json'),
  File.join(WWW, 'sw.js'),
  File.join(RAW, 'series/*'),
  File.join(RAW, 'series.md'),
  File.join(RAW, 'studio/vault.md'),
  File.join(RAW, 'studio/vault/*'),
  SiteModel.new.pages.map(&:destination_path)
)

# rake clobber
CLOBBER.include(WWW)

# BIG BUILD RAKE
namespace :site do

######## Copy/Compile Assets

  RAW_ASSETS = File.join(RAW, 'assets')
  WWW_ASSETS = File.join(WWW, 'assets')

  STYLE_ASSETS = FileList[File.join(RAW_ASSETS, '**/*.css')]
  WWW_CSS_DIR  = File.join(WWW_ASSETS, 'css')  
  WWW_JS_DIR   = File.join(WWW_ASSETS, 'js')
  WWW_STYLE    = File.join(WWW_CSS_DIR, 'style.css')
  ASSET_FILES  = FileList[File.join(RAW_ASSETS, '**/*.*')].reject{ File.directory?(_1) }
  WWW_OTHERS   = (ASSET_FILES - STYLE_ASSETS).pathmap("%{^#{RAW}/,#{WWW}/}p")

  directory WWW_ASSETS
  directory WWW_JS_DIR
  directory WWW_CSS_DIR

  file WWW_STYLE => [WWW_ASSETS, WWW_CSS_DIR, *STYLE_ASSETS] do
    StyleTask.call
    puts "  » assets: compiled #{WWW_STYLE}"
  end

  # just copy other than styles and series/ images
  rule(%r{^#{WWW_ASSETS}/(?!css/|.+/css/|series/).+$}) do |t|
    source = t.name.sub(/^#{WWW_ASSETS}/, RAW_ASSETS)
    next unless File.exist?(source)
    File.dirname(t.name).then{ mkdir_p it unless Dir.exist?(it) }
    cp source, t.name, verbose: false
    puts "  » assets: copied #{source} -> #{t.name}"
  end

  desc 'Copy assets'
  task :assets => ([WWW_STYLE] + WWW_OTHERS) #  [WWW_STYLE, *WWW_OTHERS.to_a]

######## Compile Markdown pages

  COMPILER = PageTask.new

  def pagemap
    SiteModel.new.pages
      .map{ [it.destination_path, it.source_path] }
      .to_h
  end
  
  rule ".html" => ->(f){ pagemap[f] } do |t|
    COMPILER.(t.source, extra_arguments: extra_args(t.name))
    puts "  » pages: compiled #{t.name}"
  end

  desc 'Compile markdown pages'
  # task :pages => proc{ pagemap.keys }
  task :pages do
    pagemap.keys.each do |html_file|
      Rake::Task[html_file].invoke
    end
    puts "  » pages: all markdown pages verified/compiled"
  end

  ANALYTICS = File.join(RAW, 'fragments', 'analytics.html')
  LIGHBOX   = File.join(RAW, 'fragments', 'lightbox.html')
  
  # Helper method to dry up and orchestrate native Pandoc include-before-body injections
  def extra_args(target_src)
    is_index  = target_src.match?(/\/index\.html$/)
    is_series = target_src.match?(/\/series\/.*\.html$/)

    [].tap{
      it << "--include-before-body=#{ANALYTICS}"
      it << "--include-before-body=#{LIGHBOX}" \
        if is_index || is_series
    }
  end

######## Site index files

  URL = CONFIG.site_url 
  SITEMAP = File.join(WWW, 'sitemap.xml')

  desc "Build sitemap.xml, triggers md -> html"
  file SITEMAP => :pages do |t|
    SitemapTask.call
    puts "  » index: dump /#{t.name}"
  end

  ROBOTS = File.join(WWW, 'robots.txt')

  desc "Build robots.txt"
  file ROBOTS do |t|
    content = <<~TEXT
      # robots.txt for rawww static engine
      User-agent: *
      Allow: /

      Sitemap: #{URL}/sitemap.xml
    TEXT

    File.write(t.name, content)
    puts "  » index: dump /#{t.name}"
  end

  CACHEMAP = File.join(WWW, 'cachemap.json')
  desc "Build cachemap.json"
  file CACHEMAP do |t|
    CachemapTask.call
    puts "  » index: dump /#{t.name}"
  end

  RAW_SERVICE = File.join(RAW, 'sw.js')
  SERVICE = File.join(WWW, 'sw.js')
  
  desc "Copy sw.js"
  file SERVICE do
    cp RAW_SERVICE, SERVICE, verbose: false
    puts "  » index: copy /#{SERVICE}"
  end

  desc 'Build site index'
  task :index => [SITEMAP, ROBOTS, CACHEMAP, SERVICE]
end

desc "Build site"
task :build => %w[ site:assets site:index ]
