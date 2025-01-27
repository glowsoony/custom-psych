package states.editors;

class CharacterEditorState extends MusicState {
    override function create():Void {
        super.create();
        Conductor.stop();

        FlxG.sound.playMusic(Paths.music('artisticExpression'), true, 1);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);
        if (Controls.justPressed('back')) {
            MusicState.switchState(new MainMenuState());
        }
    }

    override function destroy():Void {
        FlxG.sound.music.stop();
        super.destroy();
    }
}
