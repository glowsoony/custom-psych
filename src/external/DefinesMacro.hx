package external;

// for grabbing a compiler define
// thanks ne_eo for giving me this :sob:

class DefinesMacro {
    public static var defines(get, null):Map<String, Dynamic>;

    // GETTERS
    private static inline function get_defines()
        return __getDefines();

    // INTERNAL MACROS
    private static macro function __getDefines() {
        #if display
        return macro $v{[]};
        #else
        return macro $v{haxe.macro.Context.getDefines()};
        #end
    }
}