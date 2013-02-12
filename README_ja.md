REKit
=====
　REKit (リキット) は NSObject 拡張のコレクションで、現時点で 2 つの機能を提供する：

1. [REResponder](#REResponder): Block を使ったインスタンスの動的メソッド実装／上書き機能
2. [REObserver](#REObserver): Block を使って KVO  (Key-Value Observing) を実現する機能 + α

　Blocks や GCD の登場は、iOS, OS X の世界に大きな変化をもたらした。プログラマは、時間的に隔絶された処理をその場で記述できるようになった。それにより、開発の柔軟度は飛躍的に向上した。

　REKit 特に REResponder は、Blocks の潜在能力を GCD とはまた違った形で引き出すものだ。REResponder は、ランタイムでインスタンスを再設計する能力をプログラマに与える。具体的には、インスタンスにメソッドを追加したり、インスタンスのメソッドを上書きすることを可能にする。REKit もまた、iOS, OS X の世界に大きな変化をもたらす可能性を持っている。

　REKit は、[SpliTron](http://appstore.com/splitron "SpliTron") という iPhone アプリで実際に使用されており、開発効率の向上、保守性の向上に貢献した。それにより、SpliTron は数度の仕様変更にも迅速に対応し、チームはユーザイクスペリエンスの向上に注力することができた。

　今後 REKit が多くの開発で採用され、iOS, OS X の世界に寄与できることを願っている。

## <a id="REResponder"></a>REResponder
　REResponder は、インスタンスにメソッドを追加したり、インスタンスのメソッドを上書きすることを可能にする。以下に、REResponder の機能、挙動、[活用例](#Examples)を紹介する。


### <a id="AddingMethodsDynamically"></a>動的メソッド実装
　REResponder は、Block を使った動的メソッド実装を可能にする。それには `-respondsToSelector:withKey:usingBlock:` メソッドを使用する。例えば `NSObject` には `-sayHello` というメソッドはないが、以下のようにすると動的に実装することができる：

```objective-c
id obj;
obj = [[NSObject alloc] init];
[obj respondsToSelector:@selector(sayHello) withKey:nil usingBlock:^(id receiver) {
	NSLog(@"Hello World!");
}];
[obj performSelector:@selector(sayHello)]; // Hello World!
```

　この動的メソッド実装は、`obj` インスタンスだけに適用され、他のインスタンスには影響しない。


### <a id="OverridingMethodsDynamically"></a>動的メソッド上書き
　REResponder は、Block を使った動的メソッド上書きを可能にする。[動的メソッド実装](#AddingMethodsDynamically) のときと同じく `-respondsToSelector:withKey:usingBlock:` メソッドを使用する。例えば `-sayHello` を呼び出すと "No!" をログる MyObject クラスのインスタンスがあったとする。以下のようにすると、"Hello World!" がログられるように上書きすることができる：

```objective-c
MyObject *obj;
obj = [[MyObject alloc] init];
// [obj sayHello]; // No!	
[obj respondsToSelector:@selector(sayHello) withKey:nil usingBlock:^(id receiver) {
	NSLog(@"Hello World!");
}];
[obj sayHello]; // Hello World!
```

　動的メソッド上書きも、`obj` だけに適用され、他のインスタンスには影響しない。


### <a id="ReceiverArgument"></a>Block の receiver 引数
　これまでの例で見てきた通り、 `-respondsToSelector:withKey:usingBlock:` の Block には receiver 引数が必須だ。この receiver には、`-respondsToSelector:withKey:usingBlock:` メソッドを呼び出したときのレシーバが入る。Block の中で使っても循環参照を引き起こさないので、自由に使うことができる：

```objective-c
id obj;
obj = [[NSObject alloc] init];
[obj respondsToSelector:@selector(sayHello) withKey:nil usingBlock:^(id receiver) {
	// NSLog(@"obj = %@", obj); // Causes retain cycle! Use receiver instead.
	NSLog(@"receiver = %@", receiver);
}];
[obj performSelector:@selector(sayHello)];
```

### 引数や返り値を持つメソッドもサポートする
　REResponder は引数や返り値を持つメソッドもサポートする。引数を持つメソッドを動的に実装／上書きをする場合、Block の引数には、Block に必須な receiver 引数に続けてメソッドの引数をリストする：

```objective-c
UIAlertView *alertView;
// …
[alertView
	respondsToSelector:@selector(alertViewShouldEnableFirstOtherButton:)
	withKey:nil
	usingBlock:^(id receiver, UIAlertView *alertView) {
		return NO;
	}
];
```

### Block をキーで管理する
　Block にはキーを割り当てることができ、後々、そのキーによって Block を管理することができる。Block にキーを割り当てるには、`-respondsToSelector:withKey:usingBlock:` の key 引数に任意のオブジェクトを渡す。Block の有無は `-hasBlockForSelecor:withKey:` で確認できる。Block の削除は `-removeBlockForSelector:withKey:` で行える。

　インスタンスが解放されるとき、そのインスタンスに追加されていたブロックは自動的に削除される ー 後々の Block の操作が必要ない場合は、key 引数に nil を渡してよい。その場合、Block には UUID 文字列が割り当てられる。


### Block のスタック構造
　インスタンスはセレクタ毎に Block をスタックする。最後に追加した(一番上にある) Block が、セレクタが呼び出されたときに実行される Block となる。もし、あるセレクタにおいて、既にあるキーと共に Block を追加しようとした場合、古い Block が削除され、新しい Block が一番上にスタックされる。


### <a id="InvokingSupermethod"></a>supermethod の呼び出し
　ある Block の下にスタックされている Block の実装、あるいはハードコーディングされた実装は、`-supermethodOfCurrentBlock` で取得し、実行することができる：

```objective-c
[obj respondsToSelector:@selector(description) withKey:nil usingBlock:^(id receiver) {
	// Make description…
	NSMutableString *description;
	description = [NSMutableString string];
	
	// Append original description
	IMP supermethod;
	if ((supermethod = [receiver supermethodOfCurrentBlock])) {
		[description appendString:supermethod(receiver, @selector(description))];
	}
	
	// Customize description…
	
	return description;
}];
```

　supermethod に渡す引数には、レシーバとセレクタが必須で、セレクタが引数を持っている場合はその後に続ける。

　supermethod の返り値が id 以外の場合は、IMP をキャストする。以下は返り値が CGRect の場合のキャストである：

```objective-c
typedef CGRect (*RectIMP)(id, SEL, ...);
RectIMP supermethod;
if ((supermethod = (RectIMP)[receiver supermethodOfCurrentBlock])) {
	rect = supermethod(receiver, @selector(rect));
}
```

### <a id="Examples"></a>活用例
　REResponder の活用例を幾つか紹介する。


#### それ自身をデリゲートにする
　そもそもデリゲートパターンを採用しているクラスは、アプリケーションのコンテキストをクラスに入れず再利用性を保ちつつ、アプリケーションのコンテキストを埋込むためのジョインポイントとしてデリゲートメソッドを提供するクラスと言える。もし、デリゲートパターンを採用したインスタンスにアプリケーションのコンテキストを埋込むことができるなら、アプリケーションレイアにいるデリゲートに依存しないインスタンスを作ることができる。REResponder はそれを可能にする。

　以下は、UIAlertView の delegate に alertView 自身を設定する例である：

```objective-c
UIAlertView *alertView;
alertView = [[UIAlertView alloc]
	initWithTitle:@"title"
	message:@"message"
	delegate:nil
	cancelButtonTitle:@"Cancel"
	otherButtonTitles:@"OK", nil
];
[alertView
	respondsToSelector:@selector(alertView:didDismissWithButtonIndex:)
	withKey:nil
	usingBlock:^(id receiver, UIAlertView *alertView, NSInteger buttonIndex) {
		// Do something…
	}
];
alertView.delegate = alertView;
```

　他にも、CAAnimation の delegate に animation 自身を設定するなどが考えられる：

```objective-c
CABasicAnimation *animation;
// …
[animation
	respondsToSelector:@selector(animationDidStop:finished:)
	withKey:nil
	usingBlock:^(id receiver, CABasicAnimation *animation, BOOL finished) {
		// Do something…
	}
];
animation.delegate = animation;
```

　この新しいパターンを使用すると、時間的に隔絶されたコードもまとめて書けるので保守性が向上する。また、普通のデリゲートパターンを使用したときに往々にして必要な、「どのオブジェクトのデリゲートメソッドが呼ばれたのか」を判別する手間もなくなる。デリゲートメソッドが呼ばれるときにデリゲートオブジェクトがゾンビになっているとクラッシュする問題を気にしなくてよくなるという利点もある。


#### それ自身をターゲットにする
　ターゲット／アクション・パラダイムでも、デリゲートパターンと同じことが言える。

　以下のコードでは、タップされたときに何をするのかまでを指定したボタンを `UICollectionViewCell` に追加している：

```objective-c
UIButton *button;
// …
[button respondsToSelector:@selector(buttonAction) withKey:@"key" usingBlock:^(id receiver) {
	// Do something…
}];
[button addTarget:button action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
[cell.contentView addSubview:button];
```

#### UnitTest で、モックオブジェクトを用意する
　REResponder は UnitTest でも威力を発揮する。以下のコードでは、BalloonController のデリゲートメソッドが呼ばれるかどうかを、モックオブジェクトを用意してテストしている：

```objective-c
__block BOOL called = NO;

// Make mock
id mock;
mock = [[NSObject alloc] init];
[mock
	respondsToSelector:@selector(balloonControllerDidDismissBalloon:)
	withKey:nil
	usingBlock:^(id receiver, BalloonController *balloonController) {
		called = YES;
	}
];
balloonController.delegate = mock;

// Dismiss balloon
[balloonController dismissBalloonAnimated:NO];
STAssertTrue(called, @"");
```


#### UnitTest で、ハイコストな処理をスタブ化する
　以下のコードでは、プロフィール画像をダウンロードする AccountManager をスタブ化して、アカウント画面のビューコントローラをテストしている：

```objective-c
// Load sample image
__weak UIImage *sampleImage;
NSString *sampleImagePath;
sampleImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"sample" ofType:@"png"];
sampleImage = [UIImage imageWithContentsOfFile:sampleImagePath];

// Stub out download process
[[AccountManager sharedManager]
	respondsToSelector:@selector(downloadProfileImageWithCompletion:)
	withKey:@"key"
	usingBlock:^(id receiver, void (^completion)(UIImage*, NSError*)) {
		completion(sampleImage, nil);
	}
];

// Call thumbnailButtonAction which causes download of profile image
[acccountViewController thumbnailButtonAction];
STAssertEqualObjects(accountViewController.profileImageView.image, sampleImage, @"");

// Remove block
[[AccountManager sharedManager] removeBlockForSelector:@selector(downloadProfileImageWithCompletion:) forKey:@"key"];
```


#### 関心／機能をまとめる
　
　REResponder は、関心／機能を一ヵ所にまとめる助けをする。以下のコードでは、`UIKeyboardWillShowNotification` の監視開始／終了を `-_manageKeyboardWillShowNotificationObserver`メソッドにまとめている：

```objective-c
- (id)initWithCoder:(NSCoder *)aDecoder
{
	// super
	self = [super initWithCoder:aDecoder];
	if (!self) {
		return nil;
	}
	
	// Manage _keyboardWillShowNotificationObserver
	[self _manageKeyboardWillShowNotificationObserver];
	
	return self;
}

- (void)_manageKeyboardWillShowNotificationObserver
{
	__block id observer;
	observer = _keyboardWillShowNotificationObserver;
	
	#pragma mark └ [self viewWillAppear:]
	[self respondsToSelector:@selector(viewWillAppear:) withKey:nil usingBlock:^(id receiver, BOOL animated) {
		// supermethod
		REVoidIMP supermethod; // REVoidIMP is defined like this: typedef void (*REVoidIMP)(id, SEL, ...);
		if ((supermethod = (REVoidIMP)[receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, @selector(viewWillAppear:), animated);
		}
		
		// Start observing
		if (!observer) {
			observer = [[NSNotificationCenter defaultCenter]
				addObserverForName:UIKeyboardWillShowNotification
				object:nil
				queue:[NSOperationQueue mainQueue]
				usingBlock:^(NSNotification *note) {
					// Do something…
				}
			];
		}
	}];
	
	#pragma mark └ [self viewDidDisappear:]
	[self respondsToSelector:@selector(viewDidDisappear:) withKey:nil usingBlock:^(id receiver, BOOL animated) {
		// supermethod
		REVoidIMP supermethod;
		if ((supermethod = (REVoidIMP)[receiver supermethodOfCurrentBlock])) {
			supermethod(receiver, @selector(viewDidDisappear:), animated);
		}
		
		// Stop observing
		[[NSNotificationCenter defaultCenter] removeObserver:observer];
		observer = nil;
	}];
}
```


### REResponder - 既知の問題
a. **クラスが掏り替る**<br />
　REResponder を使って動的メソッド実装／上書きをした場合、そのインスタンスのクラスは "REResponder_UUID_オリジナルのクラス名" というサブクラスに掏り替わる。この掏り替わりによって、KVO の「監視している／監視されている」関係が崩れることが分かった。この問題には対処したが、他にも問題があるかもしれない。問題が起きた場合は、NSObject に加えた `-willChangeClass:` と `-didChangeClass:`、或は `REObjectWillChangeClassNotification` と `REObjectDidChangeClassNotification` で対処してほしい。





## <a id="REObserver"></a>REObserver

REObserver は、KVO (Key-Value Observing) に以下の機能を付加する NSObject の拡張である：

1. [Block を使って KVO を実現する機能](#KVOWithBlock)
2. [監視停止を簡潔にする機能](#StopObservingSimply)
3. [自動で監視を停止する機能](#AutomaticObservationStop)


### <a id="KVOWithBlock"></a>Block を使って KVO を実現する機能
　REObserver を使うと、監視を開始すると同時に、通知が来た時に行う処理を Block で指定できるようになる：

```objective-c
id observer;
observer = [obj addObserverForKeyPath:@"someKeyPath" options:0 usingBlock:^(NSDictionary *change) {
	// Do something…
}];
```

以下のメリットがある：

* 監視を開始するためのコードと通知が来た時のコードを一ヵ所に書けるので、保守性が向上する
* `-observeValueForKeyPath:ofObject:change:context:` メソッドで、どのオブジェクトのどのキーパスの通知が来たのか調べる必要がなくなる
* Block がコンテキストを持ってくれるので、`context` オブジェクトを作成したり、`context` オブジェクトから情報を取得する必要がなくなる


### <a id="StopObservingSimply"></a>監視停止を簡潔にする機能
　REObserver を使うと、監視の停止は `-stopObserving` メソッドを呼び出すだけになる：

```objective-c
[observer stopObserving];
```

　これで `observer` はすべての監視を停止する。監視されているオブジェクト、キーパス、コンテキストたちを覚えておかなくても監視を停止することができるので簡潔だ。

### <a id="AutomaticObservationStop"></a>自動で監視を停止する機能
　REObserver は、監視しているオブジェクト／監視されているオブジェクトいずれかが解放される際、関連する監視を自動で停止する。以下のコードに見るような、ゾンビから監視されたりゾンビを監視する問題がなくなる (以下は非 ARC コード)：

```objective-c
- (void)problem1
{
	UIView *view;
	view = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
	@autoreleasepool {
		id observer;
		observer = [[[NSObject alloc] init] autorelease];
		[view addObserver:observer forKeyPath:@"backgroundColor" options:0 context:nil];
	}
	NSLog(@"observationInfo = %@", (id)[view observationInfo]); // view is observed by zombie!
	view.backgroundColor = [UIColor redColor]; // Crash!
}

- (void)problem2
{
	id observer;
	observer = [[[NSObject alloc] init] autorelease];
	@autoreleasepool {
		UIView *view;
		view = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
		[view addObserver:observer forKeyPath:@"backgroundColor" options:0 context:nil];
	}
	// observer is observing zombie!
}
```


## 動作環境
iOS 5.0 以降

OS X 10.7 以降



## ライセンス
MIT ライセンス。詳細は LICENSE ファイルを参照。
