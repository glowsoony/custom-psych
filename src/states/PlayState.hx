package states;

import openfl.media.Sound;
import lime.ui.KeyCode;
import lime.app.Application;

import flixel.util.FlxSort;

import objects.*;
import objects.Note.NoteData;
import objects.Strumline.StrumNote;

import backend.Judgement;

import flixel.util.FlxGradient;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxStringUtil;

import substates.PauseMenu;

class PlayState extends MusicState {
	public static var self:PlayState;

	// chart stuff
	public static var song:Chart;
	public static var songID:String;

	public static var songList:Array<String> = [];
	public static var storyMode:Bool = false;
	public static var currentLevel:Int = 0;

	var songName:String;
	var noteSpawnIndex:Int = 0;
	var noteSpawnDelay:Float = 1500;

	var notes:FlxTypedSpriteGroup<Note>;
	var unspawnedNotes:Array<Note> = [];

	// gameplay logic stuff
	var scrollType:String;
	var scrollSpeed(default, set):Float = 1;
	function set_scrollSpeed(value:Float):Float {
		var ratio:Float = value / scrollSpeed;
		if (ratio != 1) {
			for (note in unspawnedNotes) {
				note.resizeByRatio(ratio);
			}
		}

		return scrollSpeed = value;
	}

	public var botplay(default, set):Bool = false;
	function set_botplay(value:Bool):Bool {
		if (playerStrums != null) playerStrums.player = !value;
		if (botplayTxt != null) botplayTxt.visible = value;
		return botplay = value;
	}

	var downscroll:Bool; 

	var clearType:String;
	var grade:String;

	static var gradeSet:Array<Array<Dynamic>> = [
		["Perfect!!", 1],
		["Sick!", 0.9],
		["Great", 0.8],
		["Good", 0.7],
		["Nice", 0.69],
		["Meh", 0.6],
		["Bruh", 0.5],
		["Bad", 0.4],
		["Shit", 0.2],
		["You Suck!", 0],
	];

	var health(default, set):Float = 50;
	function set_health(value:Float):Float {
		return health = FlxMath.bound(value, 0, 100);
	}

	var playbackRate(default, set):Float = 1;
	function set_playbackRate(value:Float):Float {
		#if FLX_PITCH
		Conductor.rate = value;

		var ratio:Float = playbackRate / value; //funny word huh
		if (ratio != 1) {
			for (note in unspawnedNotes) note.resizeByRatio(ratio);
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		#else
		playbackRate = 1.0; // ensuring -Crow
		#end
		return playbackRate;
	}

	var judgeData:Array<Judgement> = Judgement.list;

	var defaultCamZoom:Float = 1.05;

	var songPercent:Float = 0.0;
	var songLength:Float;

	var botplayTxtSine:Float = 0.0;

	var combo:Int = 0;
	var comboBreaks:Int = 0;
	var score:Int = 0;
	var accuracy:Float = 0.0;

	var totalNotesPlayed:Float = 0.0;
	var totalNotesHit:Int = 0;

	public var paused:Bool = false;
	var updateTime:Bool = false;

	// objects
	var bf:Character;
	var dad:Character;
	var gf:Character;

	var camFollow:FlxObject;
	static var prevCamFollow:FlxObject;

	var opponentStrums:Strumline;
	var playerStrums:Strumline;

	var hudGroup:FlxSpriteGroup;

	var scoreTxt:FlxText;
	var botplayTxt:FlxText;

	var timeBar:Bar;
	var timeTxt:FlxText;

	var judgeSpr:JudgementSpr;
	var comboNumbers:ComboNums;

	var judgeCounter:FlxText;

	var healthBar:Bar;
	var iconP1:CharIcon;
	var iconP2:CharIcon;

	var countdown:Countdown;

	// cameras
	var camGame:FlxCamera;
	var camHUD:FlxCamera;
	var camOther:FlxCamera;

	// whatever variables i also need lmao
	final iconSpacing:Float = 20;
	var gfSpeed:Int = 1;

	var keys:Array<String> = [
		'note_left',
		'note_down',
		'note_up',
		'note_right'
	];

	override function create() {
		Language.reloadPhrases();

		super.create();
		self = this;

		Conductor.stop();

		if (storyMode) songID = songList[currentLevel];

		// precache the pause menu music
		// to prevent the pause menu freezing on first pause
		PauseMenu.musicPath = Settings.data.pauseMusic;
		Paths.music(PauseMenu.musicPath);

		// set up gameplay settings
		botplay = Settings.data.gameplaySettings['botplay'];
		playbackRate = Settings.data.gameplaySettings['playbackRate'];
		downscroll = Settings.data.scrollDirection == 'Down';

		clearType = updateClearType();
		grade = updateGrade();

		loadSong();

		scrollSpeed = switch (Settings.data.gameplaySettings['scrollType']) {
			case 'Constant': Settings.data.gameplaySettings['scrollSpeed'];
			case 'Multiplicative': song.speed * Settings.data.gameplaySettings['scrollSpeed'];
			default: song.speed;
		}

		// set up cameras
		FlxG.cameras.reset(camGame = new FlxCamera());

		camFollow = new FlxObject();
		if (prevCamFollow != null) {
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		camFollow.setPosition(0, 0);
		add(camFollow);
		
		camGame.follow(camFollow, LOCKON, 0);
		camGame.zoom = 1;
		camGame.snapToTarget();

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		moveCamera();

		camHUD = FlxG.cameras.add(new FlxCamera(), false);
		camHUD.bgColor.alphaFloat = 1 - (Settings.data.stageBrightness * 0.01);

		// to prevent more lag when you can't even see the game camera
		if (Settings.data.stageBrightness <= 0) camGame.visible = false;

		camOther = FlxG.cameras.add(new FlxCamera(), false);
		camOther.bgColor.alpha = 0;

		// set up strumlines and the note group
		final strumlineYPos:Float = downscroll ? FlxG.height - 150 : 50;
		add(playerStrums = new Strumline(750, strumlineYPos, !botplay));
		add(opponentStrums = new Strumline(100, strumlineYPos));

		playerStrums.cameras = [camHUD];
		opponentStrums.cameras = [camHUD];

		if (Settings.data.centeredNotes) {
			playerStrums.screenCenter(X);
			opponentStrums.alpha = 0;
		}

		if (!Settings.data.opponentNotes) opponentStrums.alpha = 0;

		add(notes = new FlxTypedSpriteGroup<Note>());
		notes.cameras = [camHUD];

		// characters
		add(gf = new Character(350, 225, 'gf', false));
		add(dad = new Character(100, 225, '', false));
		add(bf = new Character(750, 225));

		// set up hud elements
		add(hudGroup = new FlxSpriteGroup());
		hudGroup.cameras = [camHUD];

		hudGroup.add(timeBar = new Bar(0, downscroll ? FlxG.height - 30 : 15, 'timeBar', function() return songPercent, 0, 1));
		timeBar.setColors(0xFFFFFFFF, 0xFF000000);
		timeBar.screenCenter(X);

		hudGroup.add(timeTxt = new FlxText(0, 0, timeBar.width, '$songName - 0:00', 16));
		timeTxt.font = Paths.font('vcr.ttf');
		timeTxt.alignment = CENTER;
		timeTxt.borderStyle = FlxTextBorderStyle.OUTLINE;
		timeTxt.borderColor = FlxColor.BLACK;
		timeTxt.borderSize = 1.25;
		timeTxt.setPosition(timeBar.getMidpoint().x - (timeTxt.width * 0.5), timeBar.getMidpoint().y - (timeTxt.height * 0.5));

		// to make it fancy
		// if you want it the generic psych way
		// (black and white)
		// then just take this long ass line out
		FlxGradient.overlayGradientOnFlxSprite(timeBar.leftBar, Std.int(timeBar.leftBar.width), Std.int(timeBar.leftBar.height), [bf.healthColor, dad.healthColor], 0, 0, 1, 180);

		hudGroup.add(healthBar = new Bar(0, downscroll ? 55 : 640, 'healthBar', function() return health, 0, 100));
		healthBar.setColors(dad.healthColor, bf.healthColor);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;

		hudGroup.add(iconP1 = new CharIcon(bf.icon, true));
		iconP1.y = healthBar.y - (iconP1.height * 0.5);

		hudGroup.add(iconP2 = new CharIcon(dad.icon));
		iconP2.y = healthBar.y - (iconP2.height * 0.5);

		updateIconPositions();

		hudGroup.add(scoreTxt = new FlxText(0, downscroll ? 21 : FlxG.height - 39, FlxG.width, '', 16));
		scoreTxt.font = Paths.font('vcr.ttf');
		scoreTxt.alignment = CENTER;
		scoreTxt.borderStyle = FlxTextBorderStyle.OUTLINE;
		scoreTxt.borderColor = FlxColor.BLACK;
		scoreTxt.borderSize = 1.25;
		scoreTxt.screenCenter(X);
		updateScoreTxt();

		hudGroup.add(judgeSpr = new JudgementSpr(Settings.data.judgePosition[0], Settings.data.judgePosition[1]));
		hudGroup.add(comboNumbers = new ComboNums(Settings.data.comboPosition[0], Settings.data.comboPosition[1]));

		hudGroup.add(botplayTxt = new FlxText(0, downscroll ? FlxG.height - 115 : 85, FlxG.width - 800, 'BOTPLAY', 32));
		botplayTxt.font = Paths.font('vcr.ttf');
		botplayTxt.alignment = CENTER;
		botplayTxt.borderStyle = FlxTextBorderStyle.OUTLINE;
		botplayTxt.borderColor = FlxColor.BLACK;
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = botplay;
		botplayTxt.screenCenter(X);

		hudGroup.add(judgeCounter = new FlxText(5, 0, 500, '', 20));
		judgeCounter.font = Paths.font('vcr.ttf');
		judgeCounter.borderStyle = FlxTextBorderStyle.OUTLINE;
		judgeCounter.borderColor = FlxColor.BLACK;
		judgeCounter.borderSize = 1.25;
		updateJudgeCounter();
		judgeCounter.screenCenter(Y);

		hudGroup.add(countdown = new Countdown());
		countdown.screenCenter();
		countdown.onStart = function() Conductor.self.active = true;
		countdown.onFinish = function() {
			Conductor.play();
			updateTime = true;
		}

		// set up any other stuff we might need
		Application.current.window.onKeyDown.add(keyPressed);
		Application.current.window.onKeyUp.add(keyReleased);

		Conductor.time -= Conductor.crotchet * 5;
		countdown.start();

		FlxG.mouse.visible = false;
	}

	function loadSong():Void {
		try {
			song = Song.load('songs/$songID/${Difficulty.format()}.json');
		} catch (e:haxe.Exception) {
			trace('"$songID (${Difficulty.current})" failed to load: $e');
			return;
		}

		Conductor.setBPMChanges(song);
		Conductor.bpm = song.bpm;
		songName = song.song;

		// load inst
		try {
			Conductor.inst = FlxG.sound.load(Paths.audio('songs/$songID/Inst'));
			Conductor.inst.onComplete = endSong;
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
		} catch (e:Dynamic) Sys.println('Vocals failed to load: $e');

		songLength = Conductor.inst.length;

		loadNotes(songID);
	}

	function loadNotes(id:String) {
		var parsedNotes:Array<NoteData> = Song.parse(song);

		for (note in unspawnedNotes) {
			note.destroy();
			note = null;
		}
		unspawnedNotes.resize(0);

		var oldNote:Note = null;

		var randomizedLanes:Array<Int> = [];
		for (i in 0...Strumline.keyCount) randomizedLanes.push(FlxG.random.int(0, Strumline.keyCount - 1, randomizedLanes));
		for (i => note in parsedNotes) {
			// dumbest way of doing it but whatever lmao
			if (Settings.data.gameplaySettings['mirroredNotes']) {
				if (note.lane == 0) note.lane = 3;
				else if (note.lane == 3) note.lane = 0;
				else if (note.lane == 1) note.lane = 2;
				else note.lane = 1;
			}

			// stepmania shuffle
			// instead of randomizing every note's lane individually
			// because chords were buggy asf lmao
			if (Settings.data.gameplaySettings['randomizedNotes']) note.lane = randomizedLanes[note.lane];

			if (!Settings.data.gameplaySettings['sustains']) note.length = 0;

			var daBPM:Float = Conductor.getBPMChangeFromMS(note.time).bpm;

			if (i != 0) {
				// CLEAR ANY POSSIBLE GHOST NOTES
				for (evilNote in unspawnedNotes) {
					var matches:Bool = (note.lane == evilNote.lane && note.player == evilNote.player);
					if (matches && Math.abs(note.time - evilNote.time) < 2.0) {
						evilNote.destroy();
						unspawnedNotes.remove(evilNote);
					}
				}
			}

			var swagNote:Note = new Note(note);
			unspawnedNotes.push(swagNote);

			var curStepCrochet:Float = (60 / daBPM) * 1000 * 0.25;
			final roundSus:Int = Math.round(swagNote.sustainLength / curStepCrochet);
			if (roundSus > 0) {
				for (susNote in 0...roundSus) {
					oldNote = unspawnedNotes[unspawnedNotes.length - 1];

					var sustainNote:Note = new Note({
						time: note.time + (curStepCrochet * susNote),
						lane: note.lane,
						length: note.length,
						type: note.type,
						player: note.player,
						speed: note.speed
					},  true, oldNote);
					sustainNote.parent = swagNote;
					sustainNote.correctionOffset.y = downscroll ? 0 : swagNote.height * 0.5;
					unspawnedNotes.push(sustainNote);
					swagNote.pieces.push(sustainNote);

					if (oldNote.isSustain) {
						oldNote.scale.y *= 44 / oldNote.frameHeight;
						oldNote.scale.y /= playbackRate;
						oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrotchet);
					}
				}
			}

			oldNote = swagNote;
		}

		// forces sustains to be behind notes
		// if you want them to be in front just use this code instead lol

		//unspawnedNotes.sort((a, b) -> Std.int(a.time - b.time));
		unspawnedNotes.sort((a, b) -> {
			if (a.time == b.time) return a.isSustain ? -1 : Std.int(a.time - b.time);
			return Std.int(a.time - b.time);
		});
		oldNote = null;
	}

	var canPause:Bool = true;
	override function update(elapsed:Float):Void {
		super.update(elapsed);

		spawnNotes();
		updateNotes();
		updateCameraScale(elapsed);
		updateIconScales(elapsed);
		updateIconPositions();
		updateTimeBar();

		if (FlxG.keys.justPressed.F8) botplay = !botplay;

		if (botplayTxt.visible) {
			botplayTxtSine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplayTxtSine) / 180);
		}

		if (Controls.justPressed('pause') && canPause) openPauseMenu();

		if (paused) camGame.followLerp = 0;
		else camGame.followLerp = 0.04 * 1 * playbackRate;
	}

	var _lastSeconds:Int = -1;
	dynamic function updateTimeBar() {
		if (paused || !updateTime) return;

		var curTime:Float = Math.max(0, Conductor.time / Conductor.rate);
		songPercent = (curTime / (songLength / Conductor.rate));

		var seconds:Int = Math.floor(curTime * 0.001);
		if (seconds < 0) seconds = 0;

		if (seconds < _lastSeconds) return;

		timeTxt.text = '$songName - ${FlxStringUtil.formatTime(seconds, false)}';
		_lastSeconds = seconds;
	}

	dynamic function spawnNotes() {
		while (noteSpawnIndex < unspawnedNotes.length) {
			final noteToSpawn:Note = unspawnedNotes[noteSpawnIndex];
			if (noteToSpawn.hitTime > noteSpawnDelay) break;

			notes.add(noteToSpawn);
			noteToSpawn.spawned = true;
			noteSpawnIndex++;
		}
	}

	dynamic function updateNotes() {
		for (note in notes.members) {
			if (note == null || !note.alive) continue;

			final strum:StrumNote = (note.player ? playerStrums : opponentStrums).members[note.lane];
			note.followStrum(strum, scrollSpeed);

			if (note.player) {
				if (botplay) checkNoteHitWithAI(strum, note);
				else if (note.isSustain) sustainInputs(strum, note);
			} else checkNoteHitWithAI(strum, note);

			if (note.player && !note.missed && !note.isSustain && note.tooLate) {
				noteMiss(note);
			}

			if (note.time < Conductor.time - 300) {
				notes.remove(note);
				note.destroy();
			}
		}
	}

	dynamic function updateCameraScale(elapsed:Float):Void {
		camGame.zoom = FlxMath.lerp(1, camGame.zoom, Math.exp(-elapsed * 6 * playbackRate));
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 6 * playbackRate));
	}

	dynamic function updateIconPositions():Void {
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconSpacing;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconSpacing * 2;
	}

	dynamic function updateIconScales(elapsed:Float):Void {
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP1.scale.set(mult, mult);
		iconP1.centerOrigin();

		mult = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP2.scale.set(mult, mult);
		iconP2.centerOrigin();
	}

	public function endSong():Void {
		Conductor.stop();
		Conductor.vocals.destroy();
		canPause = false;
		// should automatically leave if you're not in story mode
		var exitToMenu:Bool = !storyMode;
		if (storyMode) {
			++currentLevel < songList.length ? MusicState.resetState() : exitToMenu = true;
		}

		if (exitToMenu) {
			persistentUpdate = true;
			Conductor.inst = FlxG.sound.load(Paths.music('freakyMenu'), 0.7, true);
			Conductor.play();
			MusicState.switchState(storyMode ? new StoryMenuState() : new FreeplayState());
			songList = [];
			storyMode = false;
			currentLevel = 0;
		} else prevCamFollow = camFollow;
	}

	// ai note hitting
	dynamic function checkNoteHitWithAI(strum:StrumNote, note:Note):Void {
		if (!note.canHit || note.time >= Conductor.time) return;

		final noteFunc = note.player ? noteHit : opponentNoteHit;

		// sustain input
		if (note.isSustain) {
			note.clipToStrum(strum);
			if (note.wasHit) return;

			note.wasHit = true;
			strum.playAnim('notePressed');
			noteFunc(note);
			return;
		}

		// normal notes
		strum.playAnim('notePressed');
		note.wasHit = true;
		noteFunc(note);
		note.destroy();
		notes.remove(note);
	}

	dynamic function opponentNoteHit(note:Note) {
		if (song.needsVoices && Conductor.opponentVocals == null) Conductor.mainVocals.volume = 1;

		dad.playAnim('sing${Note.directions[note.lane].toUpperCase()}');
	}

	// note hitting specific to the player
	dynamic function sustainInputs(strum:StrumNote, note:Note) {
		var parent:Note = note.parent;

		if (!parent.canHit || parent.missed) return;

		var heldKey:Bool = keysHeld[parent.lane];
		var tooLate:Bool = (parent.wasHit ? note.time < Conductor.time : parent.tooLate);
		var isTail:Bool = note.animation.curAnim.name == 'holdend';

		if (!heldKey) {
			if (tooLate && !note.wasHit) {
				// ignore tails completely
				if (isTail && parent.wasHit) {
					note.destroy();
					notes.remove(note);
					return;
				}

				noteMiss(parent);
				parent.missed = true;
			}

			return;
		}

		note.clipToStrum(strum);

		if (note.time <= Conductor.time && !note.wasHit) note.wasHit = true;
		else return;
		
		strum.playAnim('notePressed');
		bf.playAnim('sing${Note.directions[parent.lane].toUpperCase()}');
	}

	dynamic function noteHit(note:Note) {
		if (song.needsVoices) Conductor.mainVocals.volume = 1;

		if (botplay) {
			bf.playAnim('sing${Note.directions[note.lane].toUpperCase()}');
			if (note.isSustain) return;

			final judge:Judgement = Judgement.list[0];

			health += judge.health;
			judgeSpr.display(judge.name);
			judge.hits++;
			combo++;
			comboNumbers.display(combo);
			updateJudgeCounter();
			
			return;
		}

		playerStrums.members[note.lane].playAnim('notePressed');
		note.wasHit = true;

		totalNotesHit++;
		
		// pbot1 scoring system
		// cuz judgement based is super boring :sob:
		if (!note.breakOnHit) score += Math.floor(500 - Math.abs(note.hitTime));
		for (id => judge in Judgement.list) {
			if (Math.abs(note.hitTime) >= judge.timing) continue;

			if (judge.breakCombo || note.breakOnHit) {
				comboNumbers.display(combo = 0);
				comboBreaks++;
			}

			if (note.breakOnHit) {
				score -= 20;
				health -= 6;
			} else {
				totalNotesPlayed += judge.accuracy;
				health += judge.health;
				judgeSpr.display(judge.name);
				judge.hits++;
			}

			break;
		}

		combo++;
		comboNumbers.display(combo);
		updateJudgeCounter();

		bf.playAnim('sing${Note.directions[note.lane].toUpperCase()}');

		accuracy = updateAccuracy();
		grade = updateGrade();
		clearType = updateClearType();
		updateScoreTxt();
	}

	dynamic function noteMiss(note:Note) {
		if (note.ignore) return;
		
		comboBreaks++;
		combo = 0;
		score -= 20;
		health -= 6;

		note.missed = true;
		for (piece in note.pieces) {
			if (piece == null || !piece.exists || !piece.alive) continue;
			piece.multAlpha = 0.25;
		}

		if (song.needsVoices) Conductor.mainVocals.volume = 0;
		bf.playAnim('miss${Note.directions[note.lane].toUpperCase()}');

		updateAccuracy();
		updateScoreTxt();
	}

	override function beatHit(beat:Int) {
		iconP1.scale.set(1.2, 1.2);
		iconP1.updateHitbox();

		iconP2.scale.set(1.2, 1.2);
		iconP2.updateHitbox();

		characterBopper(beat);
	}

	function characterBopper(beat:Int):Void {
		if (beat % Math.round(gfSpeed * gf.danceInterval) == 0)
			gf.dance();
		if (beat % bf.danceInterval == 0)
			bf.dance();
		if (beat % dad.danceInterval == 0)
			dad.dance();
	}

	dynamic function updateJudgeCounter() {
		var sicks:Int = judgeData[0].hits;
		var goods:Int = judgeData[1].hits;
		var bads:Int = judgeData[2].hits;
		var shits:Int = judgeData[3].hits;

		judgeCounter.text = 'Sicks: $sicks\nGoods: $goods\nBads: $bads\nShits: $shits';
	}

	override function measureHit(measure:Int) {
		camGame.zoom += 0.03;
		camHUD.zoom += 0.015;

		moveCamera(measure);
	}

	public function moveCamera(?measure:Int = 0) {
		if (measure < 0) measure = 0;
		if (song.notes[measure] == null) return;

		if (gf != null && song.notes[measure].gfSection) {
			camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraOffset.x;
			camFollow.y += gf.cameraOffset.y;
			return;
		}

		var isOpponent:Bool = song.notes[measure].mustHitSection != true;
		if (isOpponent) {
			if (dad == null) return;
			camFollow.setPosition(dad.getMidpoint().x, dad.getMidpoint().y);
			camFollow.x += dad.cameraOffset.x;
			camFollow.y += dad.cameraOffset.y;
			return;
		}
		
		if (bf == null) return;
		camFollow.setPosition(bf.getMidpoint().x, bf.getMidpoint().y);
		camFollow.x -= bf.cameraOffset.x;
		camFollow.y += bf.cameraOffset.y;
	}

	function openPauseMenu() {
		persistentUpdate = false;
		Conductor.pause();
		paused = true;
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished) tmr.active = false);
		FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished) twn.active = false);

		var menu:PauseMenu = new PauseMenu(songName, Difficulty.current, 0);
		openSubstate(menu);
		menu.camera = camOther;
	}

	// in case someone wants to make their own accuracy calc
	dynamic function updateAccuracy():Float {
		return totalNotesPlayed / (totalNotesHit + comboBreaks);
	}

	dynamic function updateClearType():String {
		var sicks:Int = judgeData[0].hits;
		var goods:Int = judgeData[1].hits;
		var bads:Int = judgeData[2].hits;
		var shits:Int = judgeData[3].hits;

		var type:String = 'N/A';

		if (comboBreaks == 0) {
			if (bads > 0 || shits > 0) type = 'FC';
			else if (goods == 1) type = 'BF';
			else if (goods >= 2) type = 'SDG';
			else if (goods >= 10) type = 'GFC';
			else if (sicks > 0) type = 'PFC';
		} else {
			if (comboBreaks == 1) type = 'MF';
			else if (comboBreaks <= 9) type = 'SDCB';
			else type = 'Clear';
		}

		return type;
	}

	// from troll engine
	// lol luhmao
	dynamic function updateGrade():String {
		var type:String = '?';
		if (totalNotesHit == 0) return type;
		
		final roundedAccuracy:Float = accuracy * 0.01;

		if (roundedAccuracy >= 1) return gradeSet[0][0]; // Uses first string
		else {
			for (curGrade in gradeSet) {
				if (roundedAccuracy <= curGrade[1]) continue;
				type = curGrade[0];
				break;
			}
		}
		
		return type;
	}

	dynamic function updateScoreTxt():Void {
		scoreTxt.text = 'Score: $score | Combo Breaks: $comboBreaks | Accuracy: ${Util.truncateFloat(accuracy, 2)}% [$clearType | $grade]';
	}

	var keysHeld:Array<Bool> = [for (_ in 0...Strumline.keyCount) false];
	inline function keyPressed(key:KeyCode, _):Void {
		final dir:Int = Controls.convertStrumKey(keys, Controls.convertLimeKeyCode(key));
		if (dir == -1 || keysHeld[dir] || botplay || paused) return;

		var strum:StrumNote = playerStrums.members[dir];
		final sortedNotes:Array<Note> = notes.members.filter(function(note:Note):Bool {
			// make the long ass return more readable
			if (note == null) return false;
			return note.hittable && note.lane == dir && note.player && !note.isSustain;
		});

		if (sortedNotes.length == 0) {
			strum.playAnim('pressed');
		} else {
			sortedNotes.sort((a, b) -> Std.int(a.time - b.time));
			var note:Note = sortedNotes[0];
			noteHit(note);
			note.destroy();
			notes.remove(note);
			note = null;
		}

		keysHeld[dir] = true;
	}

	inline function keyReleased(key:KeyCode, _):Void {
		final dir:Int = Controls.convertStrumKey(keys, Controls.convertLimeKeyCode(key));
		if (dir == -1 || botplay) return;
		keysHeld[dir] = false;

		playerStrums.members[dir].playAnim('default');
	}

	override function destroy() {
		resetSubstate();
		camGame.setFilters([]);

		Application.current.window.onKeyDown.remove(keyPressed);
		Application.current.window.onKeyUp.remove(keyReleased);

		Judgement.resetHits();

		Conductor.rate = 1;
		FlxG.animationTimeScale = 1;

		self = null;
		Difficulty.reset();
		super.destroy();
	}
}