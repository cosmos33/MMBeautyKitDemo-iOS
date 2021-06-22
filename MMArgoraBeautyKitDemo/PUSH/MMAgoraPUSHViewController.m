//
//  MMAgoraPUSHViewController.m
//  MMArgoraBeautyKitDemo
//
//  Created by sunfei on 2020/11/24.
//  Copyright © 2020 sunfei. All rights reserved.
//

#import "MMAgoraPUSHViewController.h"
#import "MMDeviceMotionObserver.h"
#import "MMBeautyRender.h"
#import "MMCameraTabSegmentView.h"
@import MetalPetal;
@import AVFoundation;
#import <AgoraRtcKit/AgoraRtcEngineKit.h>
#import "MMAgoraCamera.h"

static AgoraVideoRotation argoraRotation(UIInterfaceOrientation orientation) {
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return AgoraVideoRotation90;
        case UIInterfaceOrientationPortraitUpsideDown:
            return AgoraVideoRotation270;
        case UIInterfaceOrientationLandscapeLeft:
            return AgoraVideoRotationNone;
        case UIInterfaceOrientationLandscapeRight:
            return AgoraVideoRotation180;
        default:
            return AgoraVideoRotation90;
    }
}

@interface MMAgoraPUSHViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, MMDeviceMotionHandling, AgoraRtcEngineDelegate, MMAgoraCameraDelegate>

@property (nonatomic, strong) MMAgoraCamera *camera;
@property (nonatomic, strong) MMBeautyRender *render;
@property (nonatomic, strong) AgoraRtcEngineKit *agoraKit;
@property (nonatomic, assign) BOOL isJoined;

@property (nonatomic, strong) MTIImageView *localView;
@property (nonatomic, strong) UIView *remoteView;

@property (nonatomic, strong) MMCameraTabSegmentView *lookupView;
@property (nonatomic, strong) MMCameraTabSegmentView *beautyView;
@property (nonatomic, strong) MMCameraTabSegmentView *stickerView;

@end

@implementation MMAgoraPUSHViewController

- (void)dealloc {
    [MMDeviceMotionObserver removeDeviceMotionHandler:self];
    [MMDeviceMotionObserver stopMotionObserve];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.camera = [[MMAgoraCamera alloc] init];
    self.camera.delegate = self;
    
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    // Do any additional setup after loading the view, typically from a nib.
    
    self.localView = [[MTIImageView alloc] initWithFrame:self.view.bounds];
    self.remoteView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 400)];

    [self.view addSubview:self.localView];
    [self.view addSubview:self.remoteView];
    
    [MMDeviceMotionObserver startMotionObserve];
    [MMDeviceMotionObserver addDeviceMotionHandler:self];
    
    self.render = [[MMBeautyRender alloc] init];
    self.render.inputType = MMRenderInputTypeStream;
    
    AgoraRtcEngineConfig *config = [[AgoraRtcEngineConfig alloc] init];
    config.appId = @"151a54796ecc427eb5d770b3561789f0";
    config.areaCode = AgoraAreaCodeGLOB;
    self.agoraKit = [AgoraRtcEngineKit sharedEngineWithConfig:config delegate:self];
    
    NSString *channelName = @"123";
    [self.agoraKit setChannelProfile:AgoraChannelProfileLiveBroadcasting];
    [self.agoraKit setClientRole:AgoraClientRoleBroadcaster];
//    [self.agoraKit setClientRole:AgoraClientRoleAudience];
    [self.agoraKit enableVideo];
    
    [self.agoraKit setExternalVideoSource:YES useTexture:YES pushMode:YES];
    AgoraVideoEncoderConfiguration *configuration = [[AgoraVideoEncoderConfiguration alloc] initWithSize:AgoraVideoDimension640x480 frameRate:AgoraVideoFrameRateFps15 bitrate:AgoraVideoBitrateStandard orientationMode:AgoraVideoOutputOrientationModeFixedPortrait];
    [self.agoraKit setVideoEncoderConfiguration:configuration];
    
    [self.agoraKit setDefaultAudioRouteToSpeakerphone:YES];
    
    int ret = [self.agoraKit joinChannelByToken:@"006151a54796ecc427eb5d770b3561789f0IAAU8SCW046DWAWSM5fyyisdpzoygXG2IeM0rBZX8jjKxNJjSIgAAAAAEABID2Uq1668XwEAAQDWrrxf" channelId:channelName info:nil uid:0 joinSuccess:^(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed) {
        self.isJoined = YES;
    }];
    NSAssert(ret == 0, @"");
    
    [self setupViews];
    
   
}

- (void)setupViews {
    
    self.view.backgroundColor = UIColor.blackColor;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:@"翻转" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(flipButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:@[@"美颜", @"滤镜", @"贴纸"]];
    control.selectedSegmentIndex = 0;
    control.translatesAutoresizingMaskIntoConstraints = NO;
    [control addTarget:self action:@selector(switchButtonClicked:) forControlEvents:UIControlEventValueChanged];
    
    UIStackView *hStackView = [[UIStackView alloc] initWithArrangedSubviews:@[control, button]];
    hStackView.translatesAutoresizingMaskIntoConstraints = NO;
    hStackView.axis = UILayoutConstraintAxisHorizontal;
    hStackView.alignment = UIStackViewAlignmentCenter;
    hStackView.distribution = UIStackViewDistributionEqualSpacing;
    hStackView.spacing = 16;
    [self.view addSubview:hStackView];
    
    [control.widthAnchor constraintEqualToConstant:120].active = YES;
    
    [hStackView.heightAnchor constraintEqualToConstant:40].active = YES;
    [hStackView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:8].active = YES;
    if (@available(iOS 11.0, *)) {
        [hStackView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:40].active = YES;
    } else {
        [hStackView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:40].active = YES;
    }
    
    MMCameraTabSegmentView *segmentView = [[MMCameraTabSegmentView alloc] initWithFrame:CGRectZero];
    segmentView.items = [self itemsForLookup];
    segmentView.translatesAutoresizingMaskIntoConstraints = NO;
    segmentView.hidden = YES;
    self.lookupView = segmentView;
    [self.view addSubview:segmentView];
    
    [segmentView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [segmentView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [segmentView.heightAnchor constraintEqualToConstant:160].active = YES;
    if (@available(iOS 11.0, *)) {
        [segmentView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = YES;
    } else {
        [segmentView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    }
    
    __weak typeof(self) weakself = self;
    
    segmentView.clickedHander = ^(MMSegmentItem *item) {
        __strong typeof(self) self = weakself;
        [self.render setLookupPath:item.type];
        [self.render setLookupIntensity:item.intensity];
    };
    
    segmentView.sliderValueChanged = ^(MMSegmentItem *item, CGFloat intensity) {
        __strong typeof(self) self = weakself;
        [self.render setLookupIntensity:intensity];
    };
    
    MMCameraTabSegmentView *segmentView2 = [[MMCameraTabSegmentView alloc] initWithFrame:CGRectZero];
    segmentView2.items = [self itemsForBeauty];
    segmentView2.backgroundColor = UIColor.clearColor;
    segmentView2.translatesAutoresizingMaskIntoConstraints = NO;
    segmentView2.hidden = NO;
    self.beautyView = segmentView2;
    [self.view addSubview:segmentView2];
    
    [segmentView2.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [segmentView2.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [segmentView2.heightAnchor constraintEqualToConstant:160].active = YES;
    if (@available(iOS 11.0, *)) {
        [segmentView2.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = YES;
    } else {
        [segmentView2.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    }
    
    segmentView2.clickedHander = ^(MMSegmentItem *item) {
        __strong typeof(self) self = weakself;
        [self.render setBeautyFactor:item.intensity forKey:item.type];
    };
    
    segmentView2.sliderValueChanged = ^(MMSegmentItem *item, CGFloat intensity) {
        __strong typeof(self) self = weakself;
        [self.render setBeautyFactor:intensity forKey:item.type];
    };
    
    MMCameraTabSegmentView *segmentView3 = [[MMCameraTabSegmentView alloc] initWithFrame:CGRectZero];
    segmentView3.items = [self itemsForSticker];
    segmentView3.backgroundColor = UIColor.clearColor;
    segmentView3.translatesAutoresizingMaskIntoConstraints = NO;
    segmentView3.hidden = YES;
    self.stickerView = segmentView3;
    [self.view addSubview:segmentView3];
    
    [segmentView3.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [segmentView3.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [segmentView3.heightAnchor constraintEqualToConstant:160].active = YES;
    if (@available(iOS 11.0, *)) {
        [segmentView3.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = YES;
    } else {
        [segmentView3.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    }
    
    segmentView3.clickedHander = ^(MMSegmentItem *item) {
        __strong typeof(self) self = weakself;
        NSString *path = item.type;
        if (path.length > 0) {
            [self.render setMaskModelPath:item.type];
        } else {
            [self.render clearSticker];
        }
    };
    
    segmentView3.sliderValueChanged = ^(MMSegmentItem *item, CGFloat intensity) {
    };
    
    UIView *beautyBtn = [self viewForSwitch:@"美颜开关" selectorName:@"beautyButton:"];
    [self.view addSubview:beautyBtn];
    [beautyBtn.topAnchor constraintEqualToAnchor:hStackView.bottomAnchor constant:8].active = YES;
    [beautyBtn.leadingAnchor constraintEqualToAnchor:hStackView.leadingAnchor].active = YES;
    
    UIView *lookupButton = [self viewForSwitch:@"滤镜开关" selectorName:@"lookupButton:"];
    [self.view addSubview:lookupButton];
    [lookupButton.topAnchor constraintEqualToAnchor:beautyBtn.bottomAnchor constant:8].active = YES;
    [lookupButton.leadingAnchor constraintEqualToAnchor:beautyBtn.leadingAnchor].active = YES;
    
    UIView *stickerBtn = [self viewForSwitch:@"贴纸开关" selectorName:@"stickerButton:"];
    [self.view addSubview:stickerBtn];
    [stickerBtn.topAnchor constraintEqualToAnchor:lookupButton.bottomAnchor constant:8].active = YES;
    [stickerBtn.leadingAnchor constraintEqualToAnchor:lookupButton.leadingAnchor].active = YES;
    
    
}

- (void)stickerButton:(UISwitch *)switchBtn {
    if (switchBtn.isOn) {
        [self.render addSticker];
    } else {
        [self.render removeSticker];
    }
}

- (void)lookupButton:(UISwitch *)switchBtn {
    if (switchBtn.isOn) {
        [self.render addLookup];
    } else {
        [self.render removeLookup];
    }
}

- (void)beautyButton:(UISwitch *)switchBtn {
    if (switchBtn.isOn) {
        [self.render addBeauty];
    } else {
        [self.render removeBeauty];
    }
}

- (void)switchButtonClicked:(UISegmentedControl *)control {
    self.beautyView.hidden = control.selectedSegmentIndex != 0;
    self.lookupView.hidden = control.selectedSegmentIndex != 1;
    self.stickerView.hidden = control.selectedSegmentIndex != 2;
}

- (NSArray<MMSegmentItem *> *)itemsForSticker {
    NSArray *names = @[
        @{@"name" : @"重置", @"path" : @""},
        @{@"name" : @"777", @"path" : @"777"},
        @{@"name" : @"rainbow", @"path" : @"rainbow"},
        @{@"name" : @"手控樱花雨", @"path" : @"shoukongyinghua"},
        @{@"name" : @"微笑", @"path" : @"weixiao"},
        @{@"name" : @"抱拳", @"path" : @"baoquan"},
        @{@"name" : @"摇滚", @"path" : @"rock"},
        @{@"name" : @"比八", @"path" : @"biba"},
        @{@"name" : @"拜年", @"path" : @"bainian"},
        @{@"name" : @"点赞", @"path" : @"dianzan"},
        @{@"name" : @"一个手指", @"path" : @"yigeshouzhi"},
        @{@"name" : @"ok", @"path" : @"ok"},
        @{@"name" : @"打电话", @"path" : @"dadianhua"},
        @{@"name" : @"拳头", @"path" : @"quantou"},
        @{@"name" : @"剪刀手", @"path" : @"jiandaoshou"},
        @{@"name" : @"比心", @"path" : @"bixin"},
        @{@"name" : @"双手比心", @"path" : @"shuangshoubixin"},
        @{@"name" : @"666", @"path" : @"666"},
        @{@"name" : @"寒冷", @"path" : @"cold"},
        @{@"name" : @"可爱", @"path" : @"cute"},
        @{@"name" : @"高兴", @"path" : @"happy"},
        @{@"name" : @"慌忙", @"path" : @"hurry"},
        @{@"name" : @"凉凉", @"path" : @"liangliang"},
        @{@"name" : @"不说", @"path" : @"nosay"},
        @{@"name" : @"点我", @"path" : @"pickme"},
        @{@"name" : @"悲伤", @"path" : @"sad"},
        @{@"name" : @"嘻哈", @"path" : @"xiha"},
        @{@"name" : @"彩虹水平", @"path" : @"rainbow_static"},
        @{@"name" : @"彩虹垂直", @"path" : @"rainbow_animation"}
    ];
    
    NSString *root = [NSBundle.mainBundle pathForResource:@"Resources" ofType:@"bundle"];
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *item in names) {
        MMSegmentItem *tmp = [[MMSegmentItem alloc] init];
        tmp.name = item[@"name"];
        tmp.type = [item[@"path"] length] > 0 ? [root stringByAppendingPathComponent:item[@"path"]] : @"";
        tmp.begin = 0.0;
        tmp.end = 1.0;
        tmp.intensity = 0.0;
        [array addObject:tmp];
    }
    return array.copy;
}

- (NSArray<MMSegmentItem *> *)itemsForBeauty {
    NSArray *beautys = @[
        @{@"name":@"红润",@"type":RUDDY,@"begin":@0, @"end":@1},
        @{@"name":@"美白",@"type":SKIN_WHITENING,@"begin":@0, @"end":@1},
        @{@"name":@"磨皮",@"type":SKIN_SMOOTH,@"begin":@0, @"end":@1},
        @{@"name":@"大眼",@"type":BIG_EYE,@"begin":@0, @"end":@1},
        @{@"name":@"瘦脸",@"type":THIN_FACE,@"begin":@0, @"end":@1},
        @{@"name":@"鼻宽",@"type":NOSE_WIDTH,@"begin":@-1, @"end":@1},
        @{@"name":@"脸宽",@"type":FACE_WIDTH,@"begin":@0, @"end":@1},
        @{@"name":@"削脸",@"type":JAW_SHAPE,@"begin":@-1, @"end":@1},
        @{@"name":@"下巴",@"type":CHIN_LENGTH,@"begin":@-1, @"end":@1},
        @{@"name":@"额头",@"type":FOREHEAD,@"begin":@-1, @"end":@1},
        @{@"name":@"短脸",@"type":SHORTEN_FACE,@"begin":@0, @"end":@1},
        @{@"name":@"祛法令纹",@"type":NASOLABIALFOLDSAREA,@"begin":@0, @"end":@1},
        @{@"name":@"眼睛角度",@"type":EYE_TILT,@"begin":@-1, @"end":@1},
        @{@"name":@"眼距",@"type":EYE_DISTANCE,@"begin":@-1, @"end":@1},
        @{@"name":@"眼袋",@"type":EYESAREA,@"begin":@0, @"end":@1},
        @{@"name":@"眼高",@"type":EYE_HEIGHT,@"begin":@0, @"end":@1},
        @{@"name":@"鼻子大小",@"type":NOSE_SIZE,@"begin":@-1, @"end":@1},
        @{@"name":@"鼻高",@"type":NOSE_LIFT,@"begin":@-1, @"end":@1},
        @{@"name":@"鼻梁",@"type":NOSE_RIDGE_WIDTH,@"begin":@-1, @"end":@1},
        @{@"name":@"鼻尖",@"type":NOSE_TIP_SIZE,@"begin":@-1, @"end":@1},
        @{@"name":@"嘴唇厚度",@"type":LIP_THICKNESS,@"begin":@-1, @"end":@1},
        @{@"name":@"嘴唇大小",@"type":MOUTH_SIZE,@"begin":@-1, @"end":@1},
    ];
    
    NSMutableArray<MMSegmentItem *> *items = [NSMutableArray array];
    for (int i = 0; i < beautys.count; i ++) {
        MMSegmentItem *item = [[MMSegmentItem alloc] init];
        item.name = beautys[i][@"name"];
        item.type = beautys[i][@"type"];
        item.intensity = 0.0;
        item.begin = [beautys[i][@"begin"] floatValue];
        item.end = [beautys[i][@"end"] floatValue];
        [items addObject:item];
    }
    return items.copy;
}

- (NSArray<MMSegmentItem *> *)itemsForLookup {
    NSString *lookupBundlePath = [NSBundle.mainBundle pathForResource:@"Lookup" ofType:@"bundle"];
    
    NSArray *lookup = @[
        @{@"name":@"自然", @"type": @"Natural"},
        @{@"name":@"清新", @"type": @"Fresh"},
        @{@"name":@"红颜", @"type": @"Soulmate"},
        @{@"name":@"日系", @"type": @"SunShine"},
        @{@"name":@"少年", @"type": @"Boyhood"},
        @{@"name":@"白鹭", @"type": @"Egret"},
        @{@"name":@"复古", @"type": @"Retro"},
        @{@"name":@"斯托克", @"type": @"Stoker"},
        @{@"name":@"野餐", @"type": @"Picnic"},
        @{@"name":@"弗洛达", @"type": @"Frida"},
        @{@"name":@"罗马", @"type": @"Rome"},
        @{@"name":@"烧烤", @"type": @"Broil"},
        @{@"name":@"烧烤F2", @"type": @"BroilF2"},
    ];
    
    NSMutableArray<MMSegmentItem *> *items = [NSMutableArray array];
    for (int i = 0; i < lookup.count; i ++) {
        MMSegmentItem *item = [[MMSegmentItem alloc] init];
        item.name = lookup[i][@"name"];
        item.type = [lookupBundlePath stringByAppendingPathComponent: lookup[i][@"type"]];
        item.intensity = 1.0;
        item.begin = 0.0;
        item.end = 1.0;
        [items addObject:item];
    }
    return items.copy;
}

- (UIView *)viewForSwitch:(NSString *)title selectorName:(NSString *)name {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = title;
    label.textColor = UIColor.redColor;
    
    UISwitch *switchBtn = [[UISwitch alloc] init];
    switchBtn.translatesAutoresizingMaskIntoConstraints = NO;
    switchBtn.on = YES;
    [switchBtn addTarget:self action:NSSelectorFromString(name) forControlEvents:UIControlEventValueChanged];
    
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[label, switchBtn]];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.spacing = 8;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.distribution = UIStackViewDistributionFill;
    
    [stackView.widthAnchor constraintEqualToConstant:130].active = YES;
    [stackView.heightAnchor constraintEqualToConstant:40].active = YES;
    
    return stackView;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.camera startCapture];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.camera stopCapture];
    
    [self.agoraKit leaveChannel:^(AgoraChannelStats * _Nonnull stat) {
        NSLog(@"leave");
    }];
}

- (void)camera:(MMAgoraCamera *)camera didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(CMTime)timestamp {
    NSError *error;
    CVPixelBufferRef renderedBuffer = [self.render renderPixelBuffer:pixelBuffer error:&error];
    if (renderedBuffer && !error) {
        AgoraVideoFrame *videoFrame = [[AgoraVideoFrame alloc] init];
        videoFrame.format = 12;
        videoFrame.textureBuf = renderedBuffer;
        videoFrame.time = timestamp;
        videoFrame.rotation = 0;
        
        [self.agoraKit pushExternalVideoFrame:videoFrame];
        
        MTIImage *image = [[MTIImage alloc] initWithCVPixelBuffer:renderedBuffer alphaType:MTIAlphaTypeAlphaIsOne];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.localView.image = image;
        });
    }
}

- (void)flipButtonTapped:(UIButton *)button {
    //    self.render.devicePosition = self.camera.currentPosition;
}

#pragma mark - MMDeviceMotionHandling methods

- (void)handleDeviceMotionOrientation:(UIDeviceOrientation)orientation {
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            self.render.cameraRotate = MMRenderModuleCameraRotate90;
            break;
        case UIDeviceOrientationLandscapeLeft:
            self.render.cameraRotate = MMRenderModuleCameraRotate0;
            break;
        case UIDeviceOrientationLandscapeRight:
            self.render.cameraRotate = MMRenderModuleCameraRotate180;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            self.render.cameraRotate = MMRenderModuleCameraRotate270;
            break;
            
        default:
            break;
    }
}

#pragma mark - AgoraRtcEngineDelegate methods

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurWarning:(AgoraWarningCode)warningCode {
    
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraErrorCode)errorCode {
    
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    AgoraRtcVideoCanvas *canvas = [[AgoraRtcVideoCanvas alloc] init];
    canvas.uid = uid;
    canvas.view = self.remoteView;
    canvas.renderMode = AgoraVideoRenderModeHidden;
    [self.agoraKit setupRemoteVideo:canvas];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraUserOfflineReason)reason {
    AgoraRtcVideoCanvas *canvas = [[AgoraRtcVideoCanvas alloc] init];
    canvas.uid = 0;
    canvas.view = nil;
    canvas.renderMode = AgoraVideoRenderModeHidden;
    [self.agoraKit setupRemoteVideo:canvas];
}

@end
