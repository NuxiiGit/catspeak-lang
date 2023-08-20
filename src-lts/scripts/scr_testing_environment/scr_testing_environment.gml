
//# feather use syntax-errors

test_add(function () : Test("engine-tokenise") constructor {
    var engine = new CatspeakEnvironment();
    var buff = __catspeak_create_buffer_from_string(@'hello.world');
    var lexer = engine.tokenise(buff);
    assertEq(CatspeakToken.IDENT, lexer.next());
    assertEq("hello", lexer.getLexeme());
    assertEq(CatspeakToken.DOT, lexer.next());
    assertEq(".", lexer.getLexeme());
    assertEq(CatspeakToken.IDENT, lexer.next());
    assertEq("world", lexer.getLexeme());
    assertEq(CatspeakToken.EOF, lexer.next());
    buffer_delete(buff);
});

test_add(function () : Test("engine-tokenise-2") constructor {
    var engine = new CatspeakEnvironment();
    var buff = __catspeak_create_buffer_from_string(@'hello.world');
    var lexer = engine.tokenise(buff, 3, 5);
    assertEq(CatspeakToken.IDENT, lexer.next());
    assertEq("lo", lexer.getLexeme());
    assertEq(CatspeakToken.DOT, lexer.next());
    assertEq(".", lexer.getLexeme());
    assertEq(CatspeakToken.IDENT, lexer.next());
    assertEq("wo", lexer.getLexeme());
    assertEq(CatspeakToken.EOF, lexer.next());
    buffer_delete(buff);
});

test_add(function () : Test("engine-tokenise-keywords") constructor {
    var engine = new CatspeakEnvironment();
    engine.renameKeyword("while", "world");
    var buff = __catspeak_create_buffer_from_string(@'hello.world');
    var lexer = engine.tokenise(buff);
    assertEq(CatspeakToken.IDENT, lexer.next());
    assertEq("hello", lexer.getLexeme());
    assertEq(CatspeakToken.DOT, lexer.next());
    assertEq(".", lexer.getLexeme());
    assertEq(CatspeakToken.WHILE, lexer.next());
    assertEq("world", lexer.getLexeme());
    assertEq(CatspeakToken.EOF, lexer.next());
    buffer_delete(buff);
});

test_add(function () : Test("engine-self-inst") constructor {
    var engine = new CatspeakEnvironment();
    var asg = engine.parseString(@'self');
    var gmlFunc = engine.compileGML(asg);
    var inst = instance_create_depth(0, 0, 0, obj_unit_test_inst);
    gmlFunc.setSelf(inst);
    assertEq(catspeak_special_to_struct(inst), gmlFunc());
    instance_destroy(inst);
});

test_add(function () : Test("engine-global-shared") constructor {
    var engine = new CatspeakEnvironment();
    var fA = engine.compileGML(engine.parseString(@'globalvar = 1;'));
    var fB = engine.compileGML(engine.parseString(@'globalvar'));
    var s = { };
    fA.setGlobals(s);
    fB.setGlobals(s);
    fA();
    assertEq(1, fB());
});

test_add(function () : Test("engine-global-shared-2") constructor {
    var engine = new CatspeakEnvironment();
    engine.enableSharedGlobal(true);
    var fA = engine.compileGML(engine.parseString(@'globalvar = 1;'));
    var fB = engine.compileGML(engine.parseString(@'globalvar'));
    fA();
    assertEq(1, fB());
});

test_add(function () : Test("engine-delete-keyword") constructor {
    var engine = new CatspeakEnvironment();
    engine.removeKeyword("fun");
    var buff = __catspeak_create_buffer_from_string("fun");
    var lexer = engine.tokenise(buff);
    assertEq(CatspeakToken.IDENT, lexer.next());
    assertEq("fun", lexer.getLexeme());
    assertEq("fun", lexer.getValue());
    buffer_delete(buff);
});

test_add(function () : Test("engine-struct-not-terminated") constructor {
    var engine = new CatspeakEnvironment();
    var asg = engine.parseString(@'
        return {
            foo: "bar",
            a_number: 0,
            a_string: "Hello World!"
        }
    ');
    var func = engine.compileGML(asg);
    var result = func();
    assertEq(result, { foo : "bar", a_number : 0, a_string : "Hello World!" });
});

test_add(function () : Test("engine-function-brace-style") constructor {
    var engine = new CatspeakEnvironment();
    var fA = engine.compileGML(engine.parseString(@'
        main = fun()
        {
            return "hi"
        }
    '));
    var fB = engine.compileGML(engine.parseString(@'
        main = fun() {
            return "hi"
        }
    '));
    fA();
    fB();
    assertEq(fA.getGlobals().main(), fB.getGlobals().main());
    assertEq("hi", fA.getGlobals().main());
    assertEq("hi", fB.getGlobals().main());
});

test_add(function () : Test("engine-use-test") constructor {
    msg = "start";
    var engine = new CatspeakEnvironment();
    engine.addMethod("thing", function () {
        msg = "inside";
        return function () { msg = "end" };
    });
    engine.addMethod("get_msg", function () {
        return msg;
    });
    var fA = engine.compileGML(engine.parseString(@'
        let a = get_msg();
        let b;
        use thing {
            b = get_msg();
        }
        let c = get_msg();
        [a, b, c]
    '));
    assertEq(["start", "inside", "end"], fA());
});

test_add(function () : Test("engine-function-set-self") constructor {
    var engine = new CatspeakEnvironment();
    var f = engine.compileGML(engine.parseString(@'
        return fun { self };
    '));
    var fun = f();
    fun.setSelf({ hi : "hi" });
    assertEq("hi", fun().hi);
});

function EngineFunctionMethodCallTest__Construct() constructor {
    // this is part of the below test, but needs to live in global scope
    // otherwise the name will be mangled
    str = "";
    static add = function(_str) {
        str += string(_str);
    }
}
test_add(function () : Test("engine-function-method-call") constructor {
    var engine = new CatspeakEnvironment();
    engine.addFunction("Construct", function() {
        return new EngineFunctionMethodCallTest__Construct();
    });
    var f = engine.compileGML(engine.parseString(@'
        let _inst = Construct();
        _inst.add("Woo!");
        _inst.add("Yeehaw!");
        _inst
    '));
    var inst = f();
    assertEq("EngineFunctionMethodCallTest__Construct", instanceof(inst));
    assertEq("Woo!Yeehaw!", inst.str);
});

test_add(function () : Test("global-custom-presets") constructor {
    catspeak_preset_add("test-preset", function (env) {
        env.addFunction("double", function (n) { return 2 * n });
    });
    var engine = new CatspeakEnvironment();
    engine.applyPreset("test-preset");
    var f = engine.compileGML(engine.parseString(@'
        return double(103);
    '));
    assertEq(2 * 103, f());
});

test_add(function () : Test("engine-properties") constructor {
    var engine = new CatspeakEnvironment();
    var f = engine.compileGML(engine.parseString(@'
        let some_property = fun { 620 }

        return :some_property + 2 * :some_property
    '));
    assertEq(620 + 2 * 620, f());
});

test_add(function () : Test("engine-properties-2") constructor {
    var engine = new CatspeakEnvironment();
    var f = engine.compileGML(engine.parseString(@'
        count = 1
        let counter = fun {
            let res = count
            count *= 2
            return res
        }

        let a = :counter
        let b = :counter
        let c = :counter
        return { a, b, c }
    '));
    var result = f();
    assertEq(1, result.a);
    assertEq(2, result.b);
    assertEq(4, result.c);
});

test_add(function () : Test("engine-properties-get-set") constructor {
    var engine = new CatspeakEnvironment();
    var f = engine.compileGML(engine.parseString(@'
        value = 0
        let double = fun (x) {
            if x == undefined { value } else { value = 2 * x }
        }

        :double = 8
        let a = :double

        :double += 6
        let b = :double + :double

        return [a, b]
    '));
    var result = f();
    assertEq(2 * 8, result[0]);
    assertEq(2 * (2 * 8 + 6) + 2 * (2 * 8 + 6), result[1]);
});

test_add(function () : Test("engine-pipe-left") constructor {
    var engine = new CatspeakEnvironment();
    var f = engine.compileGML(engine.parseString(@'
        let f = fun (x) { return x * 2 }
        f <| 7
    '));
    assertEq(7 * 2, f());
});

test_add(function () : Test("engine-pipe-right") constructor {
    var engine = new CatspeakEnvironment();
    var f = engine.compileGML(engine.parseString(@'
        let f = fun (x) { return x + "world" }
        "hello" |> f
    '));
    assertEq("helloworld", f());
});

test_add_ignore(function () : Test("engine-gm-asset") constructor {
    var engine = new CatspeakEnvironment();
    engine.addFunction("font_exists", font_exists);
    engine.addGMAsset("fnt_testing");
    var asg = engine.parseString(@'
        return font_exists(fnt_testing);
    ');
    var func = engine.compileGML(asg);
    var result = func();
    assertEq(true, result);
});

test_add_ignore(function () : Test("engine-gml-function") constructor {
    var engine = new CatspeakEnvironment();
    engine.addGMLFunction(is_string);
    var asg = engine.parseString(@'
        return is_string("Hello World!");
    ');
    var func = engine.compileGML(asg);
    var result = func();
    assertEq(true, result);
});

test_add_ignore(function () : Test("engine-gml-function-by-substring") constructor {
    var engine = new CatspeakEnvironment();
    engine.addGMLFunctionBySubstring("test_array");
    var asg = engine.parseString(@'
        let array = [2, 2, 4];
        return test_array_sum(array);
    ');
    var func = engine.compileGML(asg);
    var result = func();
    assertEq(8, result);
});

test_add_ignore(function () : Test("engine-gml-function-by-substring-exist") constructor {
    var engine = new CatspeakEnvironment();
    engine.addGMLFunctionBySubstring("test_array");
    var asg = engine.parseString(@'
        return [
            test_array_sum,
            test_array_min,
            test_array_max,
            test_array_mean,
            test_array_median,
        ];
    ');
    var func = engine.compileGML(asg);
    var result = func();
    assertNeq(undefined, result[0]);
    assertNeq(undefined, result[1]);
    assertNeq(undefined, result[2]);
    assertNeq(undefined, result[3]);
    assertNeq(undefined, result[4]);
    assert(is_method(result[0]));
    assert(is_method(result[1]));
    assert(is_method(result[2]));
    assert(is_method(result[3]));
    assert(is_method(result[4]));
});

test_add_ignore(function () : Test("engine-gml-function-by-substring-not-exist") constructor {
    var engine = new CatspeakEnvironment();
    engine.addGMLFunctionBySubstring("test_array");
    var asg = engine.parseString(@'
        return test_struct_create;
    ');
    var func = engine.compileGML(asg);
    var result = func();
    assertEq(undefined, result);
    assert(!is_method(result));
});

test_add(function () : Test("engine-object-index") constructor {
    try {
        instance_create_depth(0, 0, 0, obj_unit_test_obj);
    } catch (e) {
        fail(e.message);
    }
});

test_add_force(function () : Test("engine-else-if") constructor {
    var engine = new CatspeakEnvironment();
    try {
        var asg = engine.parseString(@'
            a = 1
            if (a == 1) {

            } else if (a == 2) {

            }
        ');
        engine.compileGML(asg);
    } catch (e) {
        fail(e.message);
    }
});