REKit
=====
REKit [rikít] is a collection of extensions of `NSObject`.  Currently it provides 2 features:

1. [**REResponder**](#REResponder): provides ability to add/override methods at class/instance level
2. [**REObserver**](#REObserver): provides Blocks compatible method for KVO (Key-Value Coding) + α


## <a id="REResponder"></a>REResponder
REResponder provides ability to add/override methods at class/instance level. 


### <a id="SetBlock"></a>Adding/Overriding methods
You can add/override methods with `RESetBlock()`.

```objective-c
id obj;
obj = [[NSObject alloc] init];
RESetBlock(obj, @selector(sayHello), NO, nil, ^(id obj) {
	NSLog(@"Hello World!");
});
[obj performSelector:@selector(sayHello)]; // Hello World!
```

If you pass Class to `RESetBlock()` as first argument, the implementation affect all instances of the class.  If you pass an instance, the implementation affect the instance only.  Adding/Overriding class methods are also supported.


### <a id="supermethod"></a>supermethod
You can call previously-added/overridden implementation or hard-coded implementation, using `RESupermethod()`.

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

Priority of implementations are 1)Instance-level Block implementation 2)Class-level Block implementation 3)Hard-coded implementation 4)Class-level Block implementation of superclass 5)Hard-coded implementation of superclass, and so on.


### <a id="Examples"></a>Usage Examples
- Add implementation of `alertView:didDismissWithButtonIndex:` to an instance of UIAlertView.
- Add implementation of action to an instance of UIButton.
- Customize an instance without subclassing.
- Gather code fragments about a feature/concern.
- Add reusable features to classes and instances.
- In UnitTest, make mock objects, and stub high cost operations out.


## <a id="REObserver"></a>REObserver
REObserver provides:

1. [**Blocks compatible method for KVO**](#KVOWithBlock)
2. [**Simple method to stop observing**](#StopObservingSimply)
3. [**Automatic observation stop system**](#AutomaticObservationStop)


### <a id="KVOWithBlock"></a>Blocks compatible method for KVO
REObserver provides `-addObserverForKeyPath:options:usingBlock:` method. You can pass a block to be executed when the value is changed:

```objective-c
id observer;
observer = [obj addObserverForKeyPath:@"someKeyPath" options:0 usingBlock:^(NSDictionary *change) {
	// Do something…
}];
```

### <a id="StopObservingSimply"></a>Simple method to stop observing
You can stop observing simply with `-stopObserving` method:

```objective-c
[observer stopObserving];
```

### <a id="AutomaticObservationStop"></a>Automatic observation stop system
When observed object or observing object is released, REObserver stops related observations automatically.


## Availability
iOS 5.0 and later

OS X 10.7 and later


## Installation
You can install REKit using [CocoaPods](http://cocoapods.org "CcooaPods").

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

If you want to install REKit manually, add files which is under REKit folder to your project.


## License
MIT License. For more detail, read LICENSE file.
