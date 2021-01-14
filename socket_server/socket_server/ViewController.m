//
//  ViewController.m
//  socket_server
//
//  Created by qimac7 on 2021/1/11.
//

#import "ViewController.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#define NOTIFY_MAIN_QUEUE(DES) dispatch_async(dispatch_get_main_queue(), ^{DES;});

#define SOCKETPORT 1456
@protocol SocketDelegate <NSObject>

-(void)netWorkingDidStart;

-(void)netWorkingDidFaild:(NSString *)reason;

-(void)netWorkingDidLoad:(NSData *)data;

-(void)netWorkingDidClose;

-(void)netWorkingLoadComplete;
@end
@interface ViewController ()<SocketDelegate>
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;
@property(nonatomic,assign)int socketDescriptionNum;
@property(nonatomic,strong)NSThread *backThread;
@property(nonatomic,weak) id<SocketDelegate> socketDelegate;
@property(nonatomic,strong)NSURL *url;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //初始化本地url
    _url = [NSURL URLWithString:[NSString stringWithFormat:@"telnet://127.0.0.1:%i",SOCKETPORT]];
    [_sendBtn addTarget:self action:@selector(sendAction:) forControlEvents:UIControlEventTouchUpInside];
    _socketDelegate = self;
    //
    _backThread = [[NSThread alloc]initWithTarget:self selector:@selector(initSocket:) object:_url];
    //
    [_backThread start];
    // Do any additional setup after loading the view.
}
-(void)initSocket:(NSURL *)url{
    //内核产生一个socket描述符用于socket通信，选择TCP
    _socketDescriptionNum = socket(AF_INET, SOCK_STREAM, 0);
    //socket描述符生成失败
    if(_socketDescriptionNum == -1){
        NOTIFY_MAIN_QUEUE([self.socketDelegate netWorkingDidFaild:@"something wrong occured when initialize socketDescription"])
        return;
    }
    //通知代理
    NOTIFY_MAIN_QUEUE([self.socketDelegate netWorkingDidStart])
    //生成配置socket的结构体，例如ip地址和端口号
    struct sockaddr_in server;
    bzero(&server,sizeof(server));
    server.sin_family = AF_INET;
    server.sin_port = htons([[url port] integerValue]);
    server.sin_addr.s_addr = inet_addr([[_url host] UTF8String]);
    //绑定相关socke的配置
    int bindResult = bind(_socketDescriptionNum, (struct sockaddr *)&server, sizeof(server));
    if(bindResult == -1)
    {
        NOTIFY_MAIN_QUEUE([self.socketDelegate netWorkingDidFaild:@"something wrong when binding socket configuration"])
        return;
    }
    //监听端口,第二个参数代表的是连接数
    int listenResult = listen(_socketDescriptionNum, 5);
    if (listenResult == -1) {
       NOTIFY_MAIN_QUEUE( [self.socketDelegate netWorkingDidFaild:@"listen Socket failed"])
        return;
    }
    struct sockaddr_in client_address;
    socklen_t address_len;
    //socket接收,返回三个值
    /**
     （1）：accept()函数的返回值，已连接套接字描述符；
     （2）：client参数参会客户端的协议地址，包括IP地址和端口号等；
     （3）：addrlen参数返回客户端地址结构的大小。
     */
    int acceptanceResult = accept(_socketDescriptionNum, (struct sockaddr *)&client_address, &address_len);
    
    if (acceptanceResult == -1) {
        NOTIFY_MAIN_QUEUE([self.socketDelegate netWorkingDidFaild:@"something wrong in accept function"])
        return;
    }else{
        self->_socketDescriptionNum = acceptanceResult;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"acceptance done");
        });
    }
    //在这个线程当中一直循环负责TCP接收数据，但是这是个子线程，所以不会出现卡顿主线程的情况
    while (true)
    {
         char buffer[1024];
         ssize_t sendedCount = recv(_socketDescriptionNum, (void *)buffer, 1024, 0);
         if(sendedCount>0){
             int length = sizeof(buffer);
            NSData *data = [NSData dataWithBytes:buffer length:length];
            NOTIFY_MAIN_QUEUE([self.socketDelegate netWorkingDidLoad:data])
         }
        
    }
    
}

-(void)sendAction:(UIButton*)sender{
    char send[1024];
    strcpy(send, "服务端");
}

-(void)dealloc{
    close(_socketDescriptionNum);
    [self.socketDelegate netWorkingDidClose];
}
-(void)netWorkingDidFaild:(NSString *)reason {
    NSLog(@"%@:%@",NSStringFromSelector(_cmd),reason);
}

-(void)netWorkingDidLoad:(NSData *)data {
    /**
//
//     NSNEXTSTEPStringEncoding = 2,
//     NSJapaneseEUCStringEncoding = 3,
//     NSUTF8StringEncoding = 4,
//     NSISOLatin1StringEncoding = 5,
//     NSSymbolStringEncoding = 6,
//     NSNonLossyASCIIStringEncoding = 7,
//     NSShiftJISStringEncoding = 8,          /* kCFStringEncodingDOSJapanese */
//     NSISOLatin2StringEncoding = 9,
//     NSUnicodeStringEncoding = 10,
//     NSWindowsCP1251StringEncoding = 11,
//     NSWindowsCP1252StringEncoding = 12,
//     NSWindowsCP1253StringEncoding = 13,    /* Greek */
//     NSWindowsCP1254StringEncoding = 14,    /* Turkish */
//     NSWindowsCP1250StringEncoding = 15,    /* WinLatin2 */
//     NSISO2022JPStringEncoding = 21,        /* ISO 2022 Japanese encoding for e-mail */
//     NSMacOSRomanStringEncoding = 30,
//
//     NSUTF16StringEncoding = NSUnicodeStringEncoding,      /* An alias for NSUnicodeStringEncoding */
//
//     NSUTF16BigEndianStringEncoding = 0x90000100,          /* NSUTF16StringEncoding encoding with explicit endianness specified */
//     NSUTF16LittleEndianStringEncoding = 0x94000100,       /* NSUTF16StringEncoding encoding with explicit endianness specified */
//
//     NSUTF32StringEncoding = 0x8c000100,
//     NSUTF32BigEndianStringEncoding = 0x98000100,          /* NSUTF32StringEncoding encoding with explicit endianness specified */
//     NSUTF32LittleEndianStringEncoding = 0x9c000100
//     */
    NSLog(@"%@",NSStringFromSelector(_cmd));
    char cString[1024];
    [data getBytes:(void *)cString length:1024];
    NSLog(@"%@",[NSString stringWithUTF8String:cString]);
   
}

-(void)netWorkingDidStart {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

-(void)netWorkingLoadComplete {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

-(void)netWorkingDidClose {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

@end
