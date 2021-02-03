source 'https://github.com/cosmos33/MMSpecs.git'
source 'https://cdn.cocoapods.org/'


#use_frameworks!

platform :ios, '10.0'

def beautyInstall
  # 版本5
  pod 'MMBeautyKit', '2.2.0-Interact'
  
  # 版本4
#  pod 'MMBeautyKit', '2.2.0-Micro-surgery'
  
  # 版本3
#  pod 'MMBeautyKit', '2.2.0-Sticker'
  
  # 版本2
#  pod 'MMBeautyKit', '2.2.0-Filter'
  
  # 版本1
#  pod 'MMBeautyKit', '2.2.0-Basic'
  
  pod 'MetalPetal/Static', '1.13.0', :modular_headers => true

end

target 'MMBeautyKitDemo' do

  beautyInstall
  
end

target 'MMTXBeautyKitDemo' do

  beautyInstall
  # 腾讯直播推流
  pod 'TXLiteAVSDK_Professional'

end

target 'MMQNBeautyKitDemo' do

  beautyInstall
  # 七牛直播推流
  pod 'PLMediaStreamingKit'

end

target 'MMArgoraBeautyKitDemo' do
    
  beautyInstall
    
  pod 'AgoraRtcEngine_iOS'
  
end

target 'MMZegoBeautyKitDemo' do
    
    beautyInstall
    
    pod 'ZegoLiveRoom'
    
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
