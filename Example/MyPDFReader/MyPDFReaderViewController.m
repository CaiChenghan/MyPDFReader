//
//  MyPDFReaderViewController.m
//  MyPDFReader
//
//  Created by 蔡成汉 on 08/19/2016.
//  Copyright (c) 2016 蔡成汉. All rights reserved.
//

#import "MyPDFReaderViewController.h"
#import <MyPDFReader/MyPDFReader.h>

@interface MyPDFReaderViewController ()<MyPDFReaderDelegate>

@property (nonatomic , strong) MyPDFReader *pdfReader;

@end

@implementation MyPDFReaderViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _pdfReader = [[MyPDFReader alloc]initWithFrame:CGRectMake(0, 64.0, self.view.bounds.size.width, self.view.bounds.size.height - 64.0)];
    _pdfReader.backgroundColor = [UIColor blackColor];
    _pdfReader.pageColor = [UIColor lightGrayColor];
    _pdfReader.delegate = self;
    NSString *pathString = [[NSBundle mainBundle]pathForResource:@"lls" ofType:@"pdf"];
    [_pdfReader loadReaderWithPath:pathString pageIndex:5];
    [self.view addSubview:_pdfReader];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _pdfReader.frame = CGRectMake(0, 64.0, self.view.bounds.size.width, self.view.bounds.size.height - 64.0);
}

#pragma mark - MyPDFReaderDelegate

-(void)pdfReaderDidScroll:(MyPDFReader *)pdfReader
{
    self.navigationItem.title = [NSString stringWithFormat:@"第%ld/%ld页",(long)_pdfReader.currentItemIndex,(long)_pdfReader.numPage];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
