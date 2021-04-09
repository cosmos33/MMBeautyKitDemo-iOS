//
//  MMPushViewController.m
//  MMAliBeautyKitDemo
//
//  Created by momo783 on 2021/4/8.
//  Copyright © 2021 sunfei. All rights reserved.
//

#import "MMAliBeautyViewController.h"
#import "MMBeautyRender.h"
#import "MMCameraTabSegmentView.h"
#import "ALLiveConfig.h"
#import "AliLiveEngineMaker.h"
#import <Masonry/Masonry.h>

@import MetalPetal;
@import AVFoundation;

@interface MMAliBeautyViewController ()
<AliLiveDataStatsDelegate, AliLivePushInfoStatusDelegate,AliLiveNetworkDelegate,
AliLiveVidePreProcessDelegate, AliLiveRtsDelegate,
UITextFieldDelegate>
{
    GLuint _fbo;
}

@property (nonatomic, strong) AliLiveRenderView *renderView;
@property (nonatomic, strong) AliLiveConfig *liveConfig;
@property (nonatomic, strong) AliLiveEngine *engine;

@property (nonatomic, assign) BOOL rtmpReconnectFailed;

@property (nonatomic, strong) NSString *pushUrl;
@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, strong) MMBeautyRender *render;

@property (nonatomic, strong) MMCameraTabSegmentView *lookupView;
@property (nonatomic, strong) MMCameraTabSegmentView *beautyView;
@property (nonatomic, strong) MMCameraTabSegmentView *stickerView;

@property (nonatomic, strong) MTICVPixelBufferPool *pixelBufferPool;
@property (nonatomic, strong) MTICVPixelBufferPool *pixelBufferPool2;
//@property (nonatomic, strong) CIContext *ciContext;

@property (nonatomic, strong) MTIContext *renderContext;
@property (nonatomic, strong) CIContext *ciContext;

@end

@implementation MMAliBeautyViewController

- (void)dealloc {
    if (self.engine.isPublishing) {
        [self.engine stopPush];
    }
    if (self.engine.isCameraOn) {
        [self.engine stopPreview];
    }
    [self.engine destorySdk];
    self.engine = nil;
    [[ALLiveConfig sharedInstance] resetLiveConfig];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor blackColor];
    self.renderView = [[AliLiveRenderView alloc] init];
    [self.view addSubview:self.renderView];
    [self.renderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [self setupSearchView];
    [self setupBeautyView];
    [self startPreview];
    
    self.render = [[MMBeautyRender alloc] init];
    self.render.inputType = MMRenderInputTypeStream;
}

// 扫描框
- (void)setupSearchView {
    UIView *searchView = [[UIView alloc] init];
    [self.view addSubview:searchView];
    [searchView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.height.equalTo(@36);
        make.top.equalTo(self.view.mas_top).offset(44);
    }];
    searchView.layer.cornerRadius = 18;
    searchView.layer.masksToBounds = YES;
    searchView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    
    UIButton *scanButton = [[UIButton alloc] init];
    [searchView addSubview:scanButton];
    [scanButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(searchView).offset(18);
        make.centerY.equalTo(searchView);
        make.width.height.equalTo(@20);
    }];
    [scanButton setImage:[UIImage imageNamed:@"camera_push_scan"] forState:UIControlStateNormal];
//    [scanButton addTarget:self action:@selector(scanUrl) forControlEvents:UIControlEventTouchUpInside];
    
    UIView *line = [[UIView alloc] init];
    [searchView addSubview:line];
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(scanButton.mas_right).offset(8);
        make.centerY.equalTo(scanButton);
        make.height.equalTo(@20);
        make.width.equalTo(@1);
    }];
    line.backgroundColor = [UIColor colorWithRed:0.28 green:0.28 blue:0.28 alpha:1.0];
    
    UITextField *textField = [[UITextField alloc] init];
    [searchView addSubview:textField];
    [textField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(line.mas_right).offset(8);
        make.centerY.equalTo(searchView);
        make.top.bottom.right.equalTo(searchView);
    }];
    textField.returnKeyType = UIReturnKeyDone;
    textField.textColor = [UIColor whiteColor];
    textField.delegate = self;
    self.textField = textField;
    [self setupTextField:textField playerholder:@"输入推流url"];
}

- (void)setupTextField:(UITextField *)textField playerholder:(NSString *)playerholder {
    textField.borderStyle = UITextBorderStyleNone;
    textField.font = [UIFont systemFontOfSize:16];
    textField.tintColor = [UIColor whiteColor];
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:playerholder attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:textField.font}];
    textField.attributedPlaceholder = attrString;
}

- (void)flipButtonTapped {
    [self.engine switchCamera];
}

- (void)setupBeautyView {
    self.view.backgroundColor = UIColor.blackColor;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:@"翻转" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(flipButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
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

// 本地预览
- (void)startPreview {
    [[ALLiveConfig sharedInstance] resetRaceBeautyConfig];
    if (self.liveConfig == nil) {
        AliLiveConfig *myConfig = [[AliLiveConfig alloc] init];
        myConfig.videoProfile = AliLiveVideoProfile_540P;
        myConfig.videoFPS = 20;
        myConfig.enablePureAudioPush = false;
        myConfig.beautyOn = NO;
        myConfig.customPreProcessMode |= CUSTOM_MODE_VIDEO_PREPROCESS;
        self.liveConfig = myConfig;
    }
    if (self.engine == nil) {
        self.engine = [AliLiveEngineMaker createEngine:self.liveConfig delegate:self];
        [self.engine setNetworkDelegate:self];
        [self.engine setVidePreProcessDelegate:self];
        [self.engine setDataStatsDelegate:self];
    }
    self.renderView.hidden = NO;
    [self.engine startPreview:self.renderView];
}

// 停止预览
- (void)stopPreview {
    self.renderView.layer.backgroundColor = [[UIColor whiteColor] CGColor];
    [self.engine stopPreview];
    self.renderView.hidden = YES;
}

- (void)stopPublish {
    if (self.engine.isPublishing) {
        [self.engine stopPush];
    }
}

- (void)startPush {
    if (self.pushUrl.length == 0) {
        [self showMessage:@"无效的URL"];
        return;
    }
    [self.engine startPushWithURL:self.pushUrl];
}

- (void)showMessage:(NSString *)message {
    NSLog(@"[Show Message To Console] : %@", message);
}

#pragma mark - Delegate

- (void)onLiveSdkError:(AliLiveEngine *)publisher error:(AliLiveError *)error {
    [self showMessage:@"PushTest"];
}

- (void)onPreviewStarted:(AliLiveEngine *)publisher {
//    [self bottomMenuShouldRefresh:self.menu];
}

- (void)onPreviewStoped:(AliLiveEngine *)publisher {
//    [self bottomMenuShouldRefresh:self.menu];
}

- (void)onLivePushStarted:(AliLiveEngine *)publisher {
//    [self bottomMenuShouldRefresh:self.menu];
}

- (void)onLivePushStoped:(AliLiveEngine *)publisher {
//    [self bottomMenuShouldRefresh:self.menu];
}

- (void)onBGMStateChanged:(AliLiveEngine *)publisher playState:(AliLiveAudioPlayingStateCode)playState errorCode:(AliLiveAudioPlayingErrorCode)errorCode {
    
}


- (void)onFirstVideoFramePreviewed:(AliLiveEngine *)publisher {
    
}


- (void)onLiveSdkWarning:(AliLiveEngine *)publisher warning:(int)warn {
    
}


- (void)didEnterBackground:(NSNotification *)notification {
    [self.engine pausePush];
}

- (void)willEnterForeground:(NSNotification *)notification {
    [self.engine resumePush];
}

#pragma --mark AliLiveNetworkDelegate
- (void)onNetworkStatusChange:(AliLiveEngine *)publisher status:(AliLiveNetworkStatus)netStatus{
    NSString *netStr = nil;
    if(netStatus == AliLiveNetworkStatusNoNetwork)
    {
        netStr = @"无网络";
    }
    else if(netStatus == AliLiveNetworkStatusWiFi)
    {
        netStr = @"网络切换至WiFi";
    }
    else if(netStatus == AliLiveNetworkStatusWWAN)
    {
        netStr = @"网络切换至蜂窝数据";
    }
    [self showMessage:[NSString stringWithFormat:@"网络状态变化:%@",netStr]];
    
    if(netStatus != AliLiveNetworkStatusNoNetwork)
    {
        //重连失败，需要先断开推流再重新推流才可以恢复
        if(self.rtmpReconnectFailed)
        {
            self.rtmpReconnectFailed = NO;
            [self.engine stopPush];
            
            [self.engine startPushWithURL:self.pushUrl];
        }
    }
}

- (void)onNetworkPoor:(AliLiveEngine *)publisher{
    [self showMessage:@"网络差"];
}

- (void)onNetworkRecovery:(AliLiveEngine *)publisher{
    [self showMessage:@"网络恢复"];
}

- (void)onConnectionLost:(AliLiveEngine *)publisher{
    [self showMessage:@"网络连接断开"];
    //重新推流，只有rtc需要重新推流，rtmp模块自己有重连逻辑，不需要重新推流
    if ([self.pushUrl hasPrefix:@"artc://"])
    {
        [self.engine startPushWithURL:self.pushUrl];
    }
}

/**
 * @brief 网络重连开始
 * @param publisher 推流实例对象
 */
- (void)onReconnectStart:(AliLiveEngine *)publisher{
    [self showMessage:@"网络重连开始"];
}

/**
 * @brief 网络重连状态
 * @param publisher 推流实例对象
 * @param success 是否重连成功 YES成功 NO失败
 */
- (void)onReconnectStatus:(AliLiveEngine *)publisher success:(BOOL)success{
    [self showMessage:[NSString stringWithFormat:@"网络重连状态---%@",success?@"成功":@"失败"]];
    if ([self.pushUrl hasPrefix:@"rtmp://"])
    {
        self.rtmpReconnectFailed = !success;
    }
    
}

#pragma --mark AliLiveVidePreProcessDelegate
/**
 * 在OpenGL线程中回调，可以在这里释放创建的OpenGL资源
 */
- (void)onTextureDestoryed{
    //[self showMessage:@"AliLiveVidePreProcessDelegate -> onTextureDestoryed"];
//    glDeleteFramebuffers(1, &_fbo);
}

/**
 * 视频采集对象回调，进行采集图像的二次处理
 * @param pixelBuffer 采集图像
 * @return 返回给SDK的处理的图像
 * @note 若实现了该回调请回调有效的图像，若回调图像为nil，sdk会直接显示原采集图像
 */
- (CVPixelBufferRef)onVideoPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    [self showMessage:@"AliLiveVidePreProcessDelegate -> onVideoPixelBuffer"];
    
    if (pixelBuffer == NULL) {
        return NULL;
    }
    
    NSError *error;
    
    if (!self.renderContext) {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        self.renderContext = [[MTIContext alloc] initWithDevice:device error:&error];
        
    }
    
    if (!self.ciContext) {
        self.ciContext = [CIContext contextWithEAGLContext:[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3]];
    }
    
    int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    OSType pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
    
    if (!self.pixelBufferPool2 || self.pixelBufferPool2.pixelBufferWidth != bufferWidth || self.pixelBufferPool2.pixelBufferHeight != bufferHeight) {
        self.pixelBufferPool2 = [[MTICVPixelBufferPool alloc] initWithPixelBufferWidth:bufferWidth pixelBufferHeight:bufferHeight pixelFormatType:pixelFormat minimumBufferCount:30 error:nil];
    }
    CVPixelBufferRef outputPixelBuffer = NULL;
    
    @autoreleasepool {
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        
        if (!self.pixelBufferPool || self.pixelBufferPool.pixelBufferWidth != bufferWidth || self.pixelBufferPool.pixelBufferHeight != bufferHeight) {
            self.pixelBufferPool = [[MTICVPixelBufferPool alloc] initWithPixelBufferWidth:bufferWidth pixelBufferHeight:bufferHeight pixelFormatType:kCVPixelFormatType_32BGRA minimumBufferCount:30 error:nil];
        }
        
        CVPixelBufferRef beautyPixelBuffer = [self.pixelBufferPool newPixelBufferWithAllocationThreshold:0 error:&error];
        
        if (beautyPixelBuffer == NULL) {
            return nil;
        }
        
        CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer];
        [self.ciContext render:ciImage toCVPixelBuffer:beautyPixelBuffer];
        
        CFAbsoluteTime startRender = CFAbsoluteTimeGetCurrent();
        
        MTIImage *image = [self.render renderToImage:beautyPixelBuffer error:&error];
        CVPixelBufferRelease(beautyPixelBuffer);
        
        if (!image) {
            return nil;
        }
        
        outputPixelBuffer = [self.pixelBufferPool2 newPixelBufferWithAllocationThreshold:0 error:&error];
        
        if (outputPixelBuffer == NULL) {
            return nil;
        }
        
        [self.renderContext renderImage:image toCVPixelBuffer:outputPixelBuffer error:&error];
        
        CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
        NSLog(@"[render] tansform = %.1lf, all = %.1lf", (end - startRender) * 1000, (end - start) * 1000.0);
    }
    
    if (outputPixelBuffer == NULL) {
        return pixelBuffer;
    }
    
    CFAutorelease(outputPixelBuffer);
    return outputPixelBuffer;
}


#pragma markd -统计媒体流相关信息
#pragma mark - AliLiveDataStatsDelegate 回调
/**
 * @brief 实时数据回调(2s触发一次)
 * @param stats stats
 */
- (void)onLiveTotalStats:(AliLiveEngine *)publisher stats:(AliLiveStats *)stats{
    // TODO  LATER
}

/**
 * @brief 本地视频统计信息(2s触发一次)
 * @param localVideoStats 本地视频统计信息
 * @note SDK每两秒触发一次此统计信息回调
 */
- (void)onLiveLocalVideoStats:(AliLiveEngine *)publisher stats:(AliLiveLocalVideoStats *)localVideoStats{
    // TODO
}

/**
 * @brief 远端视频统计信息(2s触发一次)
 * @param remoteVideoStats 远端视频统计信息
 */
- (void)onLiveRemoteVideoStats:(AliLiveEngine *)publisher stats:(AliLiveRemoteVideoStats *)remoteVideoStats{
    // TODO  LATER
}

/**
 * @brief 远端音频统计信息(2s触发一次)
 * @param remoteAudioStats 远端视频统计信息
 */
- (void)onLiveRemoteAudioStats:(AliLiveEngine *)publisher stats:(AliLiveRemoteAudioStats *)remoteAudioStats{
    // TODO  LATER
}

// MARK: - Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *url = textField.text ?:@"";
    if (url.length == 0) {
        [self showMessage:@"无效的URL"];
        return NO;
    }
    self.pushUrl = textField.text ?:@"";
    [self startPush];
    [textField resignFirstResponder];
    return YES;
}

@end
