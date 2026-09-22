using Giny.World.Handlers.Roleplay.HeavenBag;
using Giny.World.Network;
using Giny.World.Records.Maps;

var bag = HeavenBagHandler.HavenBagMapId;
MapRecord.Maps = new() { [10] = new(10), [20] = new(20), [30] = new(30), [bag] = new(bag) };
WorldClient NewClient(long map = 10) => new() { Character = new() { Record = new() { MapId = map, CellId = 123, SpawnPointMapId = 20 } } };
void Enter(WorldClient c) => HeavenBagHandler.HandleEnterHavenBagRequest(new(), c);
void Exit(WorldClient c) => HeavenBagHandler.HandleExitHavenBagRequest(new(), c);
void Check(bool condition, string label) { if (!condition) throw new Exception(label); Console.WriteLine("PASS " + label); }
var c = NewClient(); Enter(c); Exit(c);
Check(c.Character.Record.MapId == 10 && c.Character.Record.CellId == 123 && c.Character.HavenBagReturnPosition == null, "entry/exit preserves original map and cell");
c = NewClient(); Enter(c); Enter(c);
Check(c.Character.Record.MapId == 10, "second entry click exits shared haven map");
c = NewClient(bag); Exit(c);
Check(c.Character.Record.MapId == 20, "trapped/reconnected character returns to saved spawn");
c = NewClient(bag); c.Character.Record.SpawnPointMapId = 999; Exit(c);
Check(c.Character.Record.MapId == 30, "missing saved spawn uses configured spawn");
c = NewClient(); Exit(c); Check(c.Character.Teleports == 0, "outside exit ignored");
foreach (var state in new[] { "fight", "busy", "loading" }) {
    c = NewClient(); c.Character.Fighting = state == "fight"; c.Character.Busy = state == "busy"; c.Character.ChangeMap = state == "loading";
    Enter(c); Check(c.Character.Teleports == 0, state + " entry ignored");
    c.Character.Record.MapId = bag; Exit(c); Check(c.Character.Teleports == 0, state + " exit ignored");
}
c = NewClient(); c.Character.FailTeleport = true; Enter(c);
Check(c.Character.HavenBagReturnPosition == null, "failed entry does not record visit");
c = NewClient(); Enter(c); c.Character.FailTeleport = true; Exit(c);
Check(c.Character.HavenBagReturnPosition.HasValue, "failed exit preserves return position");
HeavenBagHandler.HandleExitHavenBagRequest(new(), new());
Check(typeof(HeavenBagHandler).GetMethod("HandleExitHavenBagRequest").IsDefined(typeof(Giny.Core.Network.Messages.MessageHandlerAttribute), false), "exit handler registered");

// Minimal collaborators exercise the actual production handler without a live player.
namespace Giny.Core.Network.Messages { public class MessageHandlerAttribute : Attribute {} }
namespace Giny.Protocol.Messages { public class EnterHavenBagRequestMessage {} public class ExitHavenBagRequestMessage {} }
namespace Giny.Core.IO.Configuration { public class ConfigManager<T> where T : new() { public static T Instance = new(); } }
namespace Giny.World { public class WorldConfig { public long SpawnMapId = 30; public short SpawnCellId = 400; } }
namespace Giny.World.Records.Maps {
    public class MapRecord(long id) { public long Id = id; public static Dictionary<long, MapRecord> Maps; public static MapRecord GetMap(long id) => Maps.GetValueOrDefault(id); }
}
namespace Giny.World.Network {
    public class WorldClient { public TestCharacter Character; }
    public class TestRecord { public long MapId, SpawnPointMapId; public short CellId; }
    public class TestCharacter {
        public TestRecord Record; public bool Fighting, Busy, ChangeMap, FailTeleport; public int Teleports;
        public (long MapId, short CellId)? HavenBagReturnPosition;
        public void Teleport(long id) => Teleport(MapRecord.GetMap(id));
        public void Teleport(MapRecord map, short? cell = null) { Teleports++; if (FailTeleport || map == null) return; Record.MapId = map.Id; Record.CellId = cell ?? 0; }
    }
}
