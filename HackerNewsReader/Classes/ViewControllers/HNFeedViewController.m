//
//  HNFeedViewController.m
//  HackerNewsReader
//
//  Created by Ryan Nystrom on 4/5/15.
//  Copyright (c) 2015 Ryan Nystrom. All rights reserved.
//

#import "HNFeedViewController.h"

#import "HNFeed.h"
#import "HNPost.h"

#import "HNPostCell.h"
#import "HNEmptyTableCell.h"
#import "HNLoadingCell.h"
#import "HNCommentViewController.h"
#import "HNTableStatus.h"
#import "HNNavigationController.h"
#import "UIViewController+UISplitViewController.h"
#import "UIViewController+ActivityIndicator.h"
#import "UINavigationController+HNBarState.h"
#import "HNPostControllerHandling.h"
#import "HNReadPostStore.h"
#import "HNFeedDataSource.h"
#import "HNSearchPostsController.h"
#import "HNLoginViewController.h"
#import "HNLogin.h"

typedef NS_ENUM(NSUInteger, HNFeedViewControllerSection) {
    HNFeedViewControllerSectionData,
    HNFeedViewControllerSectionCount
};

static NSString * const kPostCellIdentifier = @"kPostCellIdentifier";
static NSUInteger const kItemsPerPage = 30;

@interface HNFeedViewController () <HNPostCellDelegate>

@property (nonatomic, strong) HNPostCell *prototypeCell;
@property (nonatomic, assign) BOOL didRefresh;
@property (nonatomic, strong) HNTableStatus *tableStatus;
@property (nonatomic, strong) HNFeedDataSource *feedDataSource;
@property (nonatomic, copy) HNFeed *feed;
@property (nonatomic, strong) HNSearchPostsController *searchPostsController;

@property (nonatomic, strong) HNLoginViewController *loginViewController;

@end

@implementation HNFeedViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.extendedLayoutIncludesOpaqueBars = YES;

    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;

    self.searchPostsController = [[HNSearchPostsController alloc] initWithContentsController:self readPostStore:self.readPostStore];
    self.definesPresentationContext = YES;
    self.tableView.tableHeaderView = [self.searchPostsController searchBar];

    [self fetchWithParams:nil refresh:YES];

    self.feedDataSource = [[HNFeedDataSource alloc] initWithTableView:self.tableView readPostStore:self.readPostStore];

    self.tableView.tableFooterView = [[UIView alloc] init];

    NSString *emptyMessage = NSLocalizedString(@"No results found", @"Did not find any results for feed");
    self.tableStatus = [[HNTableStatus alloc] initWithTableView:self.tableView emptyMessage:emptyMessage];
    self.tableStatus.sections = HNFeedViewControllerSectionCount;

    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self action:@selector(onRefresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
        [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController hn_setHidesBarsOnSwipe:NO navigationBarHidden:NO toolbarHidden:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.splitViewController.presentsWithGesture = YES;

    if (self.dataCoordinator.isFetching) {
        [self hn_insertActivityIndicator];
    }
}

- (UISearchDisplayController *)searchDisplayController {
    return self.searchPostsController;
}


#pragma mark - Actions

- (void)fetchWithParams:(NSDictionary *)params refresh:(BOOL)refresh {
    if ([self.dataCoordinator isFetching]) {
        return;
    }

    self.didRefresh = refresh;
    [self.dataCoordinator fetchWithParams:params];
}

- (void)onRefresh:(UIRefreshControl *)refreshControl {
    [self.tableStatus hideEmptyMessage];
    [self hn_hideActivityIndicator];
    [self fetchWithParams:nil refresh:YES];
}

- (void)updateFeed:(HNFeed *)feed {
    [self.tableStatus hideTailLoader];
    [self hn_hideActivityIndicator];

    if (feed.items.count == 0) {
        [self.tableStatus displayEmptyMessage];
    } else {
        [self.tableStatus hideEmptyMessage];
    }

    // if not refreshing, append items
    if (!self.didRefresh) {
        feed = [self.feed feedByMergingFeed:feed];

        NSUInteger currentCount = self.feed.items.count;
        NSMutableArray *inserts = [[NSMutableArray alloc] init];
        [feed.items enumerateObjectsUsingBlock:^(HNPost *post, NSUInteger idx, BOOL *stop) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:HNFeedViewControllerSectionData];
            if (idx >= currentCount) {
                [inserts addObject:indexPath];
            }
        }];

        self.feed = feed;

        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:inserts withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    } else {
        self.didRefresh = NO;
        self.feed = feed;
        [self.tableView reloadData];
    }
}


#pragma mark - Setters

- (void)setFeed:(HNFeed *)feed {
    _feed = [feed copy];
    self.feedDataSource.posts = feed.items;
    self.searchPostsController.posts = feed.items;
}


#pragma mark - HNPostCellDelegate

- (void)postCellDidTapCommentButton:(HNPostCell *)postCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:postCell];
    if (indexPath) {
        HNPost *post = self.feedDataSource.posts[indexPath.row];
        
        [self.readPostStore readPK:post.pk];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        HNCommentViewController *commentController = [[HNCommentViewController alloc] initWithPostID:post.pk];
        [self hn_showDetailViewControllerWithFallback:commentController];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return HNFeedViewControllerSectionCount + [self.tableStatus additionalSectionCount];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == HNFeedViewControllerSectionData) {
        return self.feedDataSource.posts.count;
    } else {
        return [self.tableStatus cellCountForSection:section];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger section = indexPath.section;

    if (section == HNFeedViewControllerSectionData) {
        HNPostCell *cell = [self.feedDataSource cellForPostAtIndexPath:indexPath];
        cell.delegate = self;
        return cell;
    } else {
        return [self.tableStatus cellForIndexPath:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == HNFeedViewControllerSectionData) {
        return [self.feedDataSource heightForPostAtIndexPath:indexPath];
    } else {
        return 55.0;
    }
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section != HNFeedViewControllerSectionData) {
        return;
    }

    HNPost *post = self.feedDataSource.posts[indexPath.row];
    [self.readPostStore readPK:post.pk];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

    UIViewController *controller = viewControllerForPost(post);
    [self hn_showDetailViewControllerWithFallback:controller];
}


#pragma mark - HNDataCoordinatorDelegate

- (void)dataCoordinator:(HNDataCoordinator *)dataCoordinator didUpdateObject:(id)object {
    NSAssert([NSThread isMainThread], @"Delegate callbacks should be on the (registered) main thread");

    if (self.isViewLoaded) {
        if (self.refreshControl.isRefreshing) {
            [self.refreshControl endRefreshing];
            [self performSelector:@selector(updateFeed:) withObject:object afterDelay:0.23];
        } else {
            [self updateFeed:object];
        }
    } else {
        self.feed = object;
    }
}

- (void)dataCoordinator:(HNDataCoordinator *)dataCoordinator didError:(NSError *)error {
    NSAssert([NSThread isMainThread], @"Delegate callbacks should be on the (registered) main thread");

    [self hn_hideActivityIndicator];
    [self.tableStatus displayEmptyMessage];
    [self.refreshControl endRefreshing];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGFloat height = CGRectGetHeight(self.view.bounds);
    CGFloat offset = targetContentOffset->y + height;
    CGFloat contentHeight = scrollView.contentSize.height;
    if (contentHeight > height && offset > contentHeight - height && !self.dataCoordinator.isFetching) {
        NSUInteger items = [self tableView:self.tableView numberOfRowsInSection:HNFeedViewControllerSectionData];
        NSUInteger page = items / kItemsPerPage + 1;
        [self fetchWithParams:@{@"p": @(page)} refresh:NO];
        [self.tableStatus displayTailLoader];
    }
}

#pragma mark - UIViewControllerPreviewingDelegate

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    HNPostCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    previewingContext.sourceRect = cell.frame;
    
    if (indexPath.section != HNFeedViewControllerSectionData) {
        return nil;
    }
    
    HNPost *post = self.feedDataSource.posts[indexPath.row];
    [self.readPostStore readPK:post.pk];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    if ([cell commentButtonContainsLocation:[self.tableView convertPoint:location toView:cell]]) {
        return [[HNCommentViewController alloc] initWithPostID:post.pk];
    } else {
        return viewControllerForPost(post);
    }
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self hn_showDetailViewControllerWithFallback:viewControllerToCommit];
}

#pragma mark - Notifications

- (void)appDidEnterBackgroundNotification:(NSNotification *)notification {
    [self.readPostStore synchronize];
}

@end
