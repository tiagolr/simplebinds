package simple.bind;
import haxe.rtti.Meta;

typedef Listener = {
	object:Dynamic,
	field:String,
	cbk:FieldChangeSignal->Void,
}

typedef FieldChangeSignal = {
	sender:Dynamic,
	field:String,
	from:Dynamic,
	to:Dynamic
}

/**
 * simplebind Dispatcher
 * @author TiagoLr
 */
class Dispatcher {
	
	/** Events are only fired when the value before and after the set is different - default is true */
	public static var ignoreUnchanged:Bool = true;
	public static var listenersMap(default, null):Map<String, Array<Listener>> = new Map<String, Array<Listener>>();
	
	public static function addListener(object:Dynamic, field:String, callBack:FieldChangeSignal->Void) {
		var listeners = listenersMap[field];
		
		if (listeners == null) {
			listeners = new Array<Listener>();
			listenersMap[field] = listeners;
		}
		
		if (getListener(object, field, callBack) == null) {
			listeners.push( { object:object, field:field, cbk:callBack });
		}
	}
	
	public static function removeListener(object:Dynamic, field:String, ?callback:FieldChangeSignal->Void) {
		if (callback != null) {
			var l = getListener(object, field, callback);
			if (l != null) {
				listenersMap[field].remove(l);
			}
		} else {
			var ls = listenersMap[field];
			if (ls != null) {
				var tmp:Array<Listener> = new Array<Listener>();
				for (l in ls) {
					if (l.object != object) {
						tmp.push(object);
					}
				}
				listenersMap[field] = tmp;
			}
		}
	}
	
	/** 
		Returns a list of the field names that dispatch events when they are set.
	**/
	public static function getBindableFields(objectOrClass:Dynamic):Array<String> {
		if (!Std.is(objectOrClass, Class)) {
			objectOrClass = Type.getClass(objectOrClass);
		}
		
		var fields = Type.getInstanceFields(objectOrClass);
		var meta = Meta.getFields(objectOrClass);
		var binded = new Array<String>();
		
		for (f in fields) {
			try {
				var m = Reflect.getProperty(meta, f);
				if (m != null)
					binded.push(f);
			} catch (e:Dynamic) {
				continue;
			}
		}
		
		return binded;
	}
	
	public static function getListener(object:Dynamic, field:String, callBack:FieldChangeSignal->Void):Listener {
		var listeners = listenersMap[field];
		if (listeners == null) return null;
		
		for (l in listeners) {
			if (l.object == object && l.field == field && l.cbk == callBack) {
				return l;
			}
		}
		return null;
	}
	
	public static function dispatch(object:Dynamic, field:String, from:Dynamic, to:Dynamic) {
		var listeners = listenersMap[field];
		
		if ( (ignoreUnchanged && from == to) || listeners == null || listeners.length == 0) 
			return;
		
		for (l in listeners) {
			if (l.object == object) {
				l.cbk( { sender:object, field:field, from:from, to:to } );
			}
		}
	}
	
	
}


