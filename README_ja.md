REKit
=====
　REKit (リキット) は NSObject 拡張のコレクションで、現時点で 2 つの機能を提供する：

1. [**REResponder**](#REResponder): Block を使った、クラスレベル／インスタンスレベルでの動的メソッド実装／上書き機能
2. [**REObserver**](#REObserver): Block を使って KVO  (Key-Value Observing) を実現する機能 + α


## <a id="REResponder"></a>REResponder
　REResponder は、Block を使った、クラスレベル／インスタンスレベルでの動的メソッド実装／上書き機能を提供する。


### <a id="SetBlock"></a>動的メソッド実装／上書き

　`RESetBlock()` にセレクタや Block を渡すと、動的にメソッド実装／上書きができる。

```objective-c
id obj;
obj = [[NSObject alloc] init];
RESetBlock(obj, @selector(sayHello), NO, nil, ^(id obj) {
	NSLog(@"Hello World!");
});
[obj performSelector:@selector(sayHello)]; // Hello World!
```

　`RESetBlock()` の第1引数をクラスにすればクラスレベルでのメソッド実装／上書きになり、そのクラスの全インスタンスに影響する。第1引数をインスタンスにすればインスタンスレベルでのメソッド実装／上書きとなり、そのインスタンスのみに影響する。クラスレベルでのクラスメソッドの実装／上書きもサポートする。

### <a id="supermethod"></a>supermethod の呼び出し
　`RESupermethod()` を使うと、より以前に追加された Block による実装、あるいはハードコーディングされた実装 (supermethod) を呼び出すことができる。

```objective-c
id obj;
obj = [[NSObject alloc] init];
RESetBlock(obj, @selector(description), NO, nil, ^(id obj) {
	// Get originalDescription
	NSString *originalDescription;
	originalDescription = RESupermethod(@"", obj);
	
	// Make customizedDescription…
	
	return customizedDescription;
});
```

　呼び出される実装の順番は、早い方から 1)REKit により追加されたインスタンスレベルでの実装 2)REKit により追加されたクラスレベルでの実装 3)ハードコーディングされた実装 4)REKit によりスーパークラスに追加された実装 5)スーパークラスでハードコーディングされた実装‥‥といった感じに続く。

### <a id="REResponderExamples"></a>活用例
- `UIAlertView` のデリゲートメソッド `alertView:didDismissWithButtonIndex:` を `UIAlertView` のインスタンス自身に実装させる
- `UIButton` のアクションを、`UIButton` のインスタンス自身に実装させる
- サブクラスを作るまでもないカスタマイズを、特定のインスタンスに施す
- `delegate` が既にいて他に動かせない場合に、`delegate` をハックする
- 機能・関心を、コード上の一箇所にまとめる
- 再利用可能な機能・関心を、クラスやインスタンスに動的に追加する
- UnitTest で、モックオブジェクトの生成や、ハイコストな処理のスタブ化に使う


## <a id="REObserver"></a>REObserver

REObserver は、KVO (Key-Value Observing) に以下の機能を付加する NSObject の拡張である：

1. [**Block を使って KVO を実現する機能**](#KVOWithBlock)
2. [**監視停止を簡潔にする機能**](#StopObservingSimply)
3. [**自動で監視を停止する機能**](#AutomaticObservationStop)


### <a id="KVOWithBlock"></a>Block を使って KVO を実現する機能
　REObserver を使うと、監視を開始すると同時に、通知が来た時に行う処理を Block で指定できるようになる：

```objective-c
id observer;
observer = [obj addObserverForKeyPath:@"someKeyPath" options:0 usingBlock:^(NSDictionary *change) {
	// Do something…
}];
```

### <a id="StopObservingSimply"></a>監視停止を簡潔にする機能
　REObserver を使うと、監視の停止は `-stopObserving` メソッドを呼び出すだけになる：

```objective-c
[observer stopObserving];
```

### <a id="AutomaticObservationStop"></a>自動で監視を停止する機能
　REObserver は、監視しているオブジェクト／監視されているオブジェクトいずれかが解放される際、関連する監視を自動で停止する。


## 動作環境
iOS 5.0 以降

OS X 10.7 以降


## インストール方法
REKit は [CocoaPods](http://cocoapods.org "CcooaPods") を使用してインストールすることができる。

&lt;Podfile for iOS&gt;

```
platform :ios, '5.0'
pod 'REKit'
```

&lt;Podfile for OS X&gt;

```
platform :osx, '10.7'
pod 'REKit'
```

&lt;Terminal&gt;

```
$ pod install
```

CocoaPods を使用しない場合は、REKit フォルダ以下のファイルをプロジェクトに追加する。


## ライセンス
MIT ライセンス。詳細は LICENSE ファイルを参照。
