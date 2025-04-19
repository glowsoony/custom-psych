package backend;

class EventHandler {
    public dynamic function triggered(event:Event) {}

	// just so it doesn't yell at me
	public function new() {}

    public var list:Array<Event> = [];
    public var index:Int = 0;
    public function load(song:String):EventHandler {
        // has to be per song instead
        // because of sm/osu support
        if (!Paths.exists('songs/$song/events.json')) return this;

        list.resize(0);

        final data = Json.parse(Paths.getFileContent('songs/$song/events.json')).song;
		var events:Array<Dynamic> = data.events;
		for (i => event in events) {
			if (event[1] == -1) { // pre-0.6 events
				// [time, noteData (-1), name, value1, value2]
				var eventToPush:Event = {
					name: events[2], 
					time: event[0], 
					args: [events[3], events[4]]
				};

				list.push(eventToPush);
			} else if (Std.isOfType(event[1], Array)) { // modern events
				// [time, [ [name, value1, value2] ]]
				var subEvents:Array<Dynamic> = event[1];
				for (subEvent in subEvents) {
					var eventToPush:Event = {
						name: subEvent[0], 
						time: event[0], 
						args: [subEvent[1], subEvent[2]]
					};
					list.push(eventToPush);
				}
			}
        }

        index = 0;
		list.sort((a, b) -> return Std.int(a.time - b.time));

		return this;
    }

    public function update():Void {
        if (index >= list.length) return;

        final nextEvent:Event = list[index];
        if (nextEvent.time > Conductor.rawTime + Conductor.songOffset) return;
        triggered(nextEvent);
        index++;
    }
}

@:structInit 
class Event {
    public var name:String = '';
    public var time:Float = 0.0;
    public var args:Array<Dynamic> = [];

	public function toString():String {
		return 'Name: $name | Time: $time | Arguments: $args';
	}
}