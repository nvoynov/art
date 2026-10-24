require_relative 'context'

# Flatplan pages integration
namespace :series do
  include Series

  SERIES = BuildPagesTask.().pages.sort_by(&:latest_media_asset)
  MAGICK = Magick.new
  
##### Import Series Images

  # site images map 
  ORIGIN = SERIES.flat_map{|page|
    new = page.assets_dir
    old = File.dirname(page.images.first)
    page.images.map{ [ it.pathmap("%{#{old},#{new}}d/%n.webp"), it] }
  }.to_h

  JOIN_DIR = proc{|part, e|
    old = File.dirname(e)
    new = File.join(WWW, old, part)
    e.pathmap("%{#{old},#{new}}d/%f")
  }
  
  FULL  = ORIGIN.transform_keys(&JOIN_DIR.curry.call('full'))
  THUMB = ORIGIN.transform_keys(&JOIN_DIR.curry.call('thumb'))

  desc 'Convert full image'
  rule %r{/full/[^/]+\.webp$} => ->(f){ FULL[f] } do |t|
    File.dirname(t.name).then{ mkdir_p it unless Dir.exist?(it)  }
    MAGICK.convert_to_full(t.source, t.name)
    puts "  » series: image #{t.name}"
  end

  desc 'Convert thumbnail'
  rule %r{/thumb/[^/]+\.webp$} => ->(f){ THUMB[f] } do |t|
    File.dirname(t.name).then{ mkdir_p it unless Dir.exist?(it)  }
    MAGICK.convert_to_thumb(t.source, t.name)
    puts "  » series: thunbnail #{t.name}"
  end
  
  SERIES_OGS = SERIES.map{|page|
    filepath = File.join(WWW, page.assets_dir, Series::OG_IMAGE)
    [filepath, page]
  }.to_h   

  desc 'Series OpenGraph'
  rule %r{series/[^/]+/#{Series::OG_IMAGE}$} do |t|
    File.dirname(t.name).then{ mkdir_p it unless Dir.exist?(it) }
    page = SERIES_OGS[t.name]
    MAGICK.make_series_png(t.name, page.title)
    puts "  » series: OG #{t.name}"
  end

 
  SERIESMAP = File.join(WWW, 'seriesmap.json')
  file SERIESMAP do
    WriteSeriesMapTask.(SERIES)
    puts "  » series: map #{SERIESMAP}"
  end 
  
  desc 'Provide images'
  task :images => (FULL.keys + THUMB.keys + SERIES_OGS.keys + [SERIESMAP])

##### Import Series Pages

  SERIES_INDEX = File.join(RAW, 'series.md')
  SERIES_PAGES = SERIES.map{|page|
    filepath = File.join(RAW, 'series', page.slug + '.md')
    [filepath, page.filepath]
  }.to_h

  desc 'Build series page'
  rule %r{#{RAW}/series/[^/]+\.md} => ->(f){ SERIES_PAGES[f] } do |t|
    File.dirname(t.name).then{ mkdir_p it unless Dir.exist?(it) }
    page = SERIES.find{ it.filepath == t.source }
    WritePageTask.(page)
    puts "  » series: page #{t.name}"
  end

  desc 'series.md index'
  file SERIES_INDEX => SERIES_PAGES.keys do
    WriteIndexTask.(SERIES)
    puts "  » series: index #{SERIES_INDEX}"
  end
  
  task :pages => ([SERIES_INDEX] + SERIES_PAGES.keys)

##### Create Image Pages

  # Page template of {title, slug, og_image, redirect_script, filename}
  IMAGE_PAGE = <<~MARKDOWN
    ---
    title: "%{title} | Fine-Art Print Specification"
    layout: image_node
    slug: %{slug}
    og_image: "%{og_image}"
    header-includes: %{redirect}
    ---

    ::: {.image-node-presenter-fallback}
    # %{title}
    
    This photographic print node reference token code is: `%{filename}`.
    
    ![%{title}](../..%{filename})
    
    *Fine-Art limited editions printing metadata module placeholder.*
    :::
  MARKDOWN

  IMAGE_PAGES = SERIES.flat_map{|page|
    page.images.map{
      image_file = File.join('assets', 'series', page.slug, File.basename(it).ext('webp'))
      file = File.basename(it, '.*').downcase.ext('md')
      path = File.join(RAW, 'series', page.slug, file)
      [path, it]
    }
  }.to_h

  # image page URL
  # https://nvoynov.github.io/exposure42/series/bubbles/p1001476.html

  rule %r{#{RAW}/series/[^/]+/[^/]+\.md} do |t|
    # Page template of {title, slug, og_image, redirect_script, filename}
    File.dirname(t.name).then{ mkdir_p it unless Dir.exist?(it) }
    slug = File.basename(t.name, '.*').upcase
    dir = File.dirname(t.name).split('/').last
    redirect = "<script>window.location.replace(\"../#{dir}.html?img=#{slug}\");</script>"
    filename = File.join(CONFIG.site_root, 'assets', 'series', dir, 'full', slug + '.webp')
    og_image = File.join('assets', 'series', dir, 'thumb', slug + '.webp')
    params = {
      title: "Unitled #{slug}",
      slug: slug,
      og_image: og_image,
      redirect: redirect,
      filename: filename,
    }
    content = IMAGE_PAGE % params
    # puts content; exit
    File.write(t.name, content)
    puts "  » series: redirect #{t.name}"
  end

  # pp IMAGE_PAGES #, IMAGE_MAP 
  task :redirect => IMAGE_PAGES.keys

end

task :series => %w[series:images series:pages series:redirect]
