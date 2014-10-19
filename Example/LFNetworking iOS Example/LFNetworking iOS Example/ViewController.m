//
//  ViewController.m
//  LFNetworking iOS Example
//
//  Created by Wei Zhang on 09/01/14.
//  Copyright (c) 2014 WeiZhang. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ViewController.h"
#import "LFURLSessionManager.h"
#import "LFInstagramAPIClient.h"
#import "LFNetworkProgressCell.h"

/** Simple request object used as the model for my tableview.
 */
@interface Request : NSObject
@property (nonatomic, strong) NSURL *url;
@property (nonatomic) CGFloat progress;
@end

@implementation Request

- (instancetype)initWithURLString:(NSString *)urlString
{
    self = [super init];
    if (self) {
        _url = [NSURL URLWithString:urlString];
        _progress = -1;
    }
    return self;
}

@end

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITextField *clientIdTextField;
@property (nonatomic, strong) UITextField *userNameTextField;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *imageUrlStrings;
@property (nonatomic, strong) NSMutableArray *requests;
@property (nonatomic, strong) NSMutableArray *operations;

@property (nonatomic, strong) LFURLSessionManager *sessionManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.requests = [NSMutableArray array];
    self.sessionManager = [[LFURLSessionManager alloc] init];
    self.operations = [NSMutableArray array];
    self.imageUrlStrings = [NSMutableArray array];
    
    UITextField *clientIdTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 100, 200, 20)];
    clientIdTextField.placeholder = @"Client Id";
    clientIdTextField.borderStyle = UITextBorderStyleLine;
    [self.view addSubview:clientIdTextField];
    
    UITextField *userNameTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 140, 200, 20)];
    userNameTextField.placeholder = @"User";
    userNameTextField.borderStyle = UITextBorderStyleLine;
    [self.view addSubview:userNameTextField];
    
    UIButton *fetchButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    fetchButton.frame = CGRectMake(20, 180, 40, 40);
    [fetchButton addTarget:self action:@selector(fetchUserInfo:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:fetchButton];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 220, self.view.bounds.size.width, 300)];
    tableView.delegate = self;
    tableView.dataSource = self;

    self.tableView = tableView;
    
    [self.view addSubview:tableView];
    
    self.userNameTextField = userNameTextField;
    self.clientIdTextField = clientIdTextField;
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)fetchUserInfo:(UIButton *)sender {
    
    __weak ViewController *weakSelf = self;
    
    [[LFInstagramAPIClient sharedClient] GET:@"users/search" parameters:@{@"q":self.userNameTextField.text, @"client_id":self.clientIdTextField.text} success:^(LFNetworkDataTaskOperation *operation, NSDictionary *jsonDict) {
        
        NSDictionary *dataDict = [jsonDict objectForKey:@"data"];
        
        for (NSDictionary *dict in dataDict) {
            [weakSelf.imageUrlStrings addObject:[dict objectForKey:@"profile_picture"]];
        }
        
        [weakSelf downloadImagesWithUrlStringArray:weakSelf.imageUrlStrings];
        
    } failure:^(LFNetworkDataTaskOperation *operation, NSError *error) {
        
    }];
}

- (void)downloadImagesWithUrlStringArray:(NSArray *)urlStringsArray {
    
    [urlStringsArray enumerateObjectsUsingBlock:^(NSString *urlString, NSUInteger idx, BOOL *stop) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.requests count] inSection:0];
        
        Request *request = [[Request alloc] initWithURLString:urlString];
        [self.requests addObject:request];
        
        NSOperation *operation = [self.sessionManager dataOperationWithURL:request.url progressHandler:^(LFNetworkDataTaskOperation *operation, long long totalBytesExpected, long long bytesReceived) {
            
            // update cell's progress bar as we proceed
            
            float progress;
            if (totalBytesExpected > 0) {
                progress = fmodf((float) bytesReceived / totalBytesExpected, 1.0);
            } else {
                progress = fmodf((float) bytesReceived / 1e6, 1.0);
            }
            request.progress = progress;
            LFNetworkProgressCell *cell = (id)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell.progressView setProgress:progress];
        } completionHandler:^(LFNetworkTaskOperation *operation, NSData *data, NSError *error) {
            
            // indicate that download is done
            
            request.progress = 1.0;
            LFNetworkProgressCell *cell = (id)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell.progressView setProgress:request.progress];
        }];
        
        [self.operations addObject:operation];
        
        if (idx > 4) {
            for (LFNetworkDataTaskOperation *op in self.operations) {
                if ([self.operations indexOfObject:op] < 5) {
                    [operation addDependency:op];
                } else {
                    break;
                }
            }
        }
        
        [self.sessionManager addOperation:operation];
    }];
    
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.imageUrlStrings count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"LFNetworkRequestProgressCell";
    LFNetworkProgressCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[LFNetworkProgressCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    Request *request = self.requests[indexPath.row];
    
    cell.networkRequestLabel.text = [request.url lastPathComponent];
    [cell.progressView setProgress:request.progress];
    
    return cell;
}

@end
