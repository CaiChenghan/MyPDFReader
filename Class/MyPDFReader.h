//
//  MyPDFReader.h
//  MyPDFReader
//
//  Created by 蔡成汉 on 16/8/18.
//  Copyright © 2016年 蔡成汉. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MyPDFReaderDelegate;

@interface MyPDFReader : UIView

/**
 *  delegate
 */
@property (nonatomic , weak) id<MyPDFReaderDelegate>delegate;

/**
 *  pageColor
 */
@property (nonatomic , strong) UIColor *pageColor;

/**
 *  currentItemIndex
 */
@property (nonatomic , assign) NSInteger currentItemIndex;

/**
 *  numPage
 */
@property (nonatomic , assign , readonly) NSInteger numPage;

/**
 *  加载pdf文件
 *
 *  @param data pdf_data
 */
-(void)loadReader:(NSData *)data;

/**
 *  加载pdf文件
 *
 *  @param data      pdf_data
 *  @param pageIndex pageIndex
 */
-(void)loadReader:(NSData *)data pageIndex:(NSInteger)pageIndex;

/**
 *  加载pdf文件
 *
 *  @param path pdf_path
 */
-(void)loadReaderWithPath:(NSString *)path;

/**
 *  加载pdf文件
 *
 *  @param path      pdf_path
 *  @param pageIndex pageIndex
 */
-(void)loadReaderWithPath:(NSString *)path pageIndex:(NSInteger)pageIndex;

@end


@protocol MyPDFReaderDelegate <NSObject>

@optional

/**
 *  itemIsTouchAtIndex
 *
 *  @param pdfReader pdfReader
 *  @param index     index
 */
-(void)pdfReader:(MyPDFReader *)pdfReader itemIsTouchAtIndex:(NSInteger)index;

/**
 *  currentItemIndexDidChange
 *
 *  @param pdfReader pdfReader
 */
-(void)pdfReaderCurrentItemIndexDidChange:(MyPDFReader *)pdfReader;

/**
 *  pdfReaderDidScroll
 *
 *  @param pdfReader pdfReader
 */
-(void)pdfReaderDidScroll:(MyPDFReader *)pdfReader;

@end