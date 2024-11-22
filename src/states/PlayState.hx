package states;

import openfl.media.Sound;
import lime.ui.KeyCode;
import lime.app.Application;

import objects.*;
import objects.Note;
import objects.Strumline.StrumNote;

class PlayState extends MusicState {
	public static var song:Chart;

	var scrollSpeed(default, set):Float = 1;
	var scrollType:String;

	function set_scrollSpeed(value:Float):Float {
		var ratio:Float = value / scrollSpeed; //funny word huh
		if (ratio != 1) {
			for (note in unspawnedNotes) {
				note.resizeByRatio(ratio);
			}
		}

		return scrollSpeed = value;
	}

	public var opponentStrums:Strumline;
	public var playerStrums:Strumline;

	public var botplay:Bool = false;

	var songName:String;
	public static var songID:String;
	public var paused:Bool = false;
	public static var self:PlayState;

	var noteSpawnIndex:Int = 0;
	var noteSpawnDelay:Float = 1500;
	
	var notes:FlxTypedSpriteGroup<Note>;
	var unspawnedNotes:Array<Note> = [];

	var keys:Array<String> = [
		'note_left',
		'note_down',
		'note_up',
		'note_right'
	];

	override function create() {
		Paths.clearStoredMemory();
		Language.reloadPhrases();

		super.create();
		self = this;

		FlxG.cameras.reset();

		final downscroll:Bool = Settings.data.scrollDirection == 'Down';
		final strumlineYPos:Float = downscroll ? FlxG.height - 150 : 50;

		add(playerStrums = new Strumline(750, strumlineYPos));
		add(opponentStrums = new Strumline(100, strumlineYPos));

		playerStrums.members[1].playAnim('notePressed');

		if (Settings.data.centeredNotes) {
			playerStrums.screenCenter(X);
			opponentStrums.alpha = 0;
		}

		if (!Settings.data.opponentNotes) opponentStrums.alpha = 0;

		add(notes = new FlxTypedSpriteGroup<Note>());

		Application.current.window.onKeyDown.add(keyPressed);
		Application.current.window.onKeyUp.add(keyReleased);

		loadSong(songID);
		Conductor.play();

		scrollType = Settings.data.gameplaySettings['scrollType'];
		scrollSpeed = switch (scrollType) {
			case 'Constant': Settings.data.gameplaySettings['scrollSpeed'];
			case 'Multiplicative': song.speed * Settings.data.gameplaySettings['scrollSpeed'];
			default: song.speed;
		}
	}

	function loadSong(id:String):Void {
		if (Conductor.inst != null) Conductor.inst.stop();

		Conductor.setBPMChanges(song);
		Conductor.bpm = song.bpm;
		songName = song.song;

		// load inst
		try {
			Conductor.inst = FlxG.sound.load(Paths.audio('songs/$songID/Inst'));
		} catch (e:Dynamic) {
			Sys.println('Instrumental failed to load: $e');
		}

		// load vocals
		try {
			if (song.needsVoices) {
				var mainFile:Sound = Paths.audio('songs/$songID/Voices-Player', null, false);
				var opponentFile:Sound = Paths.audio('songs/$songID/Voices-Opponent', null, false);

				if (mainFile == null) mainFile = Paths.audio('songs/$songID/Voices');

				Conductor.mainVocals = FlxG.sound.load(mainFile);
				if (opponentFile != null) Conductor.opponentVocals = FlxG.sound.load(opponentFile);
			}
		} catch (e:Dynamic) {
			Sys.println('Vocals failed to load: $e');
		}

		loadNotes(songID);
	}

	override function update(elapsed):Void {
		// note spawning
		while (noteSpawnIndex < unspawnedNotes.length) {
			final noteToSpawn:Note = unspawnedNotes[noteSpawnIndex];
			if (noteToSpawn.hitTime > noteSpawnDelay) break;

			notes.add(noteToSpawn);
			noteToSpawn.spawned = true;
			noteSpawnIndex++;
		}

		for (note in notes.members) {
			if (note == null || !note.alive) continue;

			final strumline:Strumline = note.player ? playerStrums : opponentStrums;
			note.followStrum(strumline.members[note.lane], scrollSpeed);

			if (botplay) checkNoteHitWithAI(playerStrums, note);
			checkNoteHitWithAI(opponentStrums, note);

			if (note.time < Conductor.time - 300) {
				notes.remove(note);
				note.destroy();
			}
		}
	}

	function checkNoteHitWithAI(strumline:Strumline, note:Note) {
		if (!note.alive || note.time > Conductor.time) return;

		strumline.members[note.lane].playAnim('notePressed');
		//(strumline.player ? onNoteHit : onOpponentNoteHit)(note);
		note.destroy();
		notes.remove(note);
	}

	function noteHit(note:Note) {
		playerStrums.members[note.lane].playAnim('notePressed');
	}

	function loadNotes(id:String) {
		var parsedNotes:Array<NoteData> = Song.parse(song);

		notes.clear();

		var oldNote:Note = null;
		for (note in parsedNotes) {
			var daBPM:Float = Conductor.getBPMChangeFromMS(note.time).bpm;

			var swagNote:Note = new Note(note, oldNote);
			unspawnedNotes.push(swagNote);

			var curStepCrochet:Float = (60 / daBPM) * 1000 * 0.25;
			final roundSus:Int = Math.round(swagNote.sustainLength / curStepCrochet);
			if (roundSus > 1) {
				for (susNote in 0...roundSus) {
					oldNote = unspawnedNotes[unspawnedNotes.length - 1];

					var sustainNote:Note = new Note({
						time: note.time + (curStepCrochet * susNote),
						lane: note.lane,
						length: note.length,
						type: note.type,
						player: note.player,
						speed: note.speed
					}, oldNote, true);
					sustainNote.parent = swagNote;
					sustainNote.correctionOffset.y = Settings.data.scrollDirection == 'Down' ? 0 : swagNote.height * 0.5;
					unspawnedNotes.push(sustainNote);
					swagNote.tail.push(sustainNote);

					if (oldNote.isSustain) {
						oldNote.scale.y *= 44 / oldNote.frameHeight;
						//oldNote.scale.y /= playbackRate;
						oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrotchet);
					}
				}
			}

			oldNote = swagNote;
		}

		unspawnedNotes.sort((a, b) -> Std.int(a.time - b.time));
		oldNote = null;
	}

	var keysHeld:Array<Bool> = [for (_ in 0...Strumline.keyCount) false];
	inline function keyPressed(key:KeyCode, _):Void {
		final dir:Int = Controls.convertStrumKey(keys, Controls.convertLimeKeyCode(key));
		if (dir == -1 || keysHeld[dir] || paused) return;

		var strumNote:StrumNote = playerStrums.members[dir];
		strumNote.playAnim('pressed');
		keysHeld[dir] = true;
	}

	inline function keyReleased(key:KeyCode, _):Void {
		final dir:Int = Controls.convertStrumKey(keys, Controls.convertLimeKeyCode(key));
		if (dir == -1) return;
		keysHeld[dir] = false;

		playerStrums.members[dir].playAnim('default');
	}

	override function destroy() {
		closeSubState();
		resetSubState();
		FlxG.camera.setFilters([]);

		Conductor.rate = 1;
		FlxG.animationTimeScale = 1;

		self = null;
		super.destroy();
	}
}
