package funkin.states;

import openfl.media.Sound;

import flixel.util.FlxSort;

import funkin.objects.*;
import funkin.stages.*;
import funkin.backend.Song.Chart;
import funkin.objects.Note.NoteData;
import funkin.objects.Strumline.Receptor;
import funkin.backend.EventHandler.Event;

import flixel.util.FlxGradient;
import flixel.util.FlxStringUtil;

import funkin.substates.PauseMenu;
import funkin.substates.GameOverSubstate;

class PlayState extends MusicState {
	public static var self:PlayState;

	///////////////////////////////////////////////////////////////////////////////////////////////
	// VSRG SPECIFIC
	// VSRG SPECIFIC
	// VSRG SPECIFIC
	///////////////////////////////////////////////////////////////////////////////////////////////

	// chart shit
	public static var song:Chart;
	public static var songID:String;
	var songName:String;
	var songPercent:Float = 0.0;
	var songLength:Float;

	// gameplay
	@:unreflective static var disqualified:Bool = false;

	@:isVar var botplay(get, set):Bool;
	function get_botplay():Bool {
		if (playfield == null) return false;

		if (playfield.botplay) disqualified = true;
		return playfield.botplay;
	}

	function set_botplay(value:Bool):Bool {
		if (value) disqualified = true;

		playfield.botplay = value;
		botplayTxt.visible = value;

		return value;
	}

	@:isVar var playerID(get, set):Int;
	function get_playerID():Int {
		if (playfield == null) return 0;
		return playfield.playerID;
	}

	function set_playerID(value:Int):Int {
		return playfield.playerID = value;
	}

	@:isVar var rate(get, set):Float;
	function get_rate():Float {
		if (playfield == null) return 1.0;
		return playfield.rate;
	}

	function set_rate(value:Float):Float {
		return playfield.rate = value;
	}

	var _rawScrollSpeed:Float = 1.0;
	@:isVar var scrollSpeed(get, set):Float;
	function get_scrollSpeed():Float {
		if (playfield == null) return 1.0;
		return playfield.scrollSpeed;
	}

	function set_scrollSpeed(value:Float):Float {
		return playfield.scrollSpeed = value;
	}

	// stats 
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
		["WHAT THE FUCK", Math.NaN]
	];

	var combo:Int = 0;
	var comboBreaks:Int = 0;
	var score:Int = 0;
	var accuracy:Float = 0.0;
	var judgeData:Array<Judgement> = Judgement.list;

	var totalNotesPlayed:Float = 0.0;
	var totalNotesHit:Int = 0;

	// objects
	var playfield:PlayField;
	var hud:FlxSpriteGroup;

	var scoreTxt:FlxText;
	var botplayTxt:FlxText;

	var timeBar:Bar;
	var timeTxt:FlxText;

	var judgeSpr:JudgementSpr;
	var comboNumbers:ComboNums;

	var judgeCounter:FlxText;

	var healthBar:Bar;

	var leftStrumline:Strumline;
	var rightStrumline:Strumline;

	///////////////////////////////////////////////////////////////////////////////////////////////
	// FNF SPECIFIC
	// FNF SPECIFIC
	// FNF SPECIFIC
	///////////////////////////////////////////////////////////////////////////////////////////////
	public static var songList:Array<String> = [];
	public static var storyMode:Bool = false;
	public static var currentLevel:Int = 0;
	public static var weekData:WeekFile;

	var characterCache:Map<String, Character> = [];
	
	var stageName:String;

	var health(default, set):Float = 50;
	function set_health(value:Float):Float {
		if (!noFail && ((playerID == 1 && value <= 0) || (playerID == 0 && value >= 100)))
			die();

		value = FlxMath.bound(value, 0, 100);

		// update health bar
		health = value;
		healthBar.percent = FlxMath.remapToRange(FlxMath.bound(health, healthBar.bounds.min, healthBar.bounds.max), healthBar.bounds.min, healthBar.bounds.max, 0, 100);

		iconP1.animation.curAnim.curFrame = healthBar.percent < 20 ? 1 : 0; //If health is under 20%, change player icon to frame 1 (losing icon), otherwise, frame 0 (normal)
		iconP2.animation.curAnim.curFrame = healthBar.percent > 80 ? 1 : 0; //If health is over 80%, change opponent icon to frame 1 (losing icon), otherwise, frame 0 (normal)

		return health = value;
	}

	var defaultCamZoom:Float = 1.05;
	var botplayTxtSine:Float = 0.0;
	var cameraSpeed:Float = 1;

	static var storyScore:Int = 0;

	public var paused:Bool = false;
	var updateTime:Bool = false;

	// objects
	var stage:Stage;

	public var bf:Character;
	public var dad:Character;
	public var gf:Character;

	var camFollow:FlxObject;
	static var prevCamFollow:FlxObject;

	var eventHandler:EventHandler;

	var iconP1:CharIcon;
	var iconP2:CharIcon;

	var countdown:Countdown;

	var noteSplashes:FlxTypedSpriteGroup<NoteSplash>;

	// cameras
	var camGame:FlxCamera;
	var camHUD:FlxCamera;
	var camOther:FlxCamera;

	final iconSpacing:Float = 20;
	var gfSpeed:Int = 1;

	override function create() {
		Language.reloadPhrases();

		super.create();
		self = this;

		Conductor.stop();

		if (storyMode) songID = songList[currentLevel];

		info('new song was loaded: $songID - ${Difficulty.current}');

		// precache the pause menu music
		// to prevent the pause menu freezing on first pause
		PauseMenu.musicPath = Settings.data.pauseMusic;
		Paths.music(PauseMenu.musicPath);

		// set up gameplay settings
		noFail = Settings.data.gameplaySettings['noFail'];
		canReset = Settings.data.canReset;
		downscroll = Settings.data.downscroll;
		scrollType = Settings.data.gameplaySettings['scrollType'];
		_rawScrollSpeed = Settings.data.gameplaySettings['scrollSpeed'];

		clearType = updateClearType();
		grade = updateGrade();

		ScriptHandler.loadFromDir('scripts');

		eventHandler = new EventHandler();
		eventHandler.triggered = eventTriggered;
		eventHandler.pushed = eventPushed;

		ScriptHandler.loadFromDir('songs/$songID');

		// set up cameras
		FlxG.cameras.reset(camGame = new FlxCamera());

		camFollow = new FlxObject();
		if (prevCamFollow != null) {
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		camHUD = FlxG.cameras.add(new FlxCamera(), false);
		camHUD.bgColor.alphaFloat = 1 - (Settings.data.gameVisibility / 100);

		// to prevent more lag when you can't even see the game camera
		if (Settings.data.gameVisibility <= 0) {
			camGame.visible = false;
			camHUD.bgColor.alphaFloat = 0;
		}

		camOther = FlxG.cameras.add(new FlxCamera(), false);
		camOther.bgColor.alpha = 0;

		// start setting up the hud
		final strumlineYPos:Float = downscroll ? FlxG.height - 150 : 50;
		leftStrumline = new Strumline(320, strumlineYPos);
		rightStrumline = new Strumline(950, strumlineYPos);

		add(playfield = new PlayField([leftStrumline, rightStrumline]));
		playfield.cameras = [camHUD];
		playfield.modifiers = true;
		playerID = Settings.data.gameplaySettings['opponentMode'] ? 0 : 1;
		rate = Settings.data.gameplaySettings['playbackRate'];

		if (Settings.data.centeredNotes) {
			for (i => line in playfield.strumlines.members) {
				if (i == playerID) {
					line.screenCenter(X);
					continue;
				}

				line.visible = false;
				line.alpha = 0;
			}
		}

		add(noteSplashes = new FlxTypedSpriteGroup<NoteSplash>());
		for (i in 0...Strumline.keyCount) noteSplashes.add(new NoteSplash(i));
		noteSplashes.cameras = [camHUD];

		// i hate having to make a seperate function for this but
		// it's the only way it'll work for dynamic functions
		playfield.noteHit = function(strumline:Strumline, note:Note) noteHit(strumline, note);
		playfield.noteMiss = function(note:Note) noteMiss(note);
		playfield.sustainHit = function(sustain:Note) sustainHit(sustain);
		playfield.ghostTap = function() ghostTap();
		
		loadSong();

		scrollSpeed = switch scrollType {
			case 'Constant': _rawScrollSpeed;
			case 'Multiplied': song.speed * _rawScrollSpeed;
			default: song.speed;
		}

		stage = switch stageName {
			case 'stage': new StageWeek1();
			case 'mansion': new Mansion();
			case 'philly': new Philly();
			case 'limo': new Limo();
			case 'mall': new Mall();
			case 'mall-evil': new MallEvil();
			case 'school': new School();
			case 'school-evil': new SchoolEvil();
			case 'warzone': new Warzone();
			case 'philly-street': new PhillyStreet();
			//case 'phillyBlazin': new PhillyBlazin();

			case _: new Stage(stageName);
		}
		ScriptHandler.loadFile('stages/$stageName.hx');

		// characters
		add(gf = new Character(stage.spectator.x, stage.spectator.y, song.meta.spectator, false));
		gf.visible = stage.isSpectatorVisible;

		add(dad = new Character(stage.opponent.x, stage.opponent.y, song.meta.enemy, false));
		leftStrumline.character = dad;

		add(bf = new Character(stage.player.x, stage.player.y, song.meta.player));
		rightStrumline.character = bf;

		// fix for the camera starting off in the stratosphere
		camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
		camFollow.x += gf.cameraOffset.x;
		camFollow.y += gf.cameraOffset.y;

		cameraSpeed = stage.cameraSpeed;
		camGame.zoom = defaultCamZoom = stage.zoom;
		camGame.follow(camFollow, LOCKON, 0);
		camGame.snapToTarget();
		
		moveCamera();

		stage.create();
		eventHandler.load(songID);

		// set up hud elements
		add(hud = new FlxSpriteGroup());
		hud.cameras = [camHUD];
		loadHUD();

		botplay = Settings.data.gameplaySettings['botplay'];

		hud.add(countdown = new Countdown());
		countdown.screenCenter();
		countdown.onStart = function() {
			Conductor.playing = true;
			ScriptHandler.call('countdownStarted');
		}
		countdown.onFinish = function() {
			Conductor.play();
			updateTime = true;
			ScriptHandler.call('onSongStart');
		}

		Conductor.rawTime = (Conductor.crotchet * -5);
		countdown.start();

		FlxG.mouse.visible = false;

		DiscordClient.changePresence('$songName - ${Difficulty.current}', storyMode ? 'Story Mode' : 'Freeplay', dad.icon, true);

		ScriptHandler.call('create');
		persistentUpdate = true;
	}

	function loadHUD():Void {
		if (hud == null) return;
		hud.clear();

		hud.add(timeBar = new Bar(0, downscroll ? FlxG.height - 30 : 15, 'timeBar', function() return songPercent, 0, 1));
		timeBar.setColors(0xFFFFFFFF, 0xFF000000);
		timeBar.screenCenter(X);

		// to make it fancy
		// if you want it the generic psych way
		// (black and white)
		// then just take this long ass line out
		FlxGradient.overlayGradientOnFlxSprite(timeBar.leftBar, Std.int(timeBar.leftBar.width), Std.int(timeBar.leftBar.height), [bf.healthColor, dad.healthColor], 0, 0, 1, 180);

		hud.add(timeTxt = new FlxText(0, 0, timeBar.width, '$songName - 0:00', 16));
		timeTxt.font = Paths.font('vcr.ttf');
		timeTxt.alignment = CENTER;
		timeTxt.borderStyle = FlxTextBorderStyle.OUTLINE;
		timeTxt.borderColor = FlxColor.BLACK;
		timeTxt.borderSize = 1.25;
		timeTxt.setPosition(timeBar.getMidpoint().x - (timeTxt.width * 0.5), timeBar.getMidpoint().y - (timeTxt.height * 0.5));

		updateTime = Settings.data.timeBarType != 'Disabled';
		timeBar.visible = Settings.data.timeBarType != 'Disabled';
		timeTxt.visible = Settings.data.timeBarType != 'Disabled';

		hud.add(healthBar = new Bar(0, downscroll ? 55 : 640, 'healthBar', function() return health, 0, 100));
		healthBar.alpha = Settings.data.healthBarAlpha;
		healthBar.setColors(dad.healthColor, bf.healthColor);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;

		hud.add(iconP1 = new CharIcon(bf.icon, true));
		iconP1.alpha = Settings.data.healthBarAlpha;
		iconP1.y = healthBar.y - (iconP1.height * 0.5);

		hud.add(iconP2 = new CharIcon(dad.icon));
		iconP2.alpha = Settings.data.healthBarAlpha;
		iconP2.y = healthBar.y - (iconP2.height * 0.5);

		updateIconPositions();

		hud.add(scoreTxt = new FlxText(0, downscroll ? 21 : FlxG.height - 39, FlxG.width, '', 16));
		scoreTxt.font = Paths.font('vcr.ttf');
		scoreTxt.alignment = CENTER;
		scoreTxt.alpha = Settings.data.scoreAlpha;
		scoreTxt.borderStyle = FlxTextBorderStyle.OUTLINE;
		scoreTxt.borderColor = FlxColor.BLACK;
		scoreTxt.borderSize = 1.25;
		scoreTxt.screenCenter(X);
		updateScoreTxt();

		hud.add(judgeSpr = new JudgementSpr(Settings.data.judgePosition[0], Settings.data.judgePosition[1]));
		hud.add(comboNumbers = new ComboNums(Settings.data.comboPosition[0], Settings.data.comboPosition[1]));

		hud.add(botplayTxt = new FlxText(0, downscroll ? FlxG.height - 115 : 85, FlxG.width - 800, 'BOTPLAY', 32));
		botplayTxt.font = Paths.font('vcr.ttf');
		botplayTxt.alignment = CENTER;
		botplayTxt.borderStyle = FlxTextBorderStyle.OUTLINE;
		botplayTxt.borderColor = FlxColor.BLACK;
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = botplay;
		botplayTxt.screenCenter(X);

		var opponentMode:Bool = Settings.data.gameplaySettings['opponentMode'];
		hud.add(judgeCounter = new FlxText(0, 0, 500, '', 20));
		judgeCounter.font = Paths.font('vcr.ttf');
		judgeCounter.borderStyle = FlxTextBorderStyle.OUTLINE;
		judgeCounter.borderColor = FlxColor.BLACK;
		judgeCounter.borderSize = 1.25;
		judgeCounter.alignment = opponentMode ? 'right' : 'left';
		updateJudgeCounter();
		judgeCounter.screenCenter(Y);
		judgeCounter.visible = Settings.data.judgementCounter;

		judgeCounter.x = opponentMode ? (FlxG.width - judgeCounter.width) - 5 : 5;
	}

	dynamic function ghostTap() {
		score -= 20;
		if (playerID == 0) health += 6;
		else health -= 6;

		accuracy = updateAccuracy();
		grade = updateGrade();
		updateScoreTxt();
	}

	function sustainHit(note:Note) {
		playCharacterAnim(playfield.currentPlayer.character, note, 'sing');
	}

	dynamic function noteHit(strumline:Strumline, note:Note):Void {
		if (note.player != playerID) {
			playCharacterAnim(strumline.character, note, 'sing');
			if (song.meta.hasVocals && Conductor.opponentVocals == null) Conductor.mainVocals.volume = 1;

			return;
		} else if (botplay) {
			playCharacterAnim(strumline.character, note, 'sing');
			if (note.isSustain) return;

			final judge:Judgement = Judgement.min;

			if (playerID == 0) health -= judge.health;
			else health += judge.health;
			if (!Settings.data.hideTightestJudge) judgeSpr.display(0);
			judge.hits++;
			comboNumbers.display(++combo);
			updateJudgeCounter();

			return;
		}

		judgeHit(strumline.members[note.lane], note);
		
		if (note.type == 'Hey!' && strumline.character.animation.exists('cheer')) {
			strumline.character.playAnim('cheer');
		} else playCharacterAnim(strumline.character, note, 'sing');
	}

	inline function playCharacterAnim(character:Character, note:Note, prefix:String) {
		character.playAnim('$prefix${Note.directions[note.lane].toUpperCase()}${note.animSuffix}');
	}

	dynamic function judgeHit(strum:Receptor, note:Note) {
		final adjustedHitTime:Float = note.rawHitTime / Conductor.rate;
		var judgeID:Int = Judgement.getIDFromTiming(adjustedHitTime);
		var judge:Judgement = Judgement.list[judgeID];

		note.judge = judge.name;

		if (Settings.data.gameplaySettings['onlySicks'] && judgeID != 0) die();
	
		if (!note.breakOnHit) {
			totalNotesPlayed += judge.accuracy;
			if (playerID == 0) health -= judge.health;
			else health += judge.health;
			// pbot1-ish scoring system
			// cuz judgement based is boring :sob:
			score += Math.floor(500 - Math.abs(adjustedHitTime));
			judge.hits++;
			combo++;
		} else {
			score -= 20;
			if (playerID == 0) health += 6;
			else health -= 6;
			combo = 0;
			comboBreaks++;
		}
	
		if (judge.breakCombo) {
			combo = 0;
			comboBreaks++;
		}
		
		totalNotesHit++;
		accuracy = updateAccuracy();
		grade = updateGrade();
		clearType = updateClearType();

		updateScoreTxt();
		updateJudgeCounter();
		if (song.meta.hasVocals) {
			if (Conductor.opponentVocals == null) Conductor.mainVocals.volume = 1;
			else Conductor.vocals.members[playerID].volume = 1;
		}

		if (Settings.data.noteSplashSkin != 'None' && judge.splashes && note.splashes) {
			noteSplashes.members[note.lane].hit(strum);
		}

		if (!note.breakOnHit) {
			if (!Settings.data.hideTightestJudge || judgeID > 0) {
				judgeSpr.display(adjustedHitTime);
			}
			comboNumbers.display(combo);
		}

		judge = null;

		ScriptHandler.call('noteHit', [note]);
	}

	dynamic function noteMiss(note:Note) {
		if (note.ignore) return;

		if (Settings.data.gameplaySettings['instakill'] || Settings.data.gameplaySettings['onlySicks']) die();

		comboBreaks++;
		combo = 0;
		score -= 20;
		if (playerID == 0) health += 6;
		else health -= 6;

		accuracy = updateAccuracy();
		grade = updateGrade();
		clearType = updateClearType();

		ScriptHandler.call('noteMiss', [note]);

		note.missed = true;
		for (piece in note.pieces) {
			if (piece == null || !piece.exists || !piece.alive) continue;
			piece.multAlpha = 0.25;
		}

		if (song.meta.hasVocals) {
			if (Conductor.opponentVocals == null) Conductor.mainVocals.volume = 0;
			else Conductor.vocals.members[playerID].volume = 0;
		}

		playCharacterAnim(playfield.currentPlayer.character, note, 'miss');
		updateScoreTxt();
	}

	function loadSong():Void {
		// load chart
		try {
			song = Song.load(songID, Difficulty.format());
		} catch (e:haxe.Exception) {
			error('The chart "$songID (${Difficulty.current})" failed to load: $e');
			song = Song.createDummyFile();
			song.meta = Meta.load(songID);
		}

		Conductor.timingPoints = song.meta.timingPoints;
		Conductor.bpm = Conductor.timingPoints[0].bpm;
		Conductor.offset = song.meta.offset;
		songName = song.meta.songName;
		stageName = song.meta.stage;

		// load inst
		try {
			Conductor.inst = FlxG.sound.load(Paths.audio('songs/$songID/Inst'));
			Conductor.inst.onComplete = function() {
				if (!disqualified) {
					Scores.setPlay({
						songID: songID,
						difficulty: Difficulty.current,

						score: score,
						accuracy: accuracy,

						modifiers: Settings.data.gameplaySettings.copy()
					});

					if (storyMode) {
						storyScore += score;
						if (currentLevel == songList.length - 1) {
							Scores.setWeekPlay({
								weekID: weekData.fileName,
								difficulty: Difficulty.current,
								score: score,
								modifiers: Settings.data.gameplaySettings.copy()
							});
							weekData = null;
							storyScore = 0;
						}
					}
				}

				endSong();
				Scores.save();
			}
		} catch (e:Dynamic) {
			error('Instrumental failed to load: $e');
		}

		songLength = Conductor.inst.length;

		// load vocals
		try {
			if (song.meta.hasVocals) {
				var mainFile:Sound = Paths.audio('songs/$songID/Voices-Player', null, false);
				var opponentFile:Sound = Paths.audio('songs/$songID/Voices-Opponent', null, false);

				if (mainFile == null) mainFile = Paths.audio('songs/$songID/Voices');

				Conductor.mainVocals = FlxG.sound.load(mainFile);
				if (opponentFile != null) Conductor.opponentVocals = FlxG.sound.load(opponentFile);
			}
		} catch (e:Dynamic) {
			warn('Vocals failed to load: $e');
		}

		playfield.loadNotes(song);
	}

	function eventTriggered(event:Event):Void {
		ScriptHandler.call('eventTriggered', [event.name, event.args]);
		stage.eventTriggered(event);

		switch event.name {
			case 'Change Character':
				var type:Int = Std.parseInt(event.args[0]);
				var character:Character = switch type {
					case 0: dad;
					case 1: gf;
					case 2: bf;

					default: null;
				}
				var name:String = event.args[1];
				if (character == null || character.name == name) return;

				var newCharacter:Character = characterCache[name];
				if (newCharacter == null) return;

				newCharacter.alpha = character.alpha;
				newCharacter.visible = character.visible;
				newCharacter.setPosition(character.x, character.y);

				if (type == 0) {
					dad = newCharacter;
					iconP2.change(name);
				} else if (type == 1) {
					gf = newCharacter;
				} else if (type == 2) {
					bf = newCharacter;
					iconP1.change(name);
				}

				healthBar.setColors(dad.healthColor, bf.healthColor);

			case 'Hey!':
				var character:Character = switch Std.parseInt(event.args[0]) {
					case 0: dad;
					case 1: gf;
					case 2: bf;

					default: null;
				}

				if (character == null || !character.animation.exists('cheer')) return;

				character.playAnim('cheer', true);
				character.specialAnim = true;

			case 'Play Animation':
				var animName:String = event.args[1];
				var character:Character = switch Std.parseInt(event.args[0]) {
					case 0: dad;
					case 1: gf;
					case 2: bf;

					default: null;
				}

				if (character == null || !character.animation.exists(animName)) return;

				character.playAnim(animName, true);
				character.specialAnim = true;

			case 'Set GF Speed':
				gfSpeed = Math.floor(Math.max(Std.parseInt(event.args[0]), 1));

			case 'Play Sound':
				FlxG.sound.play(Paths.sound(event.args[0]), Std.parseFloat(event.args[1]));

			case 'Add Camera Zoom':
				if (!Settings.data.cameraZooms || camGame.zoom >= 1.35) return;

				camGame.zoom += Std.parseFloat(event.args[0]);
				camHUD.zoom += Std.parseFloat(event.args[1]);

			case 'Screen Shake':
				var camerasToTarget:Array<FlxCamera> = [camGame, camHUD];
				for (i => cam in camerasToTarget) {
					var duration:Float = Std.parseFloat(event.args[0].split(',')[i]);
					var intensity:Float = Std.parseFloat(event.args[1].split(',')[i]);

					if (duration <= 0 || intensity <= 0) continue;
					cam.shake(intensity, duration);
				}

			case 'Change Scroll Speed':
				if (scrollType == 'constant') return;

				var duration:Float = Std.parseFloat(event.args[1]);
				var value:Float = song.speed * _rawScrollSpeed * Math.max(Std.parseFloat(event.args[0]), 1);

				if (duration <= 0) scrollSpeed = value;
				else FlxTween.tween(this, {scrollSpeed: value}, duration / rate);
		}
	}

	var eventList:Array<String> = [];
	function eventPushed(event:Event):Void {
		eventPushedUnique(event);
		if (eventList.contains(event.name)) return;

		eventList.push(event.name);
		stage.eventPushed(event);
	}

	function eventPushedUnique(event:Event):Void {
		stage.eventPushedUnique(event);

		switch event.name {
			case 'Change Character':
				cacheCharacter(Std.parseInt(event.args[0]), event.args[1]);
		}
	}

	function cacheCharacter(type:Int, name:String):Character {
		var linkedCharacter:Character = switch type {
			case 0: dad;
			case 1: gf;
			case 2: bf;

			default: null;
		}

		if (linkedCharacter == null) return null;

		var character:Character = new Character(0, 0, name);
		character.alpha = 0.0001;
		character.setPosition(linkedCharacter.x, linkedCharacter.y);
		characterCache.set(name, character);

		return character;
	}

	var canPause:Bool = true;
	override function update(elapsed:Float):Void {
		ScriptHandler.call('update', [elapsed]);
		super.update(elapsed);

		if ((Controls.justPressed('reset') && canReset)) die();

		updateCameraScale(elapsed);
		updateIconScales(elapsed);
		updateIconPositions();
		updateTimeBar();

		if (countdown.finished) eventHandler.update();
		stage.update(elapsed);

		if (FlxG.keys.justPressed.F8) botplay = !botplay;

		if (botplayTxt.visible) {
			botplayTxtSine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplayTxtSine) / 180);
		}

		if (Controls.justPressed('pause') && canPause) openPauseMenu();

		camGame.followLerp = paused ? 0 : (0.04 * cameraSpeed * playfield.rate);

		ScriptHandler.call('updatePost', [elapsed]);
	}

	var _lastSeconds:Int = -1;
	dynamic function updateTimeBar() {
		if (paused || !updateTime) return;

		var curTime:Float = Math.max(0, Conductor.rawTime);
		songPercent = (curTime / songLength);

		var songCalc:Float = (songLength - curTime);
		if (Settings.data.timeBarType == 'Time Elapsed') songCalc = curTime;

		var seconds:Int = Math.floor((songCalc / playfield.rate) * 0.001);
		if (seconds < 0) seconds = 0;

		if (seconds == _lastSeconds) return;

		var textToShow:String = '$songName';
		if (playfield.rate != 1) textToShow += ' (${playfield.rate}x)';
		if (Settings.data.timeBarType != 'Song Name') textToShow += ' - ${FlxStringUtil.formatTime(seconds, false)}';

		timeTxt.text = textToShow;
		_lastSeconds = seconds;
	}

	dynamic function updateCameraScale(elapsed:Float):Void {
		if (!Settings.data.cameraZooms) return;

		final scalingMult:Float = Math.exp(-elapsed * 6 * playfield.rate);
		camGame.zoom = FlxMath.lerp(defaultCamZoom, camGame.zoom, scalingMult);
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, scalingMult);
	}

	dynamic function updateIconPositions():Void {
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconSpacing;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconSpacing * 2;
	}

	dynamic function updateIconScales(elapsed:Float):Void {
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 9 * playfield.rate));
		iconP1.scale.set(mult, mult);
		iconP1.centerOrigin();

		mult = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 9 * playfield.rate));
		iconP2.scale.set(mult, mult);
		iconP2.centerOrigin();
	}

	// forceLeave:Bool - forces you to leave to the main menu
	public function endSong(?forceLeave:Bool = false):Void {
		ScriptHandler.call('endSong');

		Conductor.stop();
		Conductor.vocals.destroy();
		canPause = false;
		// should automatically leave if you're not in story mode
		var exitToMenu:Bool = !storyMode;
		if (storyMode) {
			++currentLevel < songList.length ? MusicState.resetState() : exitToMenu = true;
		}

		if (exitToMenu || forceLeave) {
			persistentUpdate = true;
			Conductor.inst = FlxG.sound.load(Paths.music('freakyMenu'), 0.7, true);
			Conductor.play();
			Difficulty.reset();
			Mods.current = '';
			MusicState.switchState(storyMode ? new StoryMenuState() : new FreeplayState());
			songList.resize(0);
			storyMode = false;
			currentLevel = 0;
			disqualified = false;
		} else prevCamFollow = camFollow;

		Sys.println('');
	}

	// you die
	function die() {
		persistentUpdate = false;
		camGame.visible = false;
		camHUD.visible = false;

		countdown.stop();

		var gameOverSubstate:GameOverSubstate = new GameOverSubstate(bf);
		gameOverSubstate.cameras = [camOther];
		openSubState(gameOverSubstate);
	}

	override function beatHit(beat:Int) {
		ScriptHandler.call('beatHit', [beat]);

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
		if (!Settings.data.judgementCounter) return;
		
		var sicks:Int = judgeData[0].hits;
		var goods:Int = judgeData[1].hits;
		var bads:Int = judgeData[2].hits;
		var shits:Int = judgeData[3].hits;

		judgeCounter.text = 'Sicks: $sicks\nGoods: $goods\nBads: $bads\nShits: $shits';
	}

	override function stepHit(step:Int) {
		ScriptHandler.call('stepHit', [step]);
	}

	override function measureHit(measure:Int) {
		ScriptHandler.call('measureHit', [measure]);

		if (Settings.data.cameraZooms) {
			camGame.zoom += 0.03;
			camHUD.zoom += 0.015;
		}

		moveCamera(measure);
	}

	public function moveCamera(?measure:Int = 0) {
		measure = Std.int(Math.max(0, measure));
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
		camFollow.x += bf.cameraOffset.x;
		camFollow.y += bf.cameraOffset.y;
	}

	function openPauseMenu() {
		persistentUpdate = false;
		Conductor.pause();
		paused = true;
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished) tmr.active = false);
		FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished) twn.active = false);

		var menu:PauseMenu = new PauseMenu(songName, Difficulty.current, 0);
		openSubState(menu);
		menu.camera = camOther;
	}

	// in case someone wants to make their own accuracy calc
	dynamic function updateAccuracy():Float {
		if (totalNotesHit <= 0) return 0.0;
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
			else if (goods > 0) {
				if (goods == 1) type = 'BF';
				else if (goods <= 9) type = 'SDG';
				else if (goods >= 10) type = 'GFC';
			} else if (sicks > 0) type = 'PFC';
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
		var textToShow:String = '';
		textToShow += 'Score: $score';

		if (!Settings.data.gameplaySettings['onlySicks']) {
			if (!Settings.data.gameplaySettings['instakill']) 
				textToShow += ' | Combo Breaks: $comboBreaks';

			textToShow += ' | Accuracy: ${Util.truncateFloat(accuracy, 2)}%';
			textToShow += ' [$clearType | $grade]';
		}

		scoreTxt.text = textToShow;
	}

	override function destroy() {
		ScriptHandler.call('destroy');
		closeSubState();
		camGame.setFilters([]);

		stage.destroy();
		Judgement.resetHits();

		Conductor.rate = 1;
		FlxG.animationTimeScale = 1;

		ScriptHandler.clear();

		self = null;
		super.destroy();

		PauseMenu.openCount = 0;
	}
}