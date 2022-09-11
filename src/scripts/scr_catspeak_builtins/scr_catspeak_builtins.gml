//! Defines the standard library functions of the Catspeak prelude.

//# feather use syntax-errors

/// Returns the value of a built-in Catspeak constant, if one exists.
/// Returns `undefined` if a built-in couldn't be found.
///
/// @param {String} name
///   The name of the built-in to find.
///
/// @return {Any}
function catspeak_string_to_builtin(name) {
    gml_pragma("forceinline");
    return global.__catspeakDatabasePrelude[$ name];
}

/// Returns whether this string represents a built-in Catspeak constant.
///
/// @param {String} name
///   The name of the built-in to find.
///
/// @return {Bool}
function catspeak_string_is_builtin(name) {
    gml_pragma("forceinline");
    return variable_struct_exists(global.__catspeakDatabasePrelude, name);
}

/// @ignore
function __catspeak_builtin_add(lhs, rhs) {
    return rhs == undefined ? +lhs : lhs + rhs;
}

/// @ignore
function __catspeak_builtin_add_string(lhs, rhs) {
    var lhs_ = is_string(lhs) ? lhs : string(lhs);
    var rhs_ = is_string(rhs) ? rhs : string(rhs);
    return lhs_ + rhs_;
}

/// @ignore
function __catspeak_builtin_sub(lhs, rhs) {
    return rhs == undefined ? -lhs : lhs - rhs;
}

/// @ignore
function __catspeak_builtin_mul(lhs, rhs) {
    return lhs * rhs;
}

/// @ignore
function __catspeak_builtin_div(lhs, rhs) {
    return lhs / rhs;
}

/// @ignore
function __catspeak_builtin_mod(lhs, rhs) {
    return lhs % rhs;
}

/// @ignore
function  __catspeak_builtin_div_int(lhs, rhs) {
    return lhs div rhs;
}

/// @ignore
function __catspeak_builtin_bit_or(lhs, rhs) {
    return lhs | rhs;
}

/// @ignore
function __catspeak_builtin_bit_and(lhs, rhs) {
    return lhs & rhs;
}

/// @ignore
function __catspeak_builtin_bit_xor(lhs, rhs) {
    return lhs ^ rhs;
}

/// @ignore
function __catspeak_builtin_bit_not(lhs) {
    return ~lhs;
}

/// @ignore
function  __catspeak_builtin_bit_lshift(lhs, rhs) {
    return lhs << rhs;
}

/// @ignore
function  __catspeak_builtin_bit_rshift(lhs, rhs) {
    return lhs >> rhs;
}

/// @ignore
function  __catspeak_builtin_or(lhs, rhs) {
    return lhs || rhs;
}

/// @ignore
function  __catspeak_builtin_and(lhs, rhs) {
    return lhs && rhs;
}

/// @ignore
function  __catspeak_builtin_xor(lhs, rhs) {
    return lhs ^^ rhs;
}

/// @ignore
function __catspeak_builtin_not(lhs) {
    return !lhs;
}

/// @ignore
function  __catspeak_builtin_eq(lhs, rhs) {
    return lhs == rhs;
}

/// @ignore
function  __catspeak_builtin_neq(lhs, rhs) {
    return lhs != rhs;
}

/// @ignore
function  __catspeak_builtin_geq(lhs, rhs) {
    return lhs >= rhs;
}

/// @ignore
function  __catspeak_builtin_leq(lhs, rhs) {
    return lhs <= rhs;
}

/// @ignore
function __catspeak_builtin_gt(lhs, rhs) {
    return lhs > rhs;
}

/// @ignore
function __catspeak_builtin_lt(lhs, rhs) {
    return lhs < rhs;
}

/// @ignore
function __catspeak_builtin_array() {
    var arr = array_create(argument_count);
    for (var i = 0; i < argument_count; i += 1) {
        arr[i] = argument[i];
    }
    return arr;
}

/// @ignore
function __catspeak_builtin_struct() {
    var obj = { };
    for (var i = 0; i < argument_count; i += 2) {
        obj[$ argument[i + 0]] = argument[i + 1];
    }
    return obj;
}

/// @ignore
function __catspeak_builtin_get(collection, key) {
    if (is_array(collection)) {
        if (key < 0 || key >= array_length(collection)) {
            return undefined;
        } else {
            return collection[key];
        }
    } else {
        __catspeak_builtin_verify_struct(collection);
        return collection[$ key];
    }
}

/// @ignore
function __catspeak_builtin_set(collection, key, value) {
    if (is_array(collection)) {
        collection[@ key] = value;
    } else {
        __catspeak_verify_struct(collection);
        collection[$ key] = value;
    }
    return value;
}

/// @ignore
function __catspeak_builtin_verify_struct(collection) {
    gml_pragma("forceinline");
    if (string_pos("Catspeak", instanceof(collection)) == 1) {
        throw new CatspeakError(undefined,
                "self-modification is prohibited by Catspeak");
    }
}

/// @ignore
function __catspeak_builtin_extern(ir) {
    var vm = new CatspeakVM();
    vm.pushCallFrame(self, ir);
    vm.popCallFrame();
    var s = {
        duration : game_get_speed(gamespeed_microseconds) / 10,
        vm : vm,
        argc : ir.argCount,
        args : array_create(ir.argCount),
        go : function() {
            // extern functions compute everything in one go
            // TODO add a limiter so that modders cannot freeze the game
            var vm_ = vm;
            var argc_ = argc;
            var args_ = args;
            for (var i = 0; i < argc_; i += 1) {
                args_[@ i] = argument[i];
            }
            vm_.reuseCallFrameWithArgs(args_, 0, argc_);
            var timeLimit = get_timer() + duration;
            while (vm_.inProgress()) {
                vm_.runProgram(10);
                if (get_timer() > timeLimit) {
                    throw new CatspeakError(undefined,
                            "execution limit exceeded on Catspeak function");
                }
            }
            return vm_.returnValue;
        },
    };
    return s.go;
}