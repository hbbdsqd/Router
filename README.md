# Router
## 调用方法
在AppDelegate中引入NGPushRouteHelper
在收到消息推送的代理中获取userInfo
NSDictionary * userInfo = response.notification.request.content.userInfo;
假设userinfo = @{@"url":@"{\"router\":\"app\",\"action\":\"LGLiveVC\",\"param\":{\"store_name\":\"测试\",\"store_Id\":\"1234\"}}"};
[NGPushRouteHelper handleUserInfo:userinfo];
## 实现方法
### 判断路由方式
#### app
app为内部跳转
#### web
web为外部跳转
### action
action为如果为APP内部跳转的时候需要跳转到的页面控制器name
### 解析参数param
param为控制器的变量集合
### 赋值控制器参数
运行时直接赋值
### 跳转实现



