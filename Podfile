source 'https://github.com/cosmos33/MMSpecs.git'
source 'https://cdn.cocoapods.org/'


#use_frameworks!
use_frameworks! :linkage=>:static

platform :ios, '10.0'

def beautyInstall
# 精简版
#  pod 'MMBeautyKit', '2.5.4-basic'
  
# 完整版
  pod 'MMBeautyKit', '2.8.0.4-interact'
#  pod 'MMCV','2.7.0-MMBeauty'
  pod 'MMCV','2.7.1.3'
  pod 'MMBeautyMedia','2.8.0.5'
  pod 'MetalPetal/Static', '1.13.0', :source => 'https://github.com/cosmos33/MMSpecs.git'

  
# 无子依赖版本，整合所有framework版本, 特殊接入需要，正常不使用
#  pod 'MMBeautyKit', '2.5.4-basic-allin'
#  pod 'MMBeautyKit', '2.5.4-interact-allin'

end

target 'MMBeautyKitDemo' do

  beautyInstall
  pod 'Masonry'
  
end

#target 'MMTXBeautyKitDemo' do
#
#  beautyInstall
#  # 腾讯直播推流
#  pod 'Masonry'
#  pod 'TXLiteAVSDK_Professional'
#
#end
#
#target 'MMQNBeautyKitDemo' do
#
#  beautyInstall
#  # 七牛直播推流
#  pod 'Masonry'
#  pod 'PLMediaStreamingKit'
#
#end
#
#target 'MMQNSortVideoBeautyDemo' do
#
#  beautyInstall
#
#  #七牛短视频SDK
##  pod "PLShortVideoKit"
#  pod 'PLShortVideoKit/ex-libMuseProcessor'
#
#  pod "TZImagePickerController"
#
#  pod 'Masonry'
#  pod 'MMMaterialDesignSpinner'
#  pod 'JGProgressHUD', '2.0'
#  pod 'SDWebImage'
#  pod 'SDCycleScrollView','>= 1.80'
#
#end

target 'MMArgoraBeautyKitDemo' do
    
  beautyInstall
  pod 'Masonry'
  
  pod 'AgoraRtcEngine_iOS','3.4.2'
  
end

#target 'MMZegoBeautyKitDemo' do
#
#    beautyInstall
#    pod 'Masonry'
#    pod 'ZegoLiveRoom'
#
#end

#target 'MMZegoExpressBeautyDemo' do
#
#    beautyInstall
#    pod 'Masonry'
#    pod 'ZegoExpressEngine/Video'
#
#end
#
#
#target 'MMAliBeautyKitDemo' do
#
#    beautyInstall
#    pod 'Masonry'
#    pod 'AliLiveSDK_iOS', '4.0.2'
#    pod 'RtsSDK','1.5.0'
#    pod 'Masonry'
#
#end

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
