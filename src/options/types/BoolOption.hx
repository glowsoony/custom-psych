package options.types;

import flixel.math.FlxMath;
import options.types.BaseOption;

class BoolOption extends BaseOption<Bool, Bool>
{
	/**
	 * @param name          Option Name in the options menu
	 * @param description   Descriptor for what the option does
	 * @param preference    Name of the preference it modifies (in backend.Settings)
	**/
	public function new(name:String, ?description:String, ?preference:String)
	{
		super(name, description, preference);
		this.change = _change;
	}

	private function _change(next:Bool):Void
	{
		var prev:Bool = this.value;
		this.value = next;
		onChange(prev);
	}
}
