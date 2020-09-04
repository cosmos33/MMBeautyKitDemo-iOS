//
//  MMTXViewController.m
//  MMBeautyKitDemo
//
//  Created by sunfei on 2020/9/2.
//  Copyright © 2020 sunfei. All rights reserved.
//

#import "MMTXViewController.h"
#import <CoreVideo/CoreVideo.h>
#import <TXLivePush.h>
#import <TXLiveBase.h>
#import <MetalPetal/MetalPetal.h>
#import "MMDeviceMotionObserver.h"
#import "MMBeautyRender.h"
#import "MMCameraTabSegmentView.h"

@interface MMTXViewController () <TXLivePushListener, TXVideoCustomProcessDelegate, MMDeviceMotionHandling> {
    BOOL                _appIsInActive;
    BOOL                _appIsBackground;
    
    UIView *_localView;
    
    CVOpenGLESTextureRef _texture;
    GLuint _fbo;
}

@property (nonatomic, strong) UIButton *btnPush;
@property (nonatomic, strong) UIButton *btnCamera;
@property (nonatomic, strong) UIButton *btnBeauty;

@property (nonatomic, strong) TXLivePush *pusher;

@property (nonatomic, strong) MTICVPixelBufferPool *pixelBufferPool;
@property (nonatomic, strong) CIContext *ciContext;

@property (nonatomic, strong) MMBeautyRender *render;

@property (nonatomic, strong) MMCameraTabSegmentView *lookupView;
@property (nonatomic, strong) MMCameraTabSegmentView *beautyView;
@property (nonatomic, strong) MMCameraTabSegmentView *stickerView;

@end

@implementation MMTXViewController

- (void)dealloc {
    [self stopPush];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString * const licenceURL = @"http://license.vod2.myqcloud.com/license/v1/ab1c781a4e95be20e2058c279a83d138/TXLiveSDK.licence";
        NSString * const licenceKey = @"110690b331bd72bf92281dce6989c8c3";
        
        //TXLiveBase 位于 "TXLiveBase.h" 头文件中
        [TXLiveBase setLicenceURL:licenceURL key:licenceKey];
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    _pusher = [self createPusher];
    _render = [[MMBeautyRender alloc] init];
    
    [MMDeviceMotionObserver startMotionObserve];
    [MMDeviceMotionObserver addDeviceMotionHandler:self];
    
    [self setupViews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)setupViews {
    self.title = @"腾讯RTMP推流";
    self.view.backgroundColor = UIColor.yellowColor;
    
    UIButton *btnPush = [UIButton buttonWithType:UIButtonTypeCustom];
    btnPush.translatesAutoresizingMaskIntoConstraints = NO;
    [btnPush setTitle:@"推流" forState:UIControlStateNormal];
    [btnPush addTarget:self action:@selector(clickPush:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:@"翻转" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(clickCamera:) forControlEvents:UIControlEventTouchUpInside];
    
    UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:@[@"美颜", @"滤镜", @"贴纸"]];
    control.selectedSegmentIndex = 0;
    control.translatesAutoresizingMaskIntoConstraints = NO;
    [control addTarget:self action:@selector(switchButtonClicked:) forControlEvents:UIControlEventValueChanged];
    
    UIStackView *hStackView = [[UIStackView alloc] initWithArrangedSubviews:@[control, button, btnPush]];
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
    
    segmentView.clickedHander = ^(MMSegmentItem *item) {
        [self.render setLookupPath:item.type];
        [self.render setLookupIntensity:item.intensity];
    };
    
    segmentView.sliderValueChanged = ^(MMSegmentItem *item, CGFloat intensity) {
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
        [self.render setBeautyFactor:item.intensity forKey:item.type];
    };
    
    segmentView2.sliderValueChanged = ^(MMSegmentItem *item, CGFloat intensity) {
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
        NSString *path = item.type;
        if (path.length > 0) {
            [self.render setMaskModelPath:item.type];
        } else {
            [self.render clearSticker];
        }
    };
    
    segmentView3.sliderValueChanged = ^(MMSegmentItem *item, CGFloat intensity) {
    };
    
    _localView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:_localView atIndex:0];
    _localView.center = self.view.center;
}

- (void)switchButtonClicked:(UISegmentedControl *)control {
    self.beautyView.hidden = control.selectedSegmentIndex != 0;
    self.lookupView.hidden = control.selectedSegmentIndex != 1;
    self.stickerView.hidden = control.selectedSegmentIndex != 2;
}

- (NSArray<MMSegmentItem *> *)itemsForSticker {
    NSArray *names = @[
        @{@"name" : @"重置", @"path" : @""},
        @{@"name" : @"rainbow", @"path" : @"rainbow"},
        @{@"name" : @"手控樱花雨", @"path" : @"shoukongyinghua"},
        @{@"name" : @"微笑", @"path" : @"weixiao"},
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
        @{@"name":@"祛法令纹",@"tpe":NASOLABIALFOLDSAREA,@"begin":@0, @"end":@1},
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
        @{@"name":@"宽颔",@"type":JAWWIDTH, @"begin":@-1, @"end":@1},
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

#pragma mark - push

- (TXLivePush *)createPusher {
    TXLivePushConfig *config = [[TXLivePushConfig alloc] init];
    config.pauseFps = 10;
    config.pauseTime = 300;
    config.pauseImg = [UIImage imageNamed:@"pause_publish"];
    config.touchFocus = NO;
    config.enableZoom = NO;
    config.enablePureAudioPush = NO;
    config.enableAudioPreview = NO;
    NSInteger audioQuality = 2;
    switch (audioQuality) {
        case 2:
            // 音乐音质，采样率48000
            config.audioChannels = 2;
            config.audioSampleRate = AUDIO_SAMPLE_RATE_48000;
            break;
        case 1:
            // 标准音质，采样率48000
            config.audioChannels = 1;
            config.audioSampleRate = AUDIO_SAMPLE_RATE_48000;
            break;
        case 0:
            // 语音音质，采样率16000
            config.audioChannels = 1;
            config.audioSampleRate = AUDIO_SAMPLE_RATE_16000;
            break;
        default:
            break;
    }
    config.frontCamera = _btnCamera.tag == 0 ? YES : NO;
    // 推流器初始化
    TXLivePush *pusher = [[TXLivePush alloc] initWithConfig:config];
    [pusher toggleTorch:NO];
    [pusher setMirror:YES];
    [pusher setMute:NO];
    [pusher setVideoQuality:VIDEO_QUALITY_SUPER_DEFINITION adjustBitrate:NO adjustResolution:NO];
    [pusher setVideoProcessDelegate:self];
    
#ifdef ENABLE_CUSTOM_MODE_AUDIO_CAPTURE
    config.enableAEC = NO;
    config.customModeType = CUSTOM_MODE_AUDIO_CAPTURE;
    config.audioSampleRate = CUSTOM_AUDIO_CAPTURE_SAMPLERATE;
    config.audioChannels = CUSTOM_AUDIO_CAPTURE_CHANNEL;
#endif
    
    config.enableHWAcceleration = YES;
    
    config.homeOrientation = HOME_ORIENTATION_DOWN;
    [pusher setRenderRotation:0];

    [pusher setLogViewMargin:UIEdgeInsetsMake(120, 10, 60, 10)];
    [pusher showVideoDebugLog:NO];
    [pusher setEnableClockOverlay:NO];
    
    [pusher setConfig:config];
    
    return pusher;
}

- (void)clickPush:(UIButton *)btn {
    if ([self.pusher isPublishing]) {
        [self stopPush];
        [btn setBackgroundColor:UIColor.greenColor];
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    } else {
        if ([self startPush]) {
            [btn setBackgroundColor:UIColor.redColor];
            [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        } else {
            [self.pusher stopPreview];
        }
    }
}

- (void)clickCamera:(UIButton *)btn {
    [self.pusher switchCamera];
    [self.pusher setMirror:self.pusher.frontCamera];
    [btn setBackgroundColor:self.pusher.frontCamera ? UIColor.redColor : UIColor.greenColor];
}

- (BOOL)startPush {
    NSString *rtmpURL = @"rtmp://172.16.139.16:1935/myapp/sunfei";
    
    AVAuthorizationStatus statusVideo = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (statusVideo == AVAuthorizationStatusDenied) {
        return NO;
    }
    
    // 检查麦克风权限
    AVAuthorizationStatus statusAudio = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (statusAudio == AVAuthorizationStatusDenied) {
        return NO;
    }
    
    [self.pusher setDelegate:self];
    
    [self.pusher startPreview:_localView];
    
    int ret = [_pusher startPush:rtmpURL];
    if (ret != 0) {
        NSLog(@"推流器启动失败");
        return NO;
    }
    
    return YES;
}

- (void)stopPush {
    if (self.pusher) {
        [self.pusher setDelegate:nil];
        [self.pusher stopPreview];
        [self.pusher stopPush];
    }
}

#pragma mark - TXLivePushListener

- (void)onPushEvent:(int)evtID withParam:(NSDictionary *)param {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (evtID == PUSH_ERR_NET_DISCONNECT || evtID == PUSH_ERR_INVALID_ADDRESS) {
            // 断开连接时，模拟点击一次关闭推流
            [self clickPush:self->_btnPush];
            
        } else if (evtID == PUSH_ERR_OPEN_CAMERA_FAIL) {
            [self clickPush:self->_btnPush];
            NSLog(@"获取摄像头权限失败，请前往隐私-相机设置里面打开应用权限");
            
        } else if (evtID == PUSH_EVT_OPEN_CAMERA_SUCC) {
            [self.pusher toggleTorch:NO];
            
        } else if (evtID == PUSH_ERR_OPEN_MIC_FAIL) {
            [self clickPush:self->_btnPush];
            NSLog(@"获取麦克风权限失败，请前往隐私-麦克风设置里面打开应用权限");
            
        } else if (evtID == PUSH_EVT_CONNECT_SUCC) {
            [self.pusher setMute:NO];
            [self.pusher showVideoDebugLog:NO];
            [self.pusher setMirror:self.pusher.frontCamera];
        } else if (evtID == PUSH_WARNING_NET_BUSY) {
            NSLog(@"您当前的网络环境不佳，请尽快更换网络保证正常直播");
        }
        
        // log
        NSLog(@"params = %@", param);
    });
}

- (void)onNetStatus:(NSDictionary *)param {
    NSLog(@"param = %@", param);
}

#pragma mark - TXVideoCustomProcessDelegate methods

- (GLuint)onPreProcessTexture:(GLuint)texture width:(CGFloat)width height:(CGFloat)height {
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (!self.ciContext) {
        self.ciContext = [CIContext contextWithEAGLContext:[EAGLContext currentContext] options:@{(id)kCIContextWorkingColorSpace : (__bridge id)colorSpace}];
    }
    CIImage *image = [CIImage imageWithTexture:texture size:CGSizeMake(width, height) flipped:YES colorSpace:colorSpace];
    CGColorSpaceRelease(colorSpace);
    
    if (!self.pixelBufferPool || self.pixelBufferPool.pixelBufferWidth != width || self.pixelBufferPool.pixelBufferHeight != height) {
        self.pixelBufferPool = [[MTICVPixelBufferPool alloc] initWithPixelBufferWidth:width pixelBufferHeight:height pixelFormatType:kCVPixelFormatType_32BGRA minimumBufferCount:10 error:nil];
    }
    
    CVPixelBufferRef pixelBuffer = [self.pixelBufferPool newPixelBufferWithAllocationThreshold:0 error:nil];
    
    if (@available(iOS 11.0, *)) {
        CIRenderDestination *destination = [[CIRenderDestination alloc] initWithPixelBuffer:pixelBuffer];
        [self.ciContext startTaskToRender:image toDestination:destination error:nil];
    } else {
        [self.ciContext render:image toCVPixelBuffer:pixelBuffer];
    }
    
    CVPixelBufferRef newPixelBuffer = [self.render renderPixelBuffer:pixelBuffer error:nil];
    CVPixelBufferRetain(newPixelBuffer);
    CVPixelBufferRelease(pixelBuffer);
    
    CIImage *renderedImage = [CIImage imageWithCVPixelBuffer:newPixelBuffer];
    
    if (@available(iOS 11.0, *)) {
        renderedImage = [renderedImage imageByApplyingCGOrientation:kCGImagePropertyOrientationDownMirrored];
    } else {
        CGSize size = renderedImage.extent.size;
        CGAffineTransform transform = CGAffineTransformTranslate(CGAffineTransformMakeScale(1.0, -1.0), 0, -size.height);
        renderedImage = [renderedImage imageByApplyingTransform:transform];
    }
    
//    glDeleteTextures(1, &_ret);
//    glGenTextures(1, &_ret);
//    glBindTexture(GL_TEXTURE_2D, _ret);
//
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
//
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    if (!_fbo) {
        glGenFramebuffers(1, &_fbo);
    }
    glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    glViewport(0, 0, width, height);
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.ciContext drawImage:renderedImage inRect:CGRectMake(0, 0, width, height) fromRect:renderedImage.extent];
    
    glFlush();
    CVPixelBufferRelease(newPixelBuffer);

    return texture;
}

- (void)onTextureDestoryed {
    glDeleteFramebuffers(1, &_fbo);
}

#pragma mark - notification methods

- (void)onAppWillResignActive:(NSNotification *)notification {
    _appIsInActive = YES;
    [_pusher pausePush];
}

- (void)onAppDidBecomeActive:(NSNotification *)notification {
    _appIsInActive = NO;
    if (!_appIsBackground && !_appIsInActive) {
        [_pusher resumePush];
    }
}

- (void)onAppDidEnterBackGround:(NSNotification *)notification {
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        
    }];
    _appIsBackground = YES;
    [_pusher pausePush];
}

- (void)onAppWillEnterForeground:(NSNotification *)notification {
    _appIsBackground = NO;
    if (!_appIsBackground && !_appIsInActive) {
        [_pusher resumePush];
    }
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

@end
