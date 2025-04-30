package funkin.options;

class GraphicsSettingsSubState extends BaseOptionsMenu {
	public function new() {
		title = Language.getPhrase('graphics_menu', 'Graphics Settings');
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		addOption(new Option(
			'Anti-aliasing',
			'Enables smoothing on sprites, so lines look less blocky.\nWill cause smaller sprites to appear blurry.',
			'antialiasing',
			BOOL
		));

		addOption(new Option(
			'Reduced Quality',
			'Has certain objects not spawn in/animated to save on performance.',
			'reducedQuality',
			BOOL
		));

		addOption(new Option(
			'Shaders',
			'Used for visual effects, and also CPU/GPU intensive for weaker PCs.',
			'shaders',
			BOOL
		));

		addOption(new Option(
			'GPU Caching',
			'Allows the GPU to be used for caching textures, decreasing RAM usage.\nDon\'t turn this on if you have a shitty graphics card.',
			'gpuCaching',
			BOOL
		));

		addOption(new Option(
			'Fullscreen',
			'Occupies the monitor\'s entire screen with the game.',
			'fullscreen',
			BOOL
		));

		super();
	}
}