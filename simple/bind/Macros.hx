package simple.bind;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Field;
import haxe.macro.Expr.Function;
using Lambda;
using tink.MacroApi;
/**
 * simplebind Macros
 * @author TiagoLr
 */
class Macros{

	public static function build():Array<Field> {
		var fields:Array<Field> = Context.getBuildFields();
		var newFields = new Array<Field>();
		
		for (field in fields) {
			for (meta in field.meta) {
				if (meta.name == "bind") {
					switch (field.kind) {
						/** 
							If the field is a variable (no getter/setter), then create a setter to it that calls 
							the dispatcher when the variable is set.
						**/
						case FVar(varType, e):
							field.meta.push({name:":isVar", pos: Context.currentPos()});
							field.kind = FieldType.FProp("default", "set", varType, e);
							newFields.push(generateSetter(field, varType));
							
						/** 
							If its a property with getter and setter, modify the setter, adding a dispatcher call before 
							any return statement.
						**/
						case FProp(get, set, varType, e):
							switch(set) {
								case "never", "dynamic", "null":
									Context.error('can\'t bind "$set" with null access.', field.pos);
								
								case "default":
									field.kind = FProp(get, "set", varType, e);
									newFields.push(generateSetter(field, varType));
									
								case "set":
									var methodName = "set_" + field.name;
									var setter = null;
									for (f in fields) if (f.name == methodName) {
										setter = f;
										break;
									}
									if (setter == null) 
										Context.error("can't find setter: " + methodName, field.pos);
										
									switch (setter.kind) {
										case FFun(fn):
											setterField = fn.args[0].name;
											fieldName = field.name;
											variableRef = field.name.resolve();
											
											// store the current field value at the beggining of the setter
											switch (fn.expr.expr) {
												case EBlock(exprs):
													exprs.unshift(macro var __from__ = $variableRef);
												case _:
											}
											
											// recursivelly add a dispatch call before return statements.
											fn.expr = fn.expr.map(addDispatcherCall);
											
										case _: Context.error("setter must be function", setter.pos);
									}
								
							}
							
						case _: null;
					}
				}
			}
		}
		
		for (newField in newFields)
			fields.push(newField);
		
		return fields;
	}
	
	static function generateSetter(field:Field, varType:Null<ComplexType>):Field {
		var variableRef = field.name.resolve();
		var setterBody = macro {
			var __from__ = $variableRef;
			$variableRef = v;
			simple.bind.Dispatcher.dispatch(this, $v { field.name }, __from__, v);
			return $variableRef;
		};
		return {
			pos: Context.currentPos(),
			name: "set_" + field.name,
			access: [APrivate],
			meta: [],
			kind: FieldType.FFun({
					ret: varType,
					params: [],
					expr: setterBody,
					args: [{
						value: null,
						type: varType,
						opt: false,
						name: "v"
					}]
				}),
			doc: ""
		};
		return null;
	}
	
	static var setterField:String;
	static var variableRef:Dynamic;
	static var fieldName:String;
	/** 
		Recursively visits expressions and adds a dispatcher call before any `return` statement.
		If the returned value is an expression, the expression is added before the dispatch and return calls.
	**/
	static function addDispatcherCall(expr:Expr):Expr {
		return switch (expr.expr) {
			case EReturn(e) :
				if (e == null) Context.error("setter must return value", expr.pos);
				switch (e.expr) {
					case EConst(c):
						macro {
							simple.bind.Dispatcher.dispatch(this, $v{ fieldName }, $i{'__from__'} , $variableRef ); 
							return $e;
						}
					case _:
						macro {
							${e.map(addDispatcherCall)};
							simple.bind.Dispatcher.dispatch(this, $v{ fieldName }, $i{'__from__'} , $variableRef ); 
							return $i{setterField};
						}
				}
			case _: expr.map(addDispatcherCall);
		}
		return null;
	}
	
}