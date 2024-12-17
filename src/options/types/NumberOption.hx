package options.types;

import flixel.math.FlxMath;

import options.types.BaseOption;

class NumberOption extends BaseOption<Float> {
    /**
     * Minimum (number) value the option can go to before looping back to `maximum`
    **/
    public var minimum:Float = 0.0;
    /**
     * Maximum (number) value the option can go to before looping back to `minimum`
    **/
    public var maximum:Float = 1.0;

    /**
     * Scroll Speed in the menus
    **/
    public var scrollSpeed:Float = 1.0;

    // just realised this would probably allow u to make something with scripts
    // lolll ! !! ! @IamMorwen
    public override function change(next:Float) {
        var prev = this.value;
        this.value = FlxMath.wrap(this.value + next, minimum, maximum);
        onChange(prev);
    }
}