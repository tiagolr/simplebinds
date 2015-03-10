import haxe.unit.TestRunner;
import haxe.unit.TestCase;
import simple.bind.Dispatcher;
using Lambda;

/**
 * @author TiagoLr
 */
class Main {
	public static function main() {
		var r = new TestRunner();
		r.add(new Test());
		r.run();
	}
}

@:build(simple.bind.Macros.build())
class Test extends TestCase {
	
	@bind var noSetter:Int = 0;
	@bind var defSetter(default, default):String = "0";
	@bind var setter(default, set):String = "0";
	@bind var exprSetter(default, set):Int = 0;
	
	function set_setter( s:String ) {
		if (s == "pre") {
			setter = "at_middle_return";
			return s;
		}
		setter = s;
		return s;
	}
	
	function set_exprSetter( i: Int ) {
		if (i == 100)
			return exprSetter = i + 1;
		return exprSetter = i + 10;
	}
	
	public function new() {super();}
	
	public function test_no_getter_no_setter() {
		var gotSignal:Bool = false;
		Dispatcher.addListener(this, "noSetter", function( received:FieldChangeSignal ) {
			assertResult( { sender:this, field:"noSetter", from:0, to:100 } , received);
			gotSignal = true;
		});
		noSetter = 100;
		assertTrue(gotSignal);
		Dispatcher.removeListener(this, "noSetter");
	}
	
	public function test_default_setter() {
		var gotSignal:Bool = false;
		Dispatcher.addListener(this, "defSetter", function( received:FieldChangeSignal ) {
			assertResult( { sender:this, field:"defSetter", from:"0", to:"def" } , received);
			gotSignal = true;
		});
		defSetter = "def";
		assertTrue(gotSignal);
		Dispatcher.removeListener(this, "defSetter");
	}
	
	public function test_setter_return() {
		var gotSignal:Bool = false;
		Dispatcher.addListener(this, "setter", function( received:FieldChangeSignal ) {
			assertResult( { sender:this, field:"setter", from:"0", to:"normal" } , received);
			gotSignal = true;
		});
		setter = "normal";
		assertTrue(gotSignal);
		Dispatcher.removeListener(this, "setter");
		
		gotSignal = false;
		Dispatcher.addListener(this, "setter", function( received:FieldChangeSignal ) {
			assertResult( { sender:this, field:"setter", from:"normal", to:"at_middle_return" } , received);
			gotSignal = true;
		});
		setter = "pre";
		assertTrue(gotSignal);
		Dispatcher.removeListener(this, "setter");
	}
	
	public function test_setter_return_expr() {
		var gotSignal:Bool = false;
		Dispatcher.addListener(this, "exprSetter", function( received:FieldChangeSignal ) {
			assertResult( { sender:this, field:"exprSetter", from:0, to:20 } , received);
			gotSignal = true;
		});
		exprSetter = 10;
		assertTrue(gotSignal);
		Dispatcher.removeListener(this, "exprSetter");
		
		gotSignal = false;
		Dispatcher.addListener(this, "exprSetter", function( received:FieldChangeSignal ) {
			assertResult( { sender:this, field:"exprSetter", from:20, to:101 } , received);
			gotSignal = true;
		});
		exprSetter = 100;
		assertTrue(gotSignal);
		Dispatcher.removeListener(this, "exprSetter");
	}
	
	public function test_add_remove_listener() {
		Dispatcher.addListener(this, "noSetter", null);
		assertEquals(Dispatcher.listenersMap['noSetter'].length, 1);
		
		Dispatcher.removeListener(this, "noSetter");
		assertEquals(Dispatcher.listenersMap['noSetter'].length, 0);
	}
	
	public function test_getBindableFields() {
		var fields = Dispatcher.getBindableFields(this);
		assertEquals(fields.length, 4);
		assertTrue(fields.indexOf("noSetter") != -1);
		assertTrue(fields.indexOf("defSetter") != -1);
		assertTrue(fields.indexOf("setter") != -1);
		assertTrue(fields.indexOf("exprSetter") != -1);
		
		var fields = Dispatcher.getBindableFields(Test);
		assertEquals(fields.length, 4);
		assertTrue(fields.indexOf("noSetter") != -1);
		assertTrue(fields.indexOf("defSetter") != -1);
		assertTrue(fields.indexOf("setter") != -1);
		assertTrue(fields.indexOf("exprSetter") != -1);
	}
	
	function assertResult( expected:FieldChangeSignal, received:FieldChangeSignal) {
		assertEquals(expected.field, received.field);
		assertEquals(expected.from, received.from);
		assertEquals(expected.to, received.to);
		assertEquals(expected.sender, received.sender);
	}
	
}