require_relative 'context' 
require_relative '../lib/studio'
require 'json'

namespace :studio do

  # studio image map 
  IMAGES = SERIES.flat_map{|page|
    dir = File.join(CONFIG.site_root, page.assets_dir, 'thumb')
    page.images.map{
      key = File.basename(it, '.*')      
      [ key, File.join(dir, key.ext('webp')) ]
    }
  }.to_h
  
  desc "Copy studio.css"
  task :css do
    raw, www = File.join('assets', 'css', 'studio.css')
      .then{ [File.join(RAW, it), File.join(WWW, it)] }
    File.dirname(www).then{ Dir.mkdir(it) unless Dir.exist?(it) }
    
    cp raw, www, verbose: false
  end
  
  desc "Generate Studio Vault pages"
  task :pages do
    # TODO: change bin/imprint into exe/imprint inventory
    # NOTE: it depends on /journals/*.imprint records!
    studio_json = %x(../imprint/exe/inventory)
    # puts studio_json
    unless $?.success?
      puts "[Skip] Studio Vault empty"
      return
    end

    studio_data = JSON.parse(studio_json)
    generator = Studio::Vault.new(studio_data, IMAGES, RAW)
    generator.call
    
    # TODO: adopt the original file for Lightbox use that should
    #   show prints on Vault availability
    # studio_manifest = File.join(Rawww::PUBLIC_DIR, 'studio.json')
    # File.write(studio_manifest, studio_json)
  end

end

desc 'Build studio vault pages'
task :studio => %w[studio:pages studio:css]
