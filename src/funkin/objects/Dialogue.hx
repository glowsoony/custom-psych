package funkin.objects;

// leaving this here for later
// in case i wanna finish it

// but god i really don't care for dialogue right now :sob:

typedef DialogueFile = {
	var lines:Array<DialogueLine>;
	var characters:Array<String>;
	var box:String;
	var music:String;
}

typedef DialogueLine = {
	var text:String;
	var character:Int;
	var expression:String;
}

class Dialogue extends FlxTypedSpriteGroup<FunkinSprite> {
	public function new(songID:String) {

	}

	public static function dummyFile():DialogueFile {
		return {
			lines: [
				{
					text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
					character: 0,
					expression: 'default'
				}
			],
			characters: ['dad', 'bf'],
			box: 'default',
			music: 'breakfast'
		};
	}
}