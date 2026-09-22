using Giny.Core.Network.Messages;
using Giny.Protocol.Messages;
using Giny.World.Network;
using Giny.Core.IO.Configuration;
using Giny.World.Records.Maps;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Giny.World.Handlers.Roleplay.HeavenBag
{
    class HeavenBagHandler
    {
        public const long HavenBagMapId = 162791424;

        [MessageHandler]
        public static void HandleEnterHavenBagRequest(EnterHavenBagRequestMessage message, WorldClient client)
        {
            var character = client.Character;
            if (character == null || character.Fighting || character.Busy || character.ChangeMap)
                return;

            // This simple shared map does not use the full haven-bag UI protocol.
            // Clicking the haven-bag button again must therefore also allow leaving.
            if (character.Record.MapId == HavenBagMapId)
            {
                HandleExitHavenBagRequest(new ExitHavenBagRequestMessage(), client);
                return;
            }

            var origin = (character.Record.MapId, character.Record.CellId);
            character.Teleport(HavenBagMapId);
            if (character.Record.MapId == HavenBagMapId)
                character.HavenBagReturnPosition = origin;
        }

        [MessageHandler]
        public static void HandleExitHavenBagRequest(ExitHavenBagRequestMessage message, WorldClient client)
        {
            var character = client.Character;
            if (character == null || character.Fighting || character.Busy || character.ChangeMap ||
                character.Record.MapId != HavenBagMapId)
                return;

            var origin = character.HavenBagReturnPosition;
            var target = origin.HasValue ? MapRecord.GetMap(origin.Value.MapId) : null;
            short? cell = origin?.CellId;
            if (target == null || target.Id == HavenBagMapId)
            {
                // Covers reconnects and characters trapped before this fix.
                target = MapRecord.GetMap(character.Record.SpawnPointMapId);
                cell = null;
            }
            if (target == null || target.Id == HavenBagMapId)
            {
                var config = ConfigManager<WorldConfig>.Instance;
                target = MapRecord.GetMap(config.SpawnMapId);
                cell = config.SpawnCellId;
            }

            character.Teleport(target, cell);
            if (character.Record.MapId != HavenBagMapId)
                character.HavenBagReturnPosition = null;
        }
    }
}
