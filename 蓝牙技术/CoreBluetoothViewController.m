//
//  CoreBluetoothViewController.m
//  蓝牙技术
//
//  Created by 谭彪 on 2017/10/19.
//  Copyright © 2017年 谭彪. All rights reserved.
//

#import "CoreBluetoothViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

static NSString *const kCharacteristicUUID = @"CCE62C0F-1098-4CD0-ADFA-C8FC7EA2EE90";

static NSString *const kServiceUUID = @"50BD367B-6B17-4E81-B6E9-F62016F26E7B";

@interface CoreBluetoothViewController ()<CBCentralManagerDelegate, CBPeripheralDelegate>

/*中心管理者*/
@property (nonatomic, strong) CBCentralManager *cMgr;

@property(nonatomic,strong) CBPeripheralManager *periMgr;
 
/*连接到的外设*/
@property (nonatomic, strong) CBPeripheral *peripheral;

@property(nonatomic,strong) CBCharacteristic *characteristic;


@property (weak, nonatomic) IBOutlet UITextField *sendTextF;

@property (weak, nonatomic) IBOutlet UITextField *readTextF;


@end

@implementation CoreBluetoothViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
  
    self.cMgr = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];;
}


//向外围设备发送数据
- (IBAction)sendData:(UIButton *)sender
{
    
    [self.view endEditing:YES];
    // 用NSData类型来写入
    NSLog(@"sendText==============%@",self.sendTextF.text);
    NSData *data = [self.sendTextF.text dataUsingEncoding:NSUTF8StringEncoding];
    // 根据上面的特征self.characteristic来写入数据
    [self.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];

}

//从外围设备读取数据
- (IBAction)readData:(UIButton *)sender
{
  
    
    
}

//只要中心管理者初始化 就会触发此代理方法 判断手机蓝牙状态
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case 0:
            NSLog(@"CBCentralManagerStateUnknown");
            break;
        case 1:
            NSLog(@"CBCentralManagerStateResetting");
            break;
        case 2:
            NSLog(@"CBCentralManagerStateUnsupported");//不支持蓝牙
            break;
        case 3:
            NSLog(@"CBCentralManagerStateUnauthorized");
            break;
        case 4:
        {
            NSLog(@"CBCentralManagerStatePoweredOff");//蓝牙未开启
        }
            break;
        case 5:
        {
            NSLog(@"CBCentralManagerStatePoweredOn");//蓝牙已开启
            // 在中心管理者成功开启后再进行一些操作
            // 搜索外设
            [central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"CDD1"]] options:nil];
        }
            break;
        default:
            break;
    }
}


// 发现外设后调用的方法
- (void)centralManager:(CBCentralManager *)central // 中心管理者
 didDiscoverPeripheral:(CBPeripheral *)peripheral // 外设
     advertisementData:(NSDictionary *)advertisementData // 外设携带的数据
                  RSSI:(NSNumber *)RSSI // 外设发出的蓝牙信号强度
{
    NSLog(@"外围设备:%@",peripheral.name);
    
    if (peripheral)
    {
        self.peripheral = peripheral;
        self.peripheral.delegate = self;
        // NSMutableDictionary *options = @[@"tanbiao":@"测试使用"];
        [self.cMgr connectPeripheral:peripheral options:nil];
    }

}

// 中心管理者连接外设成功
- (void)centralManager:(CBCentralManager *)central // 中心管理者
  didConnectPeripheral:(CBPeripheral *)peripheral // 外设
{
    NSLog(@"%s, line = %d, %@=连接成功", __FUNCTION__, __LINE__, peripheral.name);
    // 连接成功之后,可以进行服务和特征的发现
    [self.cMgr stopScan];
    
    self.peripheral.delegate = self;

    [self.peripheral discoverServices:@[[CBUUID UUIDWithString:@"CDD1"]]];
}

#pragma mark - CBPeripheralDelegate

/** 发现服务 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    // 遍历出外设中所有的服务
    for (CBService *service in peripheral.services)
    {
        NSLog(@"所有的服务：%@",service);
    }
    
    // 这里仅有一个服务，所以直接获取
    CBService *service = peripheral.services.lastObject;
    
    // 根据UUID寻找服务中的特征
    if (service)
    {
         [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:@"CDD2"]] forService:service];
    }
   
}

-(void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices
{
    NSLog(@"设备名字:%@",peripheral.name);
    
    for (CBService *service in invalidatedServices)
    {
        NSLog(@"service:%@",service);
    }

}
/** 发现特征回调 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    // 遍历出所需要的特征
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        NSLog(@"所有特征：%@", characteristic);
        // 从外设开发人员那里拿到不同特征的UUID，不同特征做不同事情，比如有读取数据的特征，也有写入数据的特征
    }
    
    // 这里只获取一个特征，写入数据的时候需要用到这个特征
    self.characteristic = service.characteristics.lastObject;
    
    // 直接读取这个特征数据，会调用didUpdateValueForCharacteristic
    [peripheral readValueForCharacteristic:self.characteristic];
    
    // 订阅通知
    [peripheral setNotifyValue:YES forCharacteristic:self.characteristic];
}

/** 订阅状态的改变 */
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"订阅失败");
        NSLog(@"%@",error);
    }
    if (characteristic.isNotifying)
    {
        
        
        NSLog(@"订阅成功,可以通信了");
        
    } else
    {
        NSLog(@"取消订阅");
    }
}

/** 接收到数据回调 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // 拿到外设发送过来的数据
    NSData *data = characteristic.value;
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"text===================%@",text);
    self.readTextF.text = text;
}

/** 写入数据回调 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSLog(@"写入成功");
}


-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];

}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}



@end
