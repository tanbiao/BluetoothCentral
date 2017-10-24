//
//  ViewController.m
//  蓝牙技术
//
//  Created by 谭彪 on 2017/10/19.
//  Copyright © 2017年 谭彪. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "CoreBluetoothViewController.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
}


- (IBAction)jumpBluetooch:(UIButton *)sender
{

    CoreBluetoothViewController *bluetooth = [[CoreBluetoothViewController alloc] init];
    
    [self.navigationController pushViewController:bluetooth animated:YES];
    
}


@end
