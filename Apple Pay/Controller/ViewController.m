//
//  ViewController.m
//  Apple Pay
//
//  Created by qiuqiu on 2017/5/22.
//  Copyright © 2017年 刘纯. All rights reserved.
//

#import "ViewController.h"
#import <PassKit/PassKit.h>

@interface ViewController () <PKPaymentAuthorizationViewControllerDelegate,UITextFieldDelegate>

//收款页面
@property (weak, nonatomic) IBOutlet UIView *moneyContentView;      //收款页面
@property (weak, nonatomic) IBOutlet UIView *moneyInputView;        //金额输入模块
@property (weak, nonatomic) IBOutlet UITextField *moneyTextField;   //金额输入框
@property (weak, nonatomic) IBOutlet UILabel *moneyLabel;           //显示金额


@end

@implementation ViewController

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:@"UITextFieldTextDidChangeNotification"
                                                 object:self.moneyTextField];
    
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(textFiledEditChanged:)
                                                name:@"UITextFieldTextDidChangeNotification"
                                              object:self.moneyTextField];
    
    [self setupView];
    [self setupData];
}

#pragma makr -初始化
- (void)setupView {
    
    //  设置导航栏颜色
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:62/255.0 green:122/255.0 blue:246/255.0 alpha:1.0];
    self.title = @"Apple Pay";
    
    
    //  添加支付按钮
    PKPaymentButton *applePayButton = [[PKPaymentButton alloc] initWithPaymentButtonType:PKPaymentButtonTypePlain paymentButtonStyle:PKPaymentButtonStyleBlack];
    applePayButton.frame = CGRectMake((CGRectGetWidth(self.view.frame)-280)/2, 250, 280, 50);
    [applePayButton addTarget:self action:@selector(startApplePayAction) forControlEvents:UIControlEventTouchUpInside];
    [self.moneyContentView addSubview:applePayButton];
    
    
    self.moneyTextField.keyboardType = UIKeyboardTypeDecimalPad;
    self.moneyTextField.delegate = self;
    self.moneyTextField.text = @"0.01";
    
    self.moneyInputView.layer.cornerRadius = 6.0f;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
}

- (void)setupData {
    
    self.moneyLabel.text = @"0.01";
}

#pragma  mark - action

//支付
- (void)startApplePayAction {
    
    [self.moneyTextField resignFirstResponder];
    
    NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:self.moneyLabel.text];
    if (!([number compare:@0] == NSOrderedSame)) {
        
        //判断设备是否支持支付
        if([PKPaymentAuthorizationViewController canMakePayments]) {
            
            NSLog(@"支持支付");
            // 我们后面创建出来的支付页面就是根据这个request
            PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
            // 商品目录
            PKPaymentSummaryItem *widget1 = [PKPaymentSummaryItem
                                             summaryItemWithLabel:@"测试支付"
                                             amount:[NSDecimalNumber decimalNumberWithString:self.moneyLabel.text]];
            PKPaymentSummaryItem *widget4 = [PKPaymentSummaryItem
                                             summaryItemWithLabel:@"球球"
                                             amount:[NSDecimalNumber decimalNumberWithString:self.moneyLabel.text]
                                             type:PKPaymentSummaryItemTypeFinal];
            
            request.paymentSummaryItems = @[widget1,widget4];
            request.countryCode = @"CN";
            request.currencyCode = @"CNY";//人民币
            request.supportedNetworks =
            @[
              PKPaymentNetworkChinaUnionPay,
              PKPaymentNetworkMasterCard,
              PKPaymentNetworkVisa
              ];
            
            // 这里填的是就是我们创建的merchat IDs
            request.merchantIdentifier = @"merchant.fish.test.applepay.20170125";
            request.merchantCapabilities = PKMerchantCapability3DS|PKMerchantCapabilityCredit|PKMerchantCapabilityEMV|PKMerchantCapabilityDebit;
            
            //增加邮箱及地址信息
            request.requiredBillingAddressFields = PKAddressFieldEmail | PKAddressFieldPostalAddress;
            
            // 根据request去创建支付页面
            PKPaymentAuthorizationViewController *paymentPane = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];
            
            // 设置代理
            paymentPane.delegate = self;
            
            if (!paymentPane) {
                NSLog(@"出问题了");
            } else {
                // 模态推出页面
                [self presentViewController:paymentPane animated:YES completion:nil];
            }
        } else {
            NSLog(@"该设备不支持支付");
        }
    }
    
}


#pragma mark -PKPaymentAuthorizationViewControllerDelegate
//支付状态
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus  status))completion {
    
    //这里需要通过token去查这笔单
    NSLog(@"花费: %@", payment.token);
    NSString *paymentStr = [[NSString alloc] initWithData:payment.token.paymentData encoding:NSUTF8StringEncoding];
}

//支付完成
- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    // 支付完成后让支付页面消失
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UitextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString * aString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    //  删除数据的时候
    if ([aString isEqualToString:@""]) {
        return YES;
    }
    
    //  防止第一个数据为小数点
    if ([aString isEqualToString:@"."]) {
        return NO;
    }
    
    //  防止间接出现小数点
    if ([[aString substringFromIndex:aString.length-1] isEqualToString:@"."]) {
        if (!([[aString substringToIndex:aString.length-1] rangeOfString:@"."].location == NSNotFound)) {
            return NO;
        }else {
            YES;
        }
    }
    
    //  小数位数
    NSInteger flag = 0;
    if (!(([aString characterAtIndex:aString.length-1] == '.')||([aString characterAtIndex:aString.length-1]<='9' && [aString characterAtIndex:aString.length-1]>='0')))  {
        return NO;
    }
    
    //  判断开头和小数点位数
    for (NSInteger i = aString.length - 1; i >= 0; i--) {
        if (([aString characterAtIndex:i] == '.')||([aString characterAtIndex:i]<='9' && [aString characterAtIndex:i]>='0')) {
            if ([aString characterAtIndex:i] == '.') {
                
                flag = aString.length-1-i;
                //  判断小数位数
                if (flag <= 2) {
                    break;
                }
            }else if (i==1 && [aString characterAtIndex:i-1] == '0') {
                return NO;
            }
        }else {
            return NO;
        }
    }
    
    //  小数位数大于2
    if (flag > 2) {
        return NO;
    }
    return YES;
}

-(void)textFiledEditChanged:(NSNotification *)obj{
    
    UITextField *textField = (UITextField *)obj.object;
    UITextRange *selectedRange = [textField markedTextRange];
    
    //获取高亮部分
    UITextPosition *position = [textField positionFromPosition:selectedRange.start offset:0];
    
    // 没有高亮选择的字，则对已输入的文字进行字数统计和限制
    if (!position) {
        if (textField.text.length == 0) {
            self.moneyLabel.text = @"0.00";
        }else {
            self.moneyLabel.text = [NSString stringWithFormat:@"%@",textField.text];
        }
    }else {
        // 有高亮选择的字符串，则暂不对文字进行统计和限制
    }
}

#pragma mark -
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // 放弃第一响应者
    [self.moneyTextField resignFirstResponder];
}


@end
