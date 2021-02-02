# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'ConnieDelivers' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ConnieDelivers
		pod  'Firebase/Core'
		pod  'Firebase/Database'
		pod  'Firebase/Auth'
		pod  'Firebase/Storage'
		pod  'GeoFire' ,  '>= 1.1'
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
          config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
      end
    end
  end
end
