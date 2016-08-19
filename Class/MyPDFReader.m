//
//  MyPDFReader.m
//  MyPDFReader
//
//  Created by 蔡成汉 on 16/8/18.
//  Copyright © 2016年 蔡成汉. All rights reserved.
//

//翻页效果参考MWPhotoBrowser

#import "MyPDFReader.h"

#define PADDING                  10


#pragma mark - PDFReader


@interface PDFReader : UIView

/**
 *  加载pdf
 *
 *  @param pdfRef pdfRef
 *  @param page   page
 */
-(void)loadReader:(CGPDFDocumentRef)pdfRef page:(NSInteger)page;

@end

@interface PDFReader ()

/**
 *  pdfRef
 */
@property (nonatomic , assign , readonly) CGPDFDocumentRef pdfRef;

/**
 *  当前页面page
 */
@property (nonatomic , assign) NSInteger currentPage;

@end

@implementation PDFReader

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

/**
 *  加载pdf
 *
 *  @param pdfRef pdfRef
 *  @param page   page
 */
-(void)loadReader:(CGPDFDocumentRef)pdfRef page:(NSInteger)page
{
    //创建PDFRef
    _pdfRef = pdfRef;
    
    //当前加载页面
    _currentPage = page;
    
    [self setNeedsDisplay];
}

/**
 *  页面绘制
 *
 *  @param rect rect
 */
-(void)drawRect:(CGRect)rect
{
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    CGPDFPageRef pageRef = CGPDFDocumentGetPage(_pdfRef, _currentPage);
    //缩放 -- 此处需要特殊处理
    CGSize pdfSize = CGSizeZero;
    CGRect mediaBoxRect = CGPDFPageGetBoxRect(pageRef, kCGPDFMediaBox);
    CGFloat pdfRate = mediaBoxRect.size.width/mediaBoxRect.size.height;
    CGFloat rectRate = rect.size.width/rect.size.height;
    if (rectRate > pdfRate)
    {
        pdfSize.width = mediaBoxRect.size.width/mediaBoxRect.size.height*rect.size.height;
        pdfSize.height = rect.size.height;
    }
    else
    {
        pdfSize.width = rect.size.width;
        pdfSize.height = mediaBoxRect.size.height/mediaBoxRect.size.width*rect.size.width;
    }
    CGContextTranslateCTM(contextRef, (rect.size.width - pdfSize.width)/2.0, (pdfSize.height + rect.size.height)/2.0);
    CGContextScaleCTM(contextRef, pdfSize.width/mediaBoxRect.size.width, -(pdfSize.height/mediaBoxRect.size.height));
    CGContextSaveGState(contextRef);
    CGContextDrawPDFPage(contextRef, pageRef);
    CGContextRestoreGState(contextRef);
}


@end


#pragma mark - MyZoomingScrollView

@interface MyZoomingScrollView : UIScrollView

/**
 *  index
 */
@property (nonatomic , assign) NSInteger index;

/**
 *  myPDFReader
 */
@property (nonatomic , weak) MyPDFReader *myPDFReader;

/**
 *  加载pdf
 *
 *  @param pdfRef pdfRef
 *  @param page   page
 */
-(void)loadReader:(CGPDFDocumentRef)pdfRef page:(NSInteger)page;

/**
 *  准备重用/清理
 */
-(void)prepareForReuse;

-(void)setMaxMinZoomScalesForCurrentBounds;

@end

@interface MyZoomingScrollView ()<UIScrollViewDelegate>

/**
 *  pdfRef
 */
@property (nonatomic , assign) CGPDFDocumentRef pdfRef;

/**
 *  PDFReader
 */
@property (nonatomic , strong) PDFReader *pdfReader;

/**
 *  page
 */
@property (nonatomic , assign) NSUInteger page;

@end

@implementation MyZoomingScrollView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Setup
        self.backgroundColor = [UIColor whiteColor];
        self.delegate = self;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self initialView];
    }
    return self;
}

-(void)initialView
{
    //PDFReader
    _pdfReader = [[PDFReader alloc] initWithFrame:CGRectZero];
    _pdfReader.backgroundColor = [UIColor whiteColor];
    _pdfReader.userInteractionEnabled = YES;
    [self addSubview:_pdfReader];
    
    //添加单击
    UITapGestureRecognizer *sigleTapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(sigleTapGes:)];
    sigleTapGes.numberOfTapsRequired = 1;
    [_pdfReader addGestureRecognizer:sigleTapGes];
    
    //添加双击
    UITapGestureRecognizer *doubleTapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapGes:)];
    doubleTapGes.numberOfTapsRequired = 2;
    [_pdfReader addGestureRecognizer:doubleTapGes];
    [sigleTapGes requireGestureRecognizerToFail:doubleTapGes];
}


/**
 *  加载pdf
 *
 *  @param pdfRef pdfRef
 *  @param page   page
 */
-(void)loadReader:(CGPDFDocumentRef)pdfRef page:(NSInteger)page
{
    _pdfRef = pdfRef;
    _page = page;
    [self displayImage];
}

/**
 *  单击手势
 *
 *  @param ges 手势
 */
-(void)sigleTapGes:(UITapGestureRecognizer *)ges
{
    if ([_myPDFReader.delegate respondsToSelector:@selector(pdfReader:itemIsTouchAtIndex:)])
    {
        [_myPDFReader.delegate pdfReader:_myPDFReader itemIsTouchAtIndex:_myPDFReader.currentItemIndex];
    }
}

/**
 *  双击手势
 *
 *  @param ges 手势
 */
-(void)doubleTapGes:(UITapGestureRecognizer *)ges
{
    [self handleMyDoubleTap:[ges locationInView:ges.view]];
}

-(void)handleMyDoubleTap:(CGPoint)touchPoint
{
    // Zoom
    if (self.zoomScale != self.minimumZoomScale && self.zoomScale != [self initialZoomScaleWithMinScale])
    {
        // Zoom out
        [self setZoomScale:self.minimumZoomScale animated:YES];
        
    }
    else
    {
        // Zoom in to twice the size
        CGFloat newZoomScale = ((self.maximumZoomScale + self.minimumZoomScale) / 2);
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [self zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
    }
}

- (CGFloat)initialZoomScaleWithMinScale
{
    CGFloat zoomScale = self.minimumZoomScale;
    // Zoom image to fill if the aspect ratios are fairly similar
    CGSize boundsSize = self.bounds.size;
    
    CGRect mediaBoxRect = CGPDFPageGetBoxRect(CGPDFDocumentGetPage(_pdfRef, _page), kCGPDFMediaBox);
    CGSize pdfSize = [self resetPDFSize:mediaBoxRect.size];
    CGFloat boundsAR = boundsSize.width/boundsSize.height;
    CGFloat pdfAR = pdfSize.width/pdfSize.height;
    
    // Zooms standard portrait images on a 3.5in screen but not on a 4in screen.
    if (ABS(boundsAR - pdfAR) < 0.17)
    {
        CGFloat xScale = boundsSize.width/pdfSize.width;    // the scale needed to perfectly fit the pdf width-wise
        CGFloat yScale = boundsSize.height/pdfSize.height;  // the scale needed to perfectly fit the pdf height-wise
        zoomScale = MAX(xScale, yScale);
        // Ensure we don't zoom in or out too far, just in case
        zoomScale = MIN(MAX(self.minimumZoomScale, zoomScale), self.maximumZoomScale);
    }
    return zoomScale;
}

// Get and display image
- (void)displayImage
{
    // Reset
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    self.contentSize = CGSizeMake(0, 0);
    
    //加载PDF
    if (_pdfRef)
    {
        [_pdfReader loadReader:_pdfRef page:_page];
        _pdfReader.hidden = NO;
        
        //重置PDF的frame
        CGRect photoImageViewFrame;
        photoImageViewFrame.origin = CGPointZero;
        CGRect mediaBoxRect = CGPDFPageGetBoxRect(CGPDFDocumentGetPage(_pdfRef, _page), kCGPDFMediaBox);
        photoImageViewFrame.size = [self resetPDFSize:mediaBoxRect.size];//img.size;
        _pdfReader.frame = photoImageViewFrame;
        self.contentSize = photoImageViewFrame.size;
        
        //缩放至最小尺寸
        [self setMaxMinZoomScalesForCurrentBounds];
    }
    [self setNeedsLayout];
}

- (void)setMaxMinZoomScalesForCurrentBounds
{
    // Reset
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    
    // Bail if no image
    if (_pdfRef == nil)
    {
        return;
    }
    
    // Reset position
    _pdfReader.frame = CGRectMake(0, 0, _pdfReader.frame.size.width, _pdfReader.frame.size.height);
    
    // Sizes
    CGSize boundsSize = self.bounds.size;
    
    CGRect mediaBoxRect = CGPDFPageGetBoxRect(CGPDFDocumentGetPage(_pdfRef, _page), kCGPDFMediaBox);
    CGSize pdfSize = [self resetPDFSize:mediaBoxRect.size];
    
    // Calculate Min
    CGFloat xScale = boundsSize.width/pdfSize.width;    // the scale needed to perfectly fit the pdf width-wise
    CGFloat yScale = boundsSize.height/pdfSize.height;  // the scale needed to perfectly fit the pdf height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the pdf to become fully visible
    
    // Calculate Max
    CGFloat maxScale = 3;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        // Let them go a bit bigger on a bigger screen!
        maxScale = 4;
    }
    
    // pdf is smaller than screen so no zooming!
    if (xScale >= 1 && yScale >= 1)
    {
        minScale = 1.0;
    }
    
    // Set min/max zoom
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
    
    // Initial zoom
    self.zoomScale = [self initialZoomScaleWithMinScale];
    
    // If we're zooming to fill then centralise
    if (self.zoomScale != minScale)
    {
        
        // Centralise
        self.contentOffset = CGPointMake((pdfSize.width * self.zoomScale - boundsSize.width)/2.0,(pdfSize.height * self.zoomScale - boundsSize.height)/2.0);
        
    }
    
    // Disable scrolling initially until the first pinch to fix issues with swiping on an initally zoomed in photo
    self.scrollEnabled = NO;
    
    // Layout
    [self setNeedsLayout];
    
}

#pragma mark - UIScrollViewDelegate

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _pdfReader;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    self.scrollEnabled = YES;
}

-(void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

/**
 *  重置pdf展示尺寸
 *
 *  @param size pdf原始尺寸
 *
 *  @return “放大”后的尺寸
 */
-(CGSize)resetPDFSize:(CGSize)size
{
    CGSize tpSize = size;
    CGFloat selfRate = self.bounds.size.width/self.bounds.size.height;
    CGFloat sizeRate = size.width/size.height;
    if (selfRate > sizeRate)
    {
        if (size.height < self.bounds.size.height)
        {
            tpSize.width = size.width/size.height*self.bounds.size.height;
            tpSize.height = self.bounds.size.height;
        }
    }
    else
    {
        if (size.width < self.bounds.size.width)
        {
            tpSize.width = self.bounds.size.width;
            tpSize.height = size.height/size.width*self.bounds.size.width;
        }
    }
    return tpSize;
}

/**
 *  准备重用/清理
 */
-(void)prepareForReuse
{
    _index = NSUIntegerMax;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _pdfReader.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width)
    {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    } else
    {
        frameToCenter.origin.x = 0;
    }
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height)
    {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    } else
    {
        frameToCenter.origin.y = 0;
    }
    
    // Center
    if (!CGRectEqualToRect(_pdfReader.frame, frameToCenter))
    {
        _pdfReader.frame = frameToCenter;
    }
}

@end



#pragma mark - MyPDFReader



@interface MyPDFReader ()<UIScrollViewDelegate>
{
    /**
     *  页面个数
     */
    NSUInteger numberOfPage;
    
    /**
     *  当前页面索引
     */
    NSUInteger currentPageIndex;
    
    /**
     *  重用
     */
    NSMutableSet *visiblePages,*recycledPages;
    
    BOOL performingLayout;
    
    CGRect previousLayoutBounds;
}

/**
 *  pagingScrollView
 */
@property (nonatomic , strong) UIScrollView *pagingScrollView;

/**
 *  pdfRef
 */
@property (nonatomic , assign) CGPDFDocumentRef pdfRef;

@end


@implementation MyPDFReader

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        numberOfPage = 0;
        currentPageIndex = 0;
        visiblePages = [NSMutableSet set];
        recycledPages = [NSMutableSet set];
        previousLayoutBounds = CGRectZero;
        [self initialView];
    }
    return self;
}

-(void)initialView
{
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    _pagingScrollView = [[UIScrollView alloc]initWithFrame:pagingScrollViewFrame];
    _pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _pagingScrollView.pagingEnabled = YES;
    _pagingScrollView.delegate = self;
    _pagingScrollView.showsHorizontalScrollIndicator = NO;
    _pagingScrollView.showsVerticalScrollIndicator = NO;
    
    _pagingScrollView.backgroundColor = [UIColor whiteColor];
    [self addSubview:_pagingScrollView];
}

/**
 *  set，backgroundColor
 *
 *  @param backgroundColor backgroundColor
 */
-(void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    _pagingScrollView.backgroundColor = backgroundColor;
}

/**
 *  set，pageColor
 *
 *  @param pageColor pageColor
 */
-(void)setPageColor:(UIColor *)pageColor
{
    _pageColor = pageColor;
    [self reloadData];
}

/**
 *  get，currentItemIndex
 *
 *  @return currentItemIndex
 */
-(NSInteger)currentItemIndex
{
    return currentPageIndex;
}

/**
 *  set，currentItemIndex
 *
 *  @param currentItemIndex currentItemIndex
 */
-(void)setCurrentItemIndex:(NSInteger)currentItemIndex
{
    NSUInteger photoCount = numberOfPage;
    if (photoCount == 0)
    {
        currentItemIndex = 0;
    }
    else
    {
        if (currentItemIndex >= photoCount)
        {
            currentItemIndex = numberOfPage-1;
        }
    }
    currentPageIndex = currentItemIndex;
    [self jumpToPageAtIndex:currentItemIndex animated:NO];
}

/**
 *  get，numPage
 *
 *  @return numPage
 */
-(NSInteger)numPage
{
    return numberOfPage;
}

/**
 *  加载pdf文件
 *
 *  @param data pdf_data
 */
-(void)loadReader:(NSData *)data
{
    [self loadReader:data pageIndex:1];
}

/**
 *  加载pdf文件
 *
 *  @param data      pdf_data
 *  @param pageIndex pageIndex
 */
-(void)loadReader:(NSData *)data pageIndex:(NSInteger)pageIndex
{
    if (data == nil)
    {
        return;
    }
    //创建PDFRef
    CGDataProviderRef dataRef = CGDataProviderCreateWithCFData((CFDataRef)data);
    _pdfRef = CGPDFDocumentCreateWithProvider(dataRef);
    CFRelease(dataRef);
    
    //获取页面总数
    numberOfPage = CGPDFDocumentGetNumberOfPages(_pdfRef);
    
    //重置contentSize -- 根据页面数
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    
    currentPageIndex = pageIndex - 1;
    
    /**
     *  数据加载
     */
    [self reloadData];
}

/**
 *  加载pdf文件
 *
 *  @param path pdf_path
 */
-(void)loadReaderWithPath:(NSString *)path
{
    [self loadReaderWithPath:path pageIndex:1];
}

/**
 *  加载pdf文件
 *
 *  @param path      pdf_path
 *  @param pageIndex pageIndex
 */
-(void)loadReaderWithPath:(NSString *)path pageIndex:(NSInteger)pageIndex
{
    if (path == nil || path.length == 0)
    {
        return;
    }
    NSURL *pdfURL = [NSURL fileURLWithPath:path];
    
    //创建PDFRef
    _pdfRef = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
    
    //获取页面总数
    numberOfPage = CGPDFDocumentGetNumberOfPages(_pdfRef);
    
    //重置contentSize -- 根据页面数
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    
    currentPageIndex = pageIndex - 1;
    
    /**
     *  数据加载
     */
    [self reloadData];
}

/**
 *  加载数据
 */
-(void)reloadData
{
    if (numberOfPage == 0)
    {
        return;
    }
    
    //重置页面索引 -- 不能超过页面最大值
    if (numberOfPage > 0)
    {
        currentPageIndex = MAX(0, MIN(currentPageIndex, numberOfPage - 1));
    }
    else
    {
        currentPageIndex = 0;
    }

    //清除子视图
    [_pagingScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [self performLayout];
    [self setNeedsLayout];
}

-(void)performLayout
{
    performingLayout = YES;
    
    [visiblePages removeAllObjects];
    [recycledPages removeAllObjects];
    
    //重置偏移量
    _pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:currentPageIndex];
    
    [self tilePages];
    
    performingLayout = NO;
}

/**
 *  pageScrollView页面处理 -- 采用重用机制对对象进行操作
 */
-(void)tilePages
{
    // Calculate which pages should be visible
    // Ignore padding as paging bounces encroach on that
    // and lead to false page loads
    CGRect visibleBounds = _pagingScrollView.bounds;
    NSInteger iFirstIndex = (NSInteger)floorf((CGRectGetMinX(visibleBounds)+PADDING*2) / CGRectGetWidth(visibleBounds));
    NSInteger iLastIndex  = (NSInteger)floorf((CGRectGetMaxX(visibleBounds)-PADDING*2-1) / CGRectGetWidth(visibleBounds));
    if (iFirstIndex < 0)
    {
        iFirstIndex = 0;
    }
    if (iFirstIndex > numberOfPage - 1)
    {
        iFirstIndex = numberOfPage - 1;
    }
    if (iLastIndex < 0)
    {
        iLastIndex = 0;
    }
    if (iLastIndex > numberOfPage - 1)
    {
        iLastIndex = numberOfPage - 1;
    }
    
//    NSLog(@"第一索引=%ld",(long)iFirstIndex);
//    NSLog(@"末位索引=%ld",(long)iLastIndex);
    
    //移除目标对象：从“可见”队列中移除不可见的对象
    NSInteger pageIndex;
    for (MyZoomingScrollView *page in visiblePages)
    {
        pageIndex = page.index;
        if (pageIndex < (NSUInteger)iFirstIndex || pageIndex > (NSUInteger)iLastIndex)
        {
            [recycledPages addObject:page];
            [page prepareForReuse];
            [page removeFromSuperview];
//            NSLog(@"移除对象，同时添加到重用池中：索引=%lu", (unsigned long)pageIndex);
        }
    }
    
    //从recycledPages中除去与visiblePages中相同的元素
    [visiblePages minusSet:recycledPages];
    
    //仅仅保留2个重用对象
    while (recycledPages.count > 2)
    {
        [recycledPages removeObject:[recycledPages anyObject]];
    }
    
    //添加目标对象到scrollView上
    for (NSUInteger index = (NSUInteger)iFirstIndex ; index <= (NSUInteger)iLastIndex; index++)
    {
        //如果目标对象不在当前页面中，则添加目标对象
        if (![self isDisplayingPageForIndex:index])
        {
            //添加新对象 -- 从重用池中获取
            MyZoomingScrollView *page = [self dequeueRecycledPage];
            if (!page)
            {
                page = [[MyZoomingScrollView alloc]init];
//                NSLog(@"创建新对象：索引=%lu", (unsigned long)index);
            }
            else
            {
//                NSLog(@"重用了对象：索引=%lu", (unsigned long)index);
            }
            [visiblePages addObject:page];
            
            //对象配置
            [self configurePage:page forIndex:index];
            
            //添加对象到scrollView上
            [_pagingScrollView addSubview:page];
        }
    }
}

/**
 *  判断目标对象是否在当前页面中
 *
 *  @param index 页面索引
 *
 *  @return YES表示目标在当前页面中，NO表示不在
 */
- (BOOL)isDisplayingPageForIndex:(NSUInteger)index
{
    for (MyZoomingScrollView *page in visiblePages)
    {
        if (page.index == index)
        {
            return YES;
        }
    }
    return NO;
}

/**
 *  从重用池中获取目标对象
 *
 *  @return 重用对象
 */
- (MyZoomingScrollView *)dequeueRecycledPage
{
    //获取任意对象
    MyZoomingScrollView *page = [recycledPages anyObject];
    
    //发现对象
    if (page)
    {
        //取出对象，重用池-1
        [recycledPages removeObject:page];
    }
    return page;
}

/**
 *  页面配置
 *
 *  @param page  页面
 *  @param index 索引
 */
- (void)configurePage:(MyZoomingScrollView *)page forIndex:(NSUInteger)index
{
    page.frame = [self frameForPageAtIndex:index];
    page.index = index;
    page.backgroundColor = _pageColor;
    page.myPDFReader = self;
    [page loadReader:_pdfRef page:index+1];
}

/**
 *  重置pagingScrollView的frame
 *
 *  @return 重置后的pagingScrollView的frame
 */
- (CGRect)frameForPagingScrollView
{
    CGRect frame = self.bounds;
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return CGRectIntegral(frame);
}

/**
 *  重置pagingScrollView的contentSize
 *
 *  @return 重置后的pagingScrollView的contentSize
 */
- (CGSize)contentSizeForPagingScrollView
{
    CGRect bounds = _pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * numberOfPage, bounds.size.height);
}

/**
 *  重置pagingScrollView偏移量
 *
 *  @param index 页面索引
 *
 *  @return 偏移量
 */
- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index
{
    CGFloat pageWidth = _pagingScrollView.bounds.size.width;
    CGFloat newOffset = index * pageWidth;
    return CGPointMake(newOffset, 0);
}


/**
 *  重置目标对象的frame
 *
 *  @param index 目标索引
 *
 *  @return 目标对象
 */
- (CGRect)frameForPageAtIndex:(NSUInteger)index
{
    CGRect bounds = _pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
    return CGRectIntegral(pageFrame);
}

- (void)jumpToPageAtIndex:(NSUInteger)index animated:(BOOL)animated {
    
    // Change page
    if (index < numberOfPage)
    {
        CGRect pageFrame = [self frameForPageAtIndex:index];
        [_pagingScrollView setContentOffset:CGPointMake(pageFrame.origin.x - PADDING, 0) animated:animated];
    }
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Checks
    if (performingLayout) return;
    
    // Tile pages
    [self tilePages];
    
    //重新计算当前页面的index
    CGRect visibleBounds = _pagingScrollView.bounds;
    NSInteger index = (NSInteger)(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)));
    if (index < 0)
    {
        index = 0;
    }
    if (index > numberOfPage - 1)
    {
        index = numberOfPage - 1;
    }
    NSUInteger previousCurrentPage = currentPageIndex;
    currentPageIndex = index;
    
    //如果页面索引发生变化，则需要对目标对象进行检查，释放掉不在可见页面上的目标对象
    if (currentPageIndex != previousCurrentPage)
    {
        [self didStartViewingPageAtIndex:index];
        
        if ([self.delegate respondsToSelector:@selector(pdfReaderCurrentItemIndexDidChange:)])
        {
            [self.delegate pdfReaderCurrentItemIndexDidChange:self];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(pdfReaderDidScroll:)])
    {
        [self.delegate pdfReaderDidScroll:self];
    }
}

// Handle page changes
- (void)didStartViewingPageAtIndex:(NSUInteger)index {
    
    // Handle 0 photos
    if (!numberOfPage)
    {
        return;
    }
    
    // Release images further away than +/-1
    if (index > 0)
    {
        // Release anything < index - 1
    }
    if (index < numberOfPage - 1)
    {
        // Release anything > index + 1
        
    }
}

- (void)layoutVisiblePages
{
    // Flag
    performingLayout = YES;
    
    // Remember index
    NSUInteger indexPriorToLayout = currentPageIndex;
    
    // Get paging scroll view frame to determine if anything needs changing
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
    // Frame needs changing
    _pagingScrollView.frame = pagingScrollViewFrame;
    
    // Recalculate contentSize based on current orientation
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    
    // Adjust frames and configuration of each visible page
    for (MyZoomingScrollView *page in visiblePages)
    {
        NSUInteger index = page.index;
        page.frame = [self frameForPageAtIndex:index];
        
        // Adjust scales if bounds has changed since last time
        if (!CGRectEqualToRect(previousLayoutBounds, self.bounds))
        {
            // Update zooms for new bounds
            [page setMaxMinZoomScalesForCurrentBounds];
            previousLayoutBounds = self.bounds;
        }
    }
    
    // Adjust contentOffset to preserve page location based on values collected prior to location
    _pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:indexPriorToLayout];
    [self didStartViewingPageAtIndex:currentPageIndex]; // initial
    
    // Reset
    currentPageIndex = indexPriorToLayout;
    performingLayout = NO;
}


-(void)layoutSubviews
{
    [super layoutSubviews];
    _pagingScrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    [self layoutVisiblePages];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end



