Simplebinds is an haxelib that provides an easy way to listen to events when variable values are changed.

##Example
```haxe
@:build(simple.bind.Macros.build())
class MyClass {
	@bind public var someVar:Int = 0;
}

class OtherClass {

	public function new() {
		var instance = new MyClass();
		simple.bind.Dispatcher.addListener(instance, "someVar", onVarChanged);
		instance.someVar = 100;
	}
	
	function onVarChanged(signal:{}) {
		trace(Std.is(signal.sender, MyClass));
		trace('${signal.field} changed from: ${signal.from} to ${signal.to});
	}
}
```
outputs:<br>
```
true
someVar changed from 0 to 100
```

###Whats it useful for?
For example to update ui components or visualizers when data changes, it's the main reason this library was made.

###How it works?

```@build(simple.bind.Macros.build())``` and ```@bind``` metadata, create a call to ```Dispatcher.dispatch()``` during compile before the return of the variable setter. If the variable has no setter it create a new one.

###Wait, where is the two-way binding in this?

There isn't, however it provides a base where the two way binding can be created by listening to variable change events like the high-tech example above.

###Tested targets:
- js
- cpp
- neko
- flash

###Todo:

* See if its feasable to bind a parent class field, this would be very useful for example to listen to a openfl ```DisplayObject``` children ```x``` or ```y``` changes.