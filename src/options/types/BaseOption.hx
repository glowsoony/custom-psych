package options.types;

class BaseOption {
    /**
     * Option Name in the options menu
    **/
    public var name:String = "Unknown";

    /**
     * Descriptor for what the option does
    **/
    public var description:String = "This option may or may not do something";

    /**
     * Name of the preference it modifies (in backend.Settings)
    **/
    public var attachedPref:String = null;

    /**
     * Its (current) value
    **/
    public var value:Any = null;

    /**
     * How the value gets displayed in the options menu
     * e.g: `%vms` -> 166.67ms
    **/
    public var valueDisplay:String = "%v";

    /**
     * Used as a sanity-check to see if it can actually be modified
    **/
    public var canChange:Bool = false;

    /**
     * Contains the original value of the option (used for when pressing R while hovering over it)
    **/
    var defaultValue:Any = null;

    /**
     * @param name          Option Name in the options menu
     * @param description   Descriptor for what the option does
     * @param preference    Name of the preference it modifies (in backend.Settings)
    **/
    public function new(name:String, ?description:String, ?preference:String) {
        this.name = name;
        this.description = description;
        this.attachedPref = preference;

        defaultValue = Reflect.field(backend.Settings.default_data, attachedPref);
        value = Reflect.field(backend.Settings.data, attachedPref);
        canChange = this.defaultValue != null;
    }

    public function change(value:Any) {
        var prev = value;
        this.value = value;
        onChange(prev);
    }

    public dynamic function onHover() {}
    public dynamic function onChange(previousValue:Any) {}

    public inline function getDefaultValue()
        return defaultValue;
}