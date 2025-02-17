package backend.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;
using haxe.macro.Tools;

typedef DataField = {
    name:String,
    type:ComplexType,
    ?expr:Expr,
    meta: Null<Metadata>
}

class ClassJson {
    public static function hasMeta(meta:Metadata, name:String):Bool {
        for(m in meta) {
            if(m.name == name) return true;
        }
        return false;
    }

    public static function build():Array<Field> {
        var fields = Context.getBuildFields();
		var clRef = Context.getLocalClass();
		if (clRef == null) return fields;
		var cl = clRef.get();
        var name = cl.name;

        var dataFields:Array<DataField> = [];
        for(field in fields) {
            switch(field.kind) {
                case FVar(t, e):
                    dataFields.push({
                        name: field.name,
                        type: t,
                        expr: e,
                        meta: field.meta
                    });
                default:
            }
        }

        function isSimple(expr:Expr):Bool {
            return switch(expr.expr) {
                case EConst(_): true;
                case EParenthesis(e): isSimple(e);
                case EBinop(_, e1, e2): isSimple(e1) && isSimple(e2);
                default: false;
            }
        }

        function getFromCall(expr:Expr, ct:ComplexType, field:DataField):Expr {
            for(meta in field.meta) {
                if(meta.name == ':dyn')
                    return Context.parse(ct.toString() + ".fromJson(" + expr.toString() + ")", Context.currentPos());
            }
            switch(ct) {
                default:
                    return macro $expr;
            }
        }

        function getToCall(expr:Expr, ct:ComplexType, field:DataField):Expr {
            for(meta in field.meta) {
                if(meta.name == ':dyn')
                    return Context.parse(ct.toString() + ".toJson(" + expr.toString() + ")", Context.currentPos());
            }
            switch(ct) {
                default:
                    return macro $expr;
            }
        }

        function buildFromJson(fields:Array<DataField>):Array<Expr> {
            var exprs = [];
            for(field in fields) {
                var name = field.name;
                var type = field.type;
                var expr = field.expr;
                switch(type) {
                    case TPath({name: 'Array', pack: [], params: [TPType(ct)]}):
                        exprs.push(macro @:mergeBlock {
                            if(Reflect.hasField(data, $v{name})) {
                                var value:Array<Dynamic> = Reflect.field(data, $v{name});
                                obj.$name = [for(v in value) ${getFromCall(macro v, ct, field)}];
                            }
                        });
                    case TPath({name: 'Map', pack: [], params: [TPType(k), TPType(v)]}) | TPath({name: 'Map', pack: ["haxe", "ds"], params: [TPType(k), TPType(v)]}):
                        exprs.push(macro @:mergeBlock {
                            if(Reflect.hasField(data, $v{name})) {
                                var value:Dynamic = Reflect.field(data, $v{name});
                                obj.$name = [for(k in Reflect.fields(value)) {
                                    var v = Reflect.field(value, k);
                                    k => ${getFromCall(macro v, v, field)}
                                }];
                            }
                        });
                    case TPath(p) if (hasMeta(field.meta, ':dyn')):
                        exprs.push(macro @:mergeBlock {
                            if(Reflect.hasField(data, $v{name})) {
                                var value = Reflect.field(data, $v{name});
                                obj.$name = ${getFromCall(macro value, type, field)};
                            }
                        });
                    default:
                        exprs.push(macro @:mergeBlock {
                            if(Reflect.hasField(data, $v{name})) {
                                obj.$name = Reflect.field(data, $v{name});
                            }
                        });
                }
            }
            return exprs;
        }

        function buildToJson(fields:Array<DataField>):Array<Expr> {
            var exprs = [];
            for(field in fields) {
                var name = field.name;
                var type = field.type;
                var expr = field.expr;
                switch(type) {
                    case TPath({name: 'Array', pack: [], params: [TPType(ct)]}):
                        exprs.push(macro @:mergeBlock {
                            //if(obj.$name != null) {
                                data.$name = [for(v in obj.$name) ${getToCall(macro v, ct, field)}];
                            //}
                        });
                    case TPath({name: 'Map', pack: [], params: [TPType(k), TPType(v)]}) | TPath({name: 'Map', pack: ["haxe", "ds"], params: [TPType(k), TPType(v)]}):
                        exprs.push(macro @:mergeBlock {
                            //if(obj.$name != null) {
                                var value = {};
                                for(k => v in obj.$name) {
                                    Reflect.setField(value, k, ${getToCall(macro v, v, field)});
                                }
                                data.$name = value;
                            //}
                        });
                    case TPath(p) if (hasMeta(field.meta, ':dyn')):
                        exprs.push(macro @:mergeBlock {
                            //if(obj.$name != null) {
                                data.$name = ${getToCall(macro obj.$name, type, field)};
                            //}
                        });
                    case _ if (field.expr != null && isSimple(field.expr)):
                        exprs.push(macro @:mergeBlock {
                            if(obj.$name != ${field.expr}) {
                                data.$name = obj.$name;
                            }
                        });
                    default:
                        exprs.push(macro @:mergeBlock {
                            //if(obj.$name != null) {
                                data.$name = obj.$name;
                            //}
                        });
                }
            }
            return exprs;
        }

        //var init = Context.parse("var obj:" + name + " = new " + name + "()", Context.currentPos());

        var classType:TypePath = {name: name, pack: [], params: [], sub: null};
        var classCT = TPath(classType);

        var fromJson:Function = {
            args: [
                { name: 'data', type: macro:Dynamic }
            ],
            ret: null, // haxe infers the return type
            expr: (macro {
                //${init};
                var obj:$classCT = new $classType();
                @:mergeBlock $b{buildFromJson(dataFields)};
                return obj;
            }),
            params: null
        };

        var toJson:Function = {
            args: [
                { name: 'obj', type: classCT }
            ],
            ret: macro:Dynamic,
            expr: (macro {
                var data:Dynamic = {};
                @:mergeBlock $b{buildToJson(dataFields)};
                return data;
            }),
            params: null
        };

        fields.push({
            name: 'fromJson',
            pos: Context.currentPos(),
            kind: FFun(fromJson),
            access: [APublic, AStatic],
            meta: []
        });

        fields.push({
            name: 'toJson',
            pos: Context.currentPos(),
            kind: FFun(toJson),
            access: [APublic, AStatic],
            meta: []
        });

        //var printer = new haxe.macro.Printer();
        //trace(printer.printField(fields[fields.length - 1]));
        //trace(printer.printField(fields[fields.length - 2]));

        return fields;
    }
}