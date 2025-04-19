package options.types;

import flixel.math.FlxMath;
import options.types.BaseOption;

class ChoiceOption extends BaseOption<String, Int>
{
	public var options:Array<String> = null;

	/**
	 * @param name          Option Name in the options menu
	 * @param description   Descriptor for what the option does
	 * @param preference    Name of the preference it modifies (in backend.Settings)
	 * @param options       Choice names in the options menu
	**/
	public function new(name:String, ?description:String, ?preference:String, ?options:Array<String>)
	{
		super(name, description, preference);
		this.options = options ?? [];
		this.change = _change;
	}

	private function _change(next:Int)
	{
		if (this.options == null || this.options.length == 0)
			return;
		var prev:String = this.value;
		var next:Int = FlxMath.wrap(this.options.indexOf(this.value) + next, 0, this.options.length - 1);
		this.value = options[next];
		onChange(prev);
	}
}
