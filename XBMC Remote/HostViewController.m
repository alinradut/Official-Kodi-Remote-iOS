//
//  HostViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 14/4/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "HostViewController.h"
#import "AppDelegate.h"
#include <arpa/inet.h>
#if (TARGET_IPHONE_SIMULATOR)
#import <net/if_types.h>
#import "route.h"
#import "if_ether.h"
#else
#import "if_types.h"
#import "route.h"
#import "if_ether.h"
#endif

#import <sys/socket.h>
#import <sys/sysctl.h>
#import <ifaddrs.h>
#import <net/if_dl.h>
#import <net/if.h>
#import <netinet/in.h>
#import "Utilities.h"

#define serviceType @"_xbmc-jsonrpc-h._tcp"
#define domainName @"local"
#define DISCOVER_TIMEOUT 15.0
#define BUFLEN (sizeof(struct rt_msghdr) + 512)
#define SEQ 9999
#define RTM_VERSION	5           // important, version 2 does not return a mac address!
#define RTM_GET	0x4             // Report Metrics
#define RTF_LLINFO	0x400       // generated by link layer (e.g. ARP)
#define RTF_IFSCOPE 0x1000000   // has valid interface scope
#define RTA_DST	0x1             // destination sockaddr present


@implementation HostViewController

@synthesize detailItem = _detailItem;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)configureView {
    if (self.detailItem == nil) {
        self.navigationItem.title = LOCALIZED_STR(@"New XBMC Server");
    }
    else {
        self.navigationItem.title = LOCALIZED_STR(@"Modify XBMC Server");
        NSIndexPath *idx = self.detailItem;
        descriptionUI.text = AppDelegate.instance.arrayServerList[idx.row][@"serverDescription"];
        usernameUI.text = AppDelegate.instance.arrayServerList[idx.row][@"serverUser"];
        passwordUI.text = AppDelegate.instance.arrayServerList[idx.row][@"serverPass"];
        ipUI.text = AppDelegate.instance.arrayServerList[idx.row][@"serverIP"];
        portUI.text = AppDelegate.instance.arrayServerList[idx.row][@"serverPort"];
        NSString *macAddress = AppDelegate.instance.arrayServerList[idx.row][@"serverMacAddress"];
        NSArray *mac_octect = [macAddress componentsSeparatedByString:@":"];
        NSInteger num_octects = mac_octect.count;
        if (num_octects > 0) {
            mac_0_UI.text = mac_octect[0];
        }
        if (num_octects > 1) {
            mac_1_UI.text = mac_octect[1];
        }
        if (num_octects > 2) {
            mac_2_UI.text = mac_octect[2];
        }
        if (num_octects > 3) {
            mac_3_UI.text = mac_octect[3];
        }
        if (num_octects > 4) {
            mac_4_UI.text = mac_octect[4];
        }
        if (num_octects > 5) {
            mac_5_UI.text = mac_octect[5];
        }
        tcpPortUI.text = AppDelegate.instance.arrayServerList[idx.row][@"tcpPort"];
    }
}

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
    }
}

- (IBAction) dismissView:(id)sender {
    
    [self textFieldDoneEditing:nil];
    
    if (descriptionUI.text == nil) {
        descriptionUI.text = @"";
    }
    if (usernameUI.text == nil) {
        usernameUI.text = @"";
    }
    if (passwordUI.text == nil) {
        passwordUI.text = @"";
    }
    if (ipUI.text == nil) {
        ipUI.text = @"";
    }
    if (portUI.text == nil) {
        portUI.text = @"";
    }
    if (tcpPortUI.text == nil) {
        tcpPortUI.text = @"";
    }
    if (mac_0_UI.text == nil) {
        mac_0_UI.text = @"";
    }
    if (mac_1_UI.text == nil) {
        mac_1_UI.text = @"";
    }
    if (mac_2_UI.text == nil) {
        mac_2_UI.text = @"";
    }
    if (mac_3_UI.text == nil) {
        mac_3_UI.text = @"";
    }
    if (mac_4_UI.text == nil) {
        mac_4_UI.text = @"";
    }
    if (mac_5_UI.text == nil) {
        mac_5_UI.text = @"";
    }

    NSString *macAddress = [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@", mac_0_UI.text, mac_1_UI.text, mac_2_UI.text, mac_3_UI.text, mac_4_UI.text, mac_5_UI.text];
    if (self.detailItem == nil) {
        [AppDelegate.instance.arrayServerList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           descriptionUI.text, @"serverDescription",
                                                           usernameUI.text, @"serverUser",
                                                           passwordUI.text, @"serverPass",
                                                           ipUI.text, @"serverIP",
                                                           portUI.text, @"serverPort",
                                                           macAddress, @"serverMacAddress",
                                                           tcpPortUI.text, @"tcpPort",
                                                           nil
                                                           ]];
    }
    else {
        NSIndexPath *idx = self.detailItem;
        [AppDelegate.instance.arrayServerList removeObjectAtIndex:idx.row];
        [AppDelegate.instance.arrayServerList insertObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              descriptionUI.text, @"serverDescription",
                                                              usernameUI.text, @"serverUser",
                                                              passwordUI.text, @"serverPass",
                                                              ipUI.text, @"serverIP",
                                                              portUI.text, @"serverPort",
                                                              macAddress, @"serverMacAddress",
                                                              tcpPortUI.text, @"tcpPort",
                                                              nil
                                                              ] atIndex:idx.row];
    }
    [AppDelegate.instance saveServerList];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Helper

- (void)tailorViewContent:(BOOL)isEditing {
    if (isEditing) {
        if (IS_IPAD && IS_LANDSCAPE) {
            tipView.hidden = YES;
        }
        else {
            tipView.hidden = NO;
        }
    }
    else {
        tipView.hidden = NO;
    }
}

#pragma mark - UITextFieldDelegate Methods

- (void)textFieldDidBeginEditing:(UITextField*)textField {
    textField.textColor = [Utilities get1stLabelColor];
    [self tailorViewContent:YES];
}

- (void)resignKeyboard {
    [descriptionUI resignFirstResponder];
    [ipUI resignFirstResponder];
    [portUI resignFirstResponder];
    [tcpPortUI resignFirstResponder];
    [usernameUI resignFirstResponder];
    [mac_0_UI resignFirstResponder];
    [mac_1_UI resignFirstResponder];
    [mac_2_UI resignFirstResponder];
    [mac_3_UI resignFirstResponder];
    [mac_4_UI resignFirstResponder];
    [mac_5_UI resignFirstResponder];
    [passwordUI resignFirstResponder];
    [self tailorViewContent:NO];
}

- (BOOL)textFieldShouldReturn:(UITextField*)theTextField {
    if (theTextField.tag < 12) {
        UITextField *next = (UITextField*)[self.view viewWithTag:theTextField.tag + 1];
        [next becomeFirstResponder];
        //[next selectAll:self];
        return NO;
    }
    else {
        [self resignKeyboard];
        [theTextField resignFirstResponder];
        return YES;
    }
}

- (IBAction)textFieldDoneEditing:(id)sender {
    [self resignKeyboard];
}

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
    NSUInteger newLength = textField.text.length + string.length - range.length;
    return (newLength > 2 && textField.tag >= 5 && textField.tag <= 10) ? NO : YES;
}

# pragma mark - Gestures

- (void)handleSwipeFromRight:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


# pragma mark - NSNetServiceBrowserDelegate Methods

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser*)browser {
    searching = YES;
    [self updateUI];
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser*)browser {
    searching = NO;
    [self updateUI];
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)browser didNotSearch:(NSDictionary*)errorDict {
    searching = NO;
    [self handleError:errorDict[NSNetServicesErrorCode]];
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)browser
           didFindService:(NSNetService*)aNetService
               moreComing:(BOOL)moreComing {
    [services addObject:aNetService];
    if (!moreComing) {
        [self stopDiscovery];
        [self updateUI];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)browser
         didRemoveService:(NSNetService*)aNetService
               moreComing:(BOOL)moreComing {
    [services removeObject:aNetService];
    if (!moreComing) {
        [self updateUI];
    }
}

- (void)handleError:(NSNumber*)error {
//    NSLog(@"An error occurred. Error code = %d", [error intValue]);
    // Handle error here
}

- (void)updateUI {
    if (!searching) {
        NSInteger j = services.count;
        if (j == 1) {
            [self resolveIPAddress:services[0]];
        }
        else {
            if (j == 0) {
                [Utilities AnimLabel:noInstances AnimDuration:0.3 Alpha:1.0 XPos:0];
            }
            else {
                [discoveredInstancesTableView reloadData];
                [Utilities AnimView:discoveredInstancesView AnimDuration:0.3 Alpha:1.0 XPos:0];
            }
        }
    }
}

#pragma mark - resolveMacAddress Methods

- (NSString*)resolveMacFromIP:(NSString*)ipAddress {
    NSString* res = nil;
    
    in_addr_t host = inet_addr([ipAddress UTF8String]);
    int sockfd;
    unsigned char buf[BUFLEN];
    unsigned char buf2[BUFLEN];
    ssize_t n;
    struct rt_msghdr *rtm;
    struct sockaddr_in *sin;
    
    memset(buf, 0, sizeof(buf));
    memset(buf2, 0, sizeof(buf2));
    
    sockfd = socket(AF_ROUTE, SOCK_RAW, 0);
    rtm = (struct rt_msghdr*)buf;
    rtm->rtm_msglen = sizeof(struct rt_msghdr) + sizeof(struct sockaddr_in);
    rtm->rtm_version = RTM_VERSION;
    rtm->rtm_type = RTM_GET;
    rtm->rtm_addrs = RTA_DST;
    rtm->rtm_flags = RTF_LLINFO;
    rtm->rtm_pid = 1234;
    rtm->rtm_seq = SEQ;
    
    sin = (struct sockaddr_in*)(rtm + 1);
    sin->sin_len = sizeof(struct sockaddr_in);
    sin->sin_family = AF_INET;
    sin->sin_addr.s_addr = host;
    write(sockfd, rtm, rtm->rtm_msglen);
    
    n = read(sockfd, buf2, BUFLEN);
    if (n != 0) {
        int index = sizeof(struct rt_msghdr) + sizeof(struct sockaddr_inarp) + 8;
        res = [NSString stringWithFormat:@"%2.2X:%2.2X:%2.2X:%2.2X:%2.2X:%2.2X",
               buf2[index+0], buf2[index+1], buf2[index+2], buf2[index+3], buf2[index+4], buf2[index+5]];
    }
    
    return res;
}

- (void)fillMacAddressInfo {
    NSString *macAddress = [self resolveMacFromIP:ipUI.text];
    NSArray *macPart = [macAddress componentsSeparatedByString:@":"];
    if (macPart.count == 6 && ![macAddress isEqualToString:@"02:00:00:00:00:00"]) {
        mac_0_UI.text = macPart[0];
        mac_0_UI.textColor = [Utilities getSystemBlue];
        mac_1_UI.text = macPart[1];
        mac_1_UI.textColor = [Utilities getSystemBlue];
        mac_2_UI.text = macPart[2];
        mac_2_UI.textColor = [Utilities getSystemBlue];
        mac_3_UI.text = macPart[3];
        mac_3_UI.textColor = [Utilities getSystemBlue];
        mac_4_UI.text = macPart[4];
        mac_4_UI.textColor = [Utilities getSystemBlue];
        mac_5_UI.text = macPart[5];
        mac_5_UI.textColor = [Utilities getSystemBlue];
    }
}

# pragma mark - resolveIPAddress Methods

- (void)resolveIPAddress:(NSNetService*)service {
    NSNetService *remoteService = service;
    remoteService.delegate = self;
    [remoteService resolveWithTimeout:0];
}

- (void)netServiceDidResolveAddress:(NSNetService*)service {

    for (NSData* data in [service addresses]) {
        char addressBuffer[100];
        struct sockaddr_in* socketAddress = (struct sockaddr_in*)[data bytes];
        int sockFamily = socketAddress->sin_family;
        if (sockFamily == AF_INET) {//|| sockFamily == AF_INET6 should be considered
            const char* addressStr = inet_ntop(sockFamily,
                                               &(socketAddress->sin_addr), addressBuffer,
                                               sizeof(addressBuffer));
            int port = ntohs(socketAddress->sin_port);
            if (addressStr && port) {
                descriptionUI.text = service.name;
                ipUI.text = [NSString stringWithFormat:@"%s", addressStr];
                portUI.text = [NSString stringWithFormat:@"%d", port];
                descriptionUI.textColor = [Utilities getSystemBlue];
                ipUI.textColor = [Utilities getSystemBlue];
                portUI.textColor = [Utilities getSystemBlue];
                NSString *serverJSON = [NSString stringWithFormat:@"http://%@:%@/jsonrpc", ipUI.text, portUI.text];
                NSURL *url = [[NSURL alloc] initWithString:serverJSON];
                NSURLSession *pingSession = [NSURLSession sharedSession];
                NSURLSessionDataTask *pingConnection = [pingSession dataTaskWithURL:url];
                [pingConnection resume];
                [Utilities AnimView:discoveredInstancesView AnimDuration:0.3 Alpha:1.0 XPos:self.view.frame.size.width];
            }
        }
    }
}

- (void)stopDiscovery {
    [netServiceBrowser stop];
    [activityIndicatorView stopAnimating];
    startDiscover.enabled = YES;
}

- (IBAction)startDiscover:(id)sender {
    [self resignKeyboard];
    [activityIndicatorView startAnimating];
    [services removeAllObjects];
    startDiscover.enabled = NO;
    [Utilities AnimLabel:noInstances AnimDuration:0.3 Alpha:0.0 XPos:self.view.frame.size.width];
    [Utilities AnimView:discoveredInstancesView AnimDuration:0.3 Alpha:1.0 XPos:self.view.frame.size.width];

    searching = NO;
    netServiceBrowser.delegate = self;
    [netServiceBrowser searchForServicesOfType:serviceType inDomain:domainName];
    timer = [NSTimer scheduledTimerWithTimeInterval:DISCOVER_TIMEOUT target:self selector:@selector(stopDiscovery) userInfo:nil repeats:NO];
}

#pragma mark - TableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	return services.count;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	static NSString *tableCellIdentifier = @"UITableViewCell";
	UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableCellIdentifier];
	}
	
	NSUInteger count = services.count;
	if (count == 0) {
		return cell;
	}
    NSNetService* service = services[indexPath.row];
	cell.textLabel.text = service.name;
	cell.textLabel.textColor = [Utilities get1stLabelColor];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [self resolveIPAddress:services[indexPath.row]];
}

#pragma mark - NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection*)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge {
    [self fillMacAddressInfo];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    [self fillMacAddressInfo];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    [self fillMacAddressInfo];
}

#pragma mark - LifeCycle

- (void)viewWillAppear:(BOOL)animated {
    CGSize size = CGSizeMake(320, 380);
    self.preferredContentSize = size;
    [super viewWillAppear:animated];
    [self configureView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    services = [NSMutableArray new];
    netServiceBrowser = [NSNetServiceBrowser new];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [timer invalidate];
    timer = nil;
    netServiceBrowser = nil;
    services = nil;
    [Utilities AnimView:discoveredInstancesView AnimDuration:0.0 Alpha:1.0 XPos:self.view.frame.size.width];
    descriptionUI.text = @"";
    usernameUI.text = @"";
    passwordUI.text = @"";
    ipUI.text = @"";
    portUI.text = @"";
    mac_0_UI.text = @"";
    mac_1_UI.text = @"";
    mac_2_UI.text = @"";
    mac_3_UI.text = @"";
    mac_4_UI.text = @"";
    mac_5_UI.text = @"";
    descriptionUI.textColor = [Utilities get1stLabelColor];
    ipUI.textColor = [Utilities get1stLabelColor];
    portUI.textColor = [Utilities get1stLabelColor];
    mac_0_UI.textColor = [Utilities get1stLabelColor];
    mac_1_UI.textColor = [Utilities get1stLabelColor];
    mac_2_UI.textColor = [Utilities get1stLabelColor];
    mac_3_UI.textColor = [Utilities get1stLabelColor];
    mac_4_UI.textColor = [Utilities get1stLabelColor];
    mac_5_UI.textColor = [Utilities get1stLabelColor];
    [Utilities AnimLabel:noInstances AnimDuration:0.0 Alpha:0.0 XPos:self.view.frame.size.width];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    descriptionLabel.text = LOCALIZED_STR(@"Description");
    hostLabel.text = LOCALIZED_STR(@"Host : port /\nTCP port");
    macLabel.text = LOCALIZED_STR(@"MAC Address");
    userLabel.text = LOCALIZED_STR(@"Username and Password");
    noInstancesLabel.text = LOCALIZED_STR(@"No XBMC instances were found :(");
    findLabel.text = LOCALIZED_STR(@"\"Find XBMC\" requires XBMC server option\n\"Announce these services to other systems via Zeroconf\" enabled");
    howtoLabel.text = LOCALIZED_STR(@"How-to activate the remote app in Kodi");
    howtoLaterLabel.text = LOCALIZED_STR(@"Settings > Services > Control:\n1. Web Server > Allow remote control via HTTP\n2. Application Control > Allow remote control from applications on other systems");
    
    [saveButton setTitle:LOCALIZED_STR(@"Save") forState:UIControlStateNormal];
    [startDiscover setTitle:LOCALIZED_STR(@"Find XBMC") forState:UIControlStateNormal];
    startDiscover.titleLabel.numberOfLines = 1;
    startDiscover.titleLabel.adjustsFontSizeToFitWidth = YES;
    startDiscover.titleLabel.lineBreakMode = NSLineBreakByClipping;
    
    UIImage *img = [UIImage imageNamed:@"button_find"];
    img = [Utilities colorizeImage:img withColor:[Utilities getSystemBlue]];
    [saveButton setBackgroundImage:img forState:UIControlStateNormal];
    [startDiscover setBackgroundImage:img forState:UIControlStateNormal];
    
    descriptionUI.placeholder = LOCALIZED_STR(@"e.g. My XBMC");
    ipUI.placeholder = LOCALIZED_STR(@"e.g. 192.168.0.8");
    usernameUI.placeholder = LOCALIZED_STR(@"Username");
    passwordUI.placeholder = LOCALIZED_STR(@"Password");
    self.edgesForExtendedLayout = 0;
    descriptionUI.backgroundColor = [Utilities getSystemGray6];
    ipUI.backgroundColor = [Utilities getSystemGray6];
    portUI.backgroundColor = [Utilities getSystemGray6];
    tcpPortUI.backgroundColor = [Utilities getSystemGray6];
    usernameUI.backgroundColor = [Utilities getSystemGray6];
    passwordUI.backgroundColor = [Utilities getSystemGray6];
    mac_0_UI.backgroundColor = [Utilities getSystemGray6];
    mac_1_UI.backgroundColor = [Utilities getSystemGray6];
    mac_2_UI.backgroundColor = [Utilities getSystemGray6];
    mac_3_UI.backgroundColor = [Utilities getSystemGray6];
    mac_4_UI.backgroundColor = [Utilities getSystemGray6];
    mac_5_UI.backgroundColor = [Utilities getSystemGray6];
    descriptionUI.tintColor = [Utilities get1stLabelColor];
    ipUI.tintColor = [Utilities get1stLabelColor];
    portUI.tintColor = [Utilities get1stLabelColor];
    tcpPortUI.tintColor = [Utilities get1stLabelColor];
    usernameUI.tintColor = [Utilities get1stLabelColor];
    passwordUI.tintColor = [Utilities get1stLabelColor];
    mac_0_UI.tintColor = [Utilities get1stLabelColor];
    mac_1_UI.tintColor = [Utilities get1stLabelColor];
    mac_2_UI.tintColor = [Utilities get1stLabelColor];
    mac_3_UI.tintColor = [Utilities get1stLabelColor];
    mac_4_UI.tintColor = [Utilities get1stLabelColor];
    mac_5_UI.tintColor = [Utilities get1stLabelColor];
    discoveredInstancesTableView.backgroundColor = [Utilities getSystemGray6];
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromRight:)];
    rightSwipe.numberOfTouchesRequired = 1;
    rightSwipe.cancelsTouchesInView = NO;
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwipe];
    
    CGFloat bottomPadding = [Utilities getBottomPadding];
    if (IS_IPAD) {
        bottomPadding = SERVERPOPUP_BOTTOMPADDING;
    }
    if (bottomPadding > 0) {
        CGRect frame = tipView.frame;
        frame.origin.y -= bottomPadding;
        tipView.frame = frame;
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
