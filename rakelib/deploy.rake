# rakelib/deploy.rake

require 'fileutils'
require './lib/rawww'

namespace :site do
  # desc "Deploy the compiled website to a separate GitHub repository"
  task :push do
    puts Rawww::BANNER
    puts Rawww.environment_info
    puts "  » Launching production deployment execution phase..."

    # Extract single source of truth path from our Data config instance
    public_dir = Rawww::Config.instance.public_dir rescue 'www'
    
    # =========================================================================
    # НАСТРОЙКА НОВОГО РЕПОЗИТОРИЯ
    # 1. Замените строку ниже на SSH-адрес вашего нового пустого репозитория:
    remote_url = "git@github.com:nvoynov/exposure.git" 
    
    # 2. Указываем 'main' (современный стандарт GitHub для главных веток)
    target_branch = "main" 
    # =========================================================================

    unless Dir.exist?(public_dir)
      puts "  [Error] Target build directory '#{public_dir}' does not exist."
      exit 1
    end

    # Navigate into the compiled output directory
    Dir.chdir(public_dir) do
      puts "  » Initializing temporary deployment repository..."
      # Создаем репозиторий сразу с веткой main
      system("git init -b #{target_branch}")
      system("git config user.name 'rawww-bot'")
      system("git config user.email 'rawww-bot@local.internal'")
      
      puts "Staging compiled production nodes..."
      system("git add .")
      
      puts "Committing frozen raw production state..."
      system("git commit -m 'Automated rawww production deployment close'")
      
      puts "Executing force push sequence to remote #{target_branch} branch..."
      # Силовым пушем перезаписываем ветку main в удаленном репозитории
      success = system("git push --force #{remote_url} #{target_branch}")

      if success
        puts "  ─────────────────────────────────"
        puts "  » Deployment successful! Your raw node is live."
      else
        puts "  [Error] Push sequence failed. Verify your repository write permissions."
      end
    end

    # Clean up the hidden temporary .git metadata directory inside public path
    git_cache = File.join(public_dir, '.git')
    FileUtils.rm_rf(git_cache) if Dir.exist?(git_cache)
  end
end

# Intercept the global shortcut call
task :deploy do
  ENV['RAWWW_PRODUCTION'] = 'true'
  puts "Production environment state locked."
    
  puts "Flushing local compilation caches..."
  Rake::Task['clean'].invoke

  puts "Generating series markdown..."
  Rake::Task['series'].invoke

  puts "Generating studio markdown..."
  Rake::Task['studio'].invoke

  puts "Triggering development build..."
  Rake::Task['build'].invoke
  
  Rake::Task['site:push'].invoke
end
