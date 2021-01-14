//
//  ViewController.m
//  socket_client
//
//  Created by qimac7 on 2021/1/11.
//

#import "ViewController.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

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
@property(nonatomic,strong)NSURL *url;
@property(nonatomic,weak)id<SocketDelegate> delegate;
@end

@implementation ViewController

- (void)viewDidLoad {
     [super viewDidLoad];
    _delegate = self;
    _url = [NSURL URLWithString:[NSString stringWithFormat:@"telnet://127.0.0.1:%i",SOCKETPORT]];
     [_sendBtn addTarget:self action:@selector(sendAction:) forControlEvents:UIControlEventTouchUpInside];
     _backThread = [[NSThread alloc]initWithTarget:self selector:@selector(initSocket:) object:_url];
     [_backThread start];
    // Do any additional setup after loading the view.
}
-(void)sendAction:(UIButton*)sender{
    char sendBuffer[1024];
    strcpy(sendBuffer, "123xy你好");
    NSLog(@"%s",sendBuffer);
   ssize_t result =  send(_socketDescriptionNum,sendBuffer,1024,0);
    NSLog(@"%zi",result);
}
-(void)initSocket:(NSURL *)url{
    int sn = socket(AF_INET, SOCK_STREAM , 0);
    if (sn == -1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate netWorkingDidFaild:@"socket descriptionNum is wrong"];
            return;
        });
        
    }else{
        self->_socketDescriptionNum = sn;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"socketDescriptionNum setted ");
        });
    }
    //通知代理正确开启的socket描述符
    [self.delegate netWorkingDidStart];
    //生成配置socket的结构体，例如ip地址和端口号
    struct sockaddr_in server;
    bzero(&server,sizeof(server));
    server.sin_family = AF_INET;
    server.sin_port = htons([[_url port] integerValue]);
    server.sin_addr.s_addr = inet_addr([[_url host] UTF8String]);
    //连接函数
    if (connect(_socketDescriptionNum, (struct sockaddr*)&server, sizeof(server))== -1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate netWorkingDidFaild:@"something wrong in connection action"];
            return;
        });
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"did connect");
        });
    }
    
    //读取来自服务端的信息
//    while (true) {
//        char buffer[1024];
//        int length = sizeof(buffer);
//        ssize_t readResult = recv(_socketDescriptionNum, &buffer, length, 0);
//        if (readResult > 0) {
//            NSData *data = [NSData dataWithBytes:buffer length:length];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self.delegate netWorkingDidLoad:data];
//            });
//        }
//
//    }
    
    
}
-(void)dealloc{
    close(_socketDescriptionNum);
    [self.delegate netWorkingDidClose];
}
- (void)netWorkingDidClose {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)netWorkingDidFaild:(NSString *)reason {
    NSLog(@"%@:%@",NSStringFromSelector(_cmd),reason);
}

- (void)netWorkingDidLoad:(NSData *)data {
    NSLog(@"%@:%@",NSStringFromSelector(_cmd),[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

- (void)netWorkingDidStart {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)netWorkingLoadComplete {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}



@end
