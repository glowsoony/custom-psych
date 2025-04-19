package;

function info(v, ?infos) {
	var className:String = infos.className;
	var methodName:String = infos.methodName;
	var line:Int = infos.lineNumber;

	print('${INVERT.format(37)}[INFO | $className:$line]${INIT.format()} $v', infos);
}

function error(v, ?infos) {
	var className:String = infos.className;
	var methodName:String = infos.methodName;
	var line:Int = infos.lineNumber;

	print('${INVERT.format(31)}[ERROR | $className:$line]${INIT.format()} $v', infos);
}

function warn(v, ?infos) {
	var className:String = infos.className;
	var methodName:String = infos.methodName;
	var line:Int = infos.lineNumber;

	print('${INVERT.format(33)}[WARNING | $className:$line]${INIT.format()} $v', infos);
}

function print(v, ?infos) {
	Sys.println(v);
}

enum abstract Mode(Int) {
	var INIT = 0;
	var BOLD = 1;
	var DIM = 2;
	var ITALIC = 3;
	var UNDERLINE = 4;
	var BLINKING = 5;
	var INVERT = 7;
	var INVISIBLE = 8;
	var STRIKETHROUGH = 9;

	var GREY = 0;
	var RED = 31;
	var YELLOW = 33;
	var BLUE = 34;
	var MAGENTA = 35;
	var WHITE = 37;

	public function format(?c:Int = 37) return '\033[${this};${c}m';

	public function asCol(?c:Int = 0) return '\033[${0};${c}m';
}
