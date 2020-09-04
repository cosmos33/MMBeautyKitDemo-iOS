source 'https://github.com/cosmos33/MMSpecs.git'
source 'https://cdn.cocoapods.org/'


#use_frameworks!

platform :ios, '10.0'

target 'MMBeautyKitDemo' do

  pod 'MetalPetal', '1.10.5', :modular_headers => true
  pod 'MMBeautyKit', '1.2.2'
  
  # 解决HTTPDNS过大问题
  pod 'PhotonHTTPDNS','1.0.2'
  
  # 七牛直播推流
  pod 'PLMediaStreamingKit'
  
  # 腾讯直播推流
  pod 'TXLiteAVSDK_Professional'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|

        target.build_configurations.each do |config|
            config.build_settings['PROVISIONING_PROFILE'] = ''
            config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ''
            config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
            config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        end
    end
end
