package funkin.backend;

class Language
{
	public static var defaultLangName:String = 'English (US)'; //en-US
	#if TRANSLATIONS_ALLOWED
	private static var phrases:Map<String, String> = [];
	#end

	static var isDirectory(get, never):Bool;
	static function get_isDirectory():Bool {
		return FileSystem.isDirectory(Paths.get('locale/${Settings.data.language}'));
	}

	public static function reloadPhrases() {
		#if TRANSLATIONS_ALLOWED
		var langFile:String = Settings.data.language;
		var loadedText:Array<String> = Paths.getFileContent(isDirectory ? 'locale/$langFile/data.txt' : 'locale/$langFile.txt').split('\n');

		phrases.clear();
		var hasPhrases:Bool = false;
		for (num => phrase in loadedText) {
			phrase = phrase.trim();
			if(num < 1 && !phrase.contains(':'))
			{
				//First line ignores formatting and shit if the line doesn't have ":" because its language_name
				phrases.set('language_name', phrase.trim());
				continue;
			}

			if (phrase.length < 4 || phrase.startsWith('//')) continue; 

			var n:Int = phrase.indexOf(':');
			if(n < 0) continue;

			var key:String = phrase.substr(0, n).trim().toLowerCase();

			var value:String = phrase.substr(n);
			n = value.indexOf('"');
			if(n < 0) continue;

			//trace("Mapped to " + key);
			phrases.set(key, value.substring(n+1, value.lastIndexOf('"')).replace('\\n', '\n'));
			hasPhrases = true;
		}

		if (!hasPhrases) Settings.data.language = Settings.default_data.language;
		Alphabet.loadData(getFileTranslation('data/alphabet'));
		#else
		Alphabet.loadData();
		#end
	}

	inline public static function getPhrase(key:String, ?defaultPhrase:String, values:Array<Dynamic> = null):String {
		#if TRANSLATIONS_ALLOWED
		//trace(formatKey(key));
		var str:String = phrases.get(formatKey(key)) ?? defaultPhrase;
		#else
		var str:String = defaultPhrase;
		#end

		if (str == null) str = key;
		
		if (values != null) {
			for (num => value in values) str = str.replace('{${num + 1}}', value);
		}

		return str;
	}

	public static function getFileTranslation(id:String, ?subFolder:String):String {
		var defaultPath:String = Paths.get(id, subFolder);
		if (!isDirectory) return defaultPath; // not gonna have a file to give if the language doesn't have any

		if (subFolder != null && subFolder.length != 0) subFolder = 'locale/${Settings.data.language}/$subFolder';
		var path:String = Paths.get(id, subFolder);

		if (FileSystem.exists(path)) return path;
		return defaultPath;
	}
	
	#if TRANSLATIONS_ALLOWED
	inline static private function formatKey(key:String) {
		final hideChars = ~/[~&\\\/;:<>#.,'"%?!]/g;
		return hideChars.replace(key.replace(' ', '_'), '').toLowerCase().trim();
	}
	#end
}