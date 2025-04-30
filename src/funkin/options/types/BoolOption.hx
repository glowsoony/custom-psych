package funkin.options.types;

import funkin.options.types.BaseOption;

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
		this.hasEnter = true;
		this.enter = _enter;
		this.getText = _getText;
	}

    private function _getText():String {
        return value ? "ON" : "OFF";
    }

	private function _enter():Void
	{
		var prev:Bool = this.value;
		this.value = !prev;
		onChange(prev);
	}
}
