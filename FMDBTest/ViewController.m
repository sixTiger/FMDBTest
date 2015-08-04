//
//  ViewController.m
//  FMDBTest
//
//  Created by 杨小兵 on 15/7/31.
//  Copyright (c) 2015年 杨小兵. All rights reserved.
//

#import "ViewController.h"
#import "FMDB.h"
@import AssetsLibrary;
@import AVFoundation;

@interface ViewController ()<UIImagePickerControllerDelegate , UINavigationControllerDelegate>

@property(nonatomic , strong)UIImage *image;
@property (nonatomic, strong) FMDatabaseQueue *queue;
@property (weak, nonatomic) IBOutlet UITextField *IDTextField;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIButton *iconButton;
- (IBAction)iconButtonClick:(UIButton *)sender;

@end

@implementation ViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self creatDataBase];
}
// 增加
- (IBAction)insert:(id)sender
{
    // executeUpdate方法里面的参数必须添对象
    
    [_queue inDatabase:^(FMDatabase *db) {
        [db open];
        BOOL success = [db executeUpdate:@"insert into FMDBTest (name,imageData) values(?,?)",self.nameTextField.text,UIImagePNGRepresentation(self.image)];
        if (success)
        {
            NSLog(@"插入成功");
        }
        else
        {
            NSLog(@"插入失败");
        }
        [db close];
    }];
}
- (IBAction)delete:(id)sender
{
    [_queue inDatabase:^(FMDatabase *db) {
        [db open];
        BOOL success = [db executeUpdate:@"delete from FMDBTest where id = ?",self.IDTextField.text];
        if (success)
        {
            NSLog(@"删除成功");
        }
        else
        {
            NSLog(@"删除失败");
        }
        
        [db close];
    }];
}

- (IBAction)select:(id)sender
{
    
    [_queue inDatabase:^(FMDatabase *db) {
        [db open];
        FMResultSet *set = [db executeQuery:@"select * from FMDBTest where id = ?",self.IDTextField.text];
        
        if ([set next])
        {
            // 查询到一条记录
            
            NSInteger ID = [set intForColumn:@"id"];
            NSString *name = [set stringForColumn:@"name"];
            NSData *data = [set dataForColumn:@"imageData"];
            self.IDTextField.text = [NSString stringWithFormat:@"%@",@(ID)];
            self.nameTextField.text = name;
            [self.iconButton setImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
        }
        else
        {
            NSLog(@"内有查询到内容");
        }
        [db close];
    }];
    
}
- (IBAction)update:(id)sender
{
    
    [_queue inDatabase:^(FMDatabase *db) {
        
        [db open];
        // 开启事务
        [db beginTransaction];
        BOOL success = [db executeUpdate:@"update FMDBTest set name = ? , imageData = ? where id = ?",self.nameTextField.text,UIImagePNGRepresentation(self.image),self.IDTextField.text];;
        if (success) {
            NSLog(@"更新成功");
        }else{
            NSLog(@"更新失败");
            // 回滚:前面的操作全部无效,只要是一个事务上的操作.
            [db rollback];
        }
        // 提交
        [db commit];
        [db close];
    }];
    
}
- (void)creatDataBase
{
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [docPath stringByAppendingPathComponent:@"FMDBTest.sqlite"];
    
    // 1.创建数据库的队列,会自动帮你创建FMDatabase对象,打开数据库,肯定会生成数据库实例还有生成数据库文件
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:filePath];
    _queue = queue;
    //FMDatabase *db 是多线程安全的
    [queue inDatabase:^(FMDatabase *db) {
        // 创建表格
        // executeUpdate除了查询操作,其他都是属于更新,创建表格,增删改
        BOOL success =  [db executeUpdate:@"create table if not exists FMDBTest (id integer primary key,name text not null , imageData blob not null);"];
        if (success)
        {
            NSLog(@"创建成功");
        }
        else
        {
            NSLog(@"创建失败");
        }
        [db close];
    }];
}

- (IBAction)iconButtonClick:(UIButton *)sender
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    imagePicker.allowsEditing = YES;
    [self presentViewController:imagePicker animated:YES completion:nil];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.image = info[@"UIImagePickerControllerEditedImage"];
    [picker dismissViewControllerAnimated:YES completion:^{
        [self.iconButton setImage:self.image forState:UIControlStateNormal];
    }];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (UIImage *)image
{
    if (_image == nil)
    {
        _image = [UIImage imageNamed:@"icon"];
    }
    return _image;
}
@end
