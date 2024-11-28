package flixel;

class FlxSubState extends flixel.group.FlxGroup {
	public var parent:FlxState;

	public function create():Void {}
	public function close():Void {
		if (parent == null || parent.substate != this) return;

		parent.closeSubstate();
		active = false;
	}

	override public function destroy():Void {
		super.destroy();
		parent = null;
	}

	public function onFocusLost():Void {}
	public function onFocus():Void {}
	public function onResize(width:Int, height:Int):Void {}
}
