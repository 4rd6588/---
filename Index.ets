import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { DatabaseManager } from '../database/DatabaseManager';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State captchaCode: string = '';
  @State generatedCaptcha: string = '';
  @State isPasswordVisible: boolean = false;
  @State isRegister: boolean = false;
  @State confirmPassword: string = '';
  private dbManager: DatabaseManager | null = null;

  aboutToAppear() {
    this.generateCaptcha();
    // 初始化数据库
    const context = getContext(this) as common.UIAbilityContext;
    this.dbManager = DatabaseManager.getInstance(context);
  }

  generateCaptcha() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    let captcha = '';
    for (let i = 0; i < 4; i++) {
      captcha += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    this.generatedCaptcha = captcha;
  }

  build() {
    Stack() {
      // 背景图片
      Image($r('app.media.greenbackground'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .opacity(0.9)

      Column() {
        // Logo和标题
        Column() {
          Text('DuoLa')
            .fontSize(48)
            .fontColor('#5E8C41')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 })
          
          Text('您的智能生活助手')
            .fontSize(16)
            .fontColor('#5E8C41')
            .opacity(0.8)
        }
        .margin({ top: 100, bottom: 60 })

        // 输入区域
        Column() {
          // 用户名输入
          TextInput({ placeholder: '请输入用户名', text: this.username })
            .width('85%')
            .height(50)
            .backgroundColor('#ffffff')
            .borderRadius(25)
            .fontSize(16)
            .placeholderColor('#999999')
            .onChange((value: string) => {
              this.username = value;
            })
            .margin({ bottom: 20 })

          // 密码输入
          Stack() {
            TextInput({ 
              placeholder: '请输入密码', 
              text: this.password
            })
              .width('100%')
              .height(50)
              .type(this.isPasswordVisible ? InputType.Normal : InputType.Password)
              .backgroundColor('#ffffff')
              .borderRadius(25)
              .fontSize(16)
              .placeholderColor('#999999')
              .onChange((value: string) => {
                this.password = value;
              })
              .padding({ right: 50 })

            Image(this.isPasswordVisible ? $r('app.media.suo') : $r('app.media.suo'))
              .width(24)
              .height(24)
              .position({ x: '82%', y: 13 })
              .onClick(() => {
                this.isPasswordVisible = !this.isPasswordVisible;
              })
          }
          .width('85%')
          .margin({ bottom: this.isRegister ? 20 : 0 })

          // 确认密码（仅注册时显示）
          if (this.isRegister) {
            TextInput({ 
              placeholder: '请确认密码', 
              text: this.confirmPassword
            })
              .width('85%')
              .height(50)
              .type(InputType.Password)
              .backgroundColor('#ffffff')
              .borderRadius(25)
              .fontSize(16)
              .placeholderColor('#999999')
              .onChange((value: string) => {
                this.confirmPassword = value;
              })
              .margin({ bottom: 20 })
          }

          // 验证码区域
          Row() {
            TextInput({ placeholder: '验证码', text: this.captchaCode })
              .width('55%')
              .height(50)
              .backgroundColor('#ffffff')
              .borderRadius(25)
              .fontSize(16)
              .placeholderColor('#999999')
              .onChange((value: string) => {
                this.captchaCode = value;
              })

            // 验证码显示
            Stack() {
              Rect()
                .width(100)
                .height(40)
                .fill('#f0f0f0')
                .radius(8)
                .stroke('#cccccc')
                .strokeWidth(1)

              Text(this.generatedCaptcha)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .decoration({ type: TextDecorationType.LineThrough, color: '#999999' })
            }
            .margin({ left: 15 })
            .onClick(() => {
              this.generateCaptcha();
            })
          }
          .width('85%')
          .margin({ top: 20, bottom: 40 })

          // 登录/注册按钮
          Button(this.isRegister ? '注册' : '登录')
            .width('85%')
            .height(50)
            .backgroundColor('#5E8C41')
            .fontColor(Color.White)
            .fontSize(18)
            .borderRadius(25)
            .onClick(async () => {
              if (!this.username || !this.password) {
                promptAction.showToast({
                  message: '请输入用户名和密码',
                  duration: 2000
                });
                return;
              }

              if (this.captchaCode !== this.generatedCaptcha) {
                promptAction.showToast({
                  message: '验证码错误',
                  duration: 2000
                });
                this.generateCaptcha();
                return;
              }

              if (this.isRegister) {
                if (this.password !== this.confirmPassword) {
                  promptAction.showToast({
                    message: '两次密码输入不一致',
                    duration: 2000
                  });
                  return;
                }
                
                // 注册逻辑
                if (this.dbManager) {
                  const success = await this.dbManager.createUser({
                    username: this.username,
                    password: this.password
                  });
                  
                  if (success) {
                    promptAction.showToast({
                      message: '注册成功，请登录',
                      duration: 2000
                    });
                    this.isRegister = false;
                    this.password = '';
                    this.confirmPassword = '';
                  } else {
                    promptAction.showToast({
                      message: '注册失败，用户名可能已存在',
                      duration: 2000
                    });
                  }
                }
              } else {
                // 登录验证逻辑
                if (this.dbManager) {
                  const user = await this.dbManager.verifyUser(this.username, this.password);
                  
                  if (user) {
                    // 保存用户信息到全局状态（如果需要）
                    router.replaceUrl({
                      url: 'pages/MainPage'
                    });
                  } else {
                    promptAction.showToast({
                      message: '用户名或密码错误',
                      duration: 2000
                    });
                  }
                } else {
                  // 数据库未初始化时的临时处理
                  if (this.username === 'admin' && this.password === 'admin') {
                    router.replaceUrl({
                      url: 'pages/MainPage'
                    });
                  } else {
                    promptAction.showToast({
                      message: '用户名或密码错误',
                      duration: 2000
                    });
                  }
                }
              }
            })

          // 切换登录/注册
          Row() {
            Text(this.isRegister ? '已有账号？' : '没有账号？')
              .fontSize(14)
              .fontColor('#5E8C41')
              .opacity(0.8)

            Text(this.isRegister ? '立即登录' : '立即注册')
              .fontSize(14)
              .fontColor('#2B6631')
              .fontWeight(FontWeight.Bold)
              .onClick(() => {
                this.isRegister = !this.isRegister;
                this.password = '';
                this.confirmPassword = '';
                this.captchaCode = '';
                this.generateCaptcha();
              })
          }
          .margin({ top: 20 })

          // 用户协议
          Text('登录即表示同意《用户协议》和《隐私政策》')
            .fontSize(12)
            .fontColor('#5E8C41')
            .opacity(0.6)
            .margin({ top: 40 })
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}