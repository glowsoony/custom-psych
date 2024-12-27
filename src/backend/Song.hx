package backend;

import objects.Note;

typedef Chart = {
	var song:String;
	var notes:Array<Section>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var ?player3:String;
	var gfVersion:String;
	var stage:String;

	var ?gameOverChar:String;
	var ?gameOverSound:String;
	var ?gameOverLoop:String;
	var ?gameOverEnd:String;
	var ?offset:Float;

	var ?arrowSkin:String;
	var ?splashSkin:String;
}

typedef Section = {
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Int;
	var mustHitSection:Bool;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

class Song {
	public static function createDummyFile():Chart {
		return {
			song: 'Unknown',
			notes: [{
				sectionNotes: [],
				sectionBeats: 4,
				mustHitSection: false,
				bpm: 0,
				gfSection: false,
				changeBPM: false,
				altAnim: false
			}],
			events: [],
			bpm: 120,
			needsVoices: false,
			speed: 1.0,
			offset: 0,

			player1: 'bf',
			player2: 'bf',
			gfVersion: 'bf',
			stage: 'stage'
		}
	}

	public static function load(path:String):Chart {
		var file:Chart = createDummyFile();
		var data = Json.parse(Paths.getFileContent(path)).song;
		for (property in Reflect.fields(data)) {
			if (!Reflect.hasField(file, property)) continue;
			Reflect.setField(file, property, Reflect.field(data, property));
		}

		return file;
	}

	public static function parse(chart:Chart):Array<NoteData> {
		final notes:Array<NoteData> = [];
		if (chart == null) return notes;

		for (section in chart.notes) {
			for (note in section.sectionNotes) {
				notes.push({
					time: Math.max(0, note[0]),
					lane: Std.int(note[1] % 4),
					player: note[1] > 3 ? !section.mustHitSection : section.mustHitSection,
					length: note[2],
					type: (note[3] is String ? note[3] : Note.defaultTypes[note[3]]) ?? '',
					speed: chart.speed
				});
			}
		}

		notes.sort((a, b) -> Std.int(a.time - b.time));
		return notes;
	}
}