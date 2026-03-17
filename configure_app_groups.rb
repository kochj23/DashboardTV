#!/usr/bin/env ruby
# Configure App Groups and entitlements for DashboardTV
# Created by Jordan Koch

require 'xcodeproj'

project_path = '/Volumes/Data/xcode/DashboardTV/DashboardTV.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Configuring App Groups for DashboardTV..."

# Configure main app target
main_target = project.targets.find { |t| t.name == 'DashboardTV' }
if main_target
  main_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'DashboardTV/DashboardTV.entitlements'
  end
  puts "Main app entitlements configured"
end

# Configure Top Shelf target
topshelf_target = project.targets.find { |t| t.name == 'DashboardTVTopShelf' }
if topshelf_target
  topshelf_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'DashboardTVTopShelf/DashboardTVTopShelf.entitlements'
  end
  puts "Top Shelf entitlements configured"
end

# Add TopShelfDataManager.swift to the project
dashboardtv_group = project.main_group.children.find { |c| c.name == 'DashboardTV' }
if dashboardtv_group && main_target
  existing = dashboardtv_group.files.find { |f| f.path&.include?('TopShelfDataManager.swift') }
  unless existing
    file_ref = dashboardtv_group.new_file('TopShelfDataManager.swift')
    main_target.source_build_phase.add_file_reference(file_ref)
    puts "TopShelfDataManager.swift added to project"
  end

  # Add entitlements
  existing_ent = dashboardtv_group.files.find { |f| f.path&.include?('entitlements') }
  unless existing_ent
    dashboardtv_group.new_file('DashboardTV/DashboardTV.entitlements')
    puts "Main app entitlements file added"
  end
end

topshelf_group = project.main_group.children.find { |c| c.name == 'DashboardTVTopShelf' }
if topshelf_group
  existing = topshelf_group.files.find { |f| f.path&.include?('entitlements') }
  unless existing
    topshelf_group.new_file('DashboardTVTopShelf/DashboardTVTopShelf.entitlements')
    puts "Top Shelf entitlements file added"
  end
end

project.save
puts "App Groups configuration completed for DashboardTV!"
