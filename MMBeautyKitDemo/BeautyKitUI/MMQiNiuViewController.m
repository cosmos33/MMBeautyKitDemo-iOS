//
//  MMQiNiuVontrollerViewController.m
//  MMBeautyKitDemo
//
//  Created by wangxuefei on 2020/9/2.
//  Copyright © 2020 sunfei. All rights reserved.
//

#import "MMQiNiuViewController.h"
#import <PLMediaStreamingKit/PLMediaStreamingKit.h>
#import "MMBeautyRender.h"
#import "MMDeviceMotionObserver.h"
#import "MMBeautyRender.h"
#import "MMCameraTabSegmentView.h"
@interface MMQiNiuViewController ()<PLMediaStreamingSessionDelegate>

@property (nonatomic, strong) PLMediaStreamingSession *session;

@property (nonatomic, strong) MMBeautyRender *render;

@property (nonatomic, strong) MMCameraTabSegmentView *lookupView;
@property (nonatomic, strong) MMCameraTabSegmentView *beautyView;
@property (nonatomic, strong) MMCameraTabSegmentView *stickerView;

@end

@implementation MMQiNiuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [PLStreamingEnv initEnv];
    [self.view addSubview:self.session.previewView];

    [self setupViews];
    // Do any additional setup after loading the view.
}




- (void)updateStream{
    [self.session startStreamingWithPushURL:[NSURL URLWithString:@"rtmp://172.16.139.16:1935/myapp/100"] feedback:^(PLStreamStartStateFeedback feedback) {
        if(feedback == PLStreamStartStateSuccess){
            NSLog(@"succeed %s",__func__);
        }else{
            NSLog(@"error %s",__func__);
        }
    }];
}



- (void)flipButtonTapped:(UIButton*)btn{
    if(self.session.captureDevicePosition == AVCaptureDevicePositionFront){
        self.session.captureDevicePosition = AVCaptureDevicePositionBack;
    }else{
        self.session.captureDevicePosition = AVCaptureDevicePositionFront;
    }
}

#pragma mark - lifestyle
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    [self.session destroy];
}


#pragma mark - 七牛 delegate

- (CVPixelBufferRef __nonnull)mediaStreamingSession:(PLMediaStreamingSession *__nonnull)session cameraSourceDidGetPixelBuffer:(CVPixelBufferRef __nonnull)pixelBuffer timingInfo:(CMSampleTimingInfo)timingInfo{
    if (pixelBuffer) {
        NSError *error = nil;
        CVPixelBufferRef renderedPixelBuffer = [self.render renderPixelBuffer:pixelBuffer error:&error];
        if (!renderedPixelBuffer || error) {
            NSLog(@"error: %@", error);
        } else {
            pixelBuffer = renderedPixelBuffer;
        }
    }
    return pixelBuffer;
}




- (void)updateBtnClick:(UIButton *)btn{
    [self updateStream];
}


- (void)setupViews {
    
    self.session.previewView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.backgroundColor = UIColor.blackColor;
    
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:@"翻转" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(flipButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *updateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    updateBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [updateBtn setTitle:@"推流" forState:UIControlStateNormal];
    [updateBtn addTarget:self action:@selector(updateBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:@[@"美颜", @"滤镜", @"贴纸"]];
    control.selectedSegmentIndex = 0;
    control.translatesAutoresizingMaskIntoConstraints = NO;
    [control addTarget:self action:@selector(switchButtonClicked:) forControlEvents:UIControlEventValueChanged];
    
    UIStackView *hStackView = [[UIStackView alloc] initWithArrangedSubviews:@[control, button,updateBtn]];
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
        [weakself.render setLookupPath:item.type];
        [weakself.render setLookupIntensity:item.intensity];
    };
    
    segmentView.sliderValueChanged = ^(MMSegmentItem *item, CGFloat intensity) {
        [weakself.render setLookupIntensity:intensity];
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
        [weakself.render setBeautyFactor:item.intensity forKey:item.type];
    };
    
    segmentView2.sliderValueChanged = ^(MMSegmentItem *item, CGFloat intensity) {
        [weakself.render setBeautyFactor:intensity forKey:item.type];
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
            [weakself.render setMaskModelPath:item.type];
        } else {
            [weakself.render clearSticker];
        }
    };
    
    segmentView3.sliderValueChanged = ^(MMSegmentItem *item, CGFloat intensity) {
    };
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


#pragma mark - set get

- (PLMediaStreamingSession *)session{
    if(!_session){
       _session = [[PLMediaStreamingSession alloc]initWithVideoCaptureConfiguration:[PLVideoCaptureConfiguration defaultConfiguration] audioCaptureConfiguration:[PLAudioCaptureConfiguration defaultConfiguration] videoStreamingConfiguration:[PLVideoStreamingConfiguration defaultConfiguration] audioStreamingConfiguration:[PLAudioStreamingConfiguration defaultConfiguration] stream:nil];
        _session.delegate = self;
    }
    return _session;
}

- (MMBeautyRender *)render{
    if(!_render){
        _render = [[MMBeautyRender alloc] init];
        _render.inputType = MMRenderInputTypeStream;
    }
    return _render;
}

- (void)dealloc
{
    NSLog(@"%s",__func__);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
