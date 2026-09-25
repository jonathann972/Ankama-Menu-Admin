using Giny.World.Records.Monsters;
using System.Collections.Generic;
using System.Linq;

namespace Giny.World.Managers.Items.Anomalies
{
    public static class AnomalyDropManager
    {
        private const short RoyalGobballMonsterId = 147;
        private const int CataclysmeItemId = 32869;

        private static readonly HashSet<long> EliocalypseStormMapIds = new HashSet<long>
        {
            204472320,
            204473344,
            204474368,
            204475392,
            204476416,
        };

        public static bool CanDrop(int itemGid, long mapId)
        {
            return itemGid != CataclysmeItemId || EliocalypseStormMapIds.Contains(mapId);
        }

        public static void ConfigureDevelopmentDrops()
        {
            var royalGobball = MonsterRecord.GetMonsterRecord(RoyalGobballMonsterId);
            if (royalGobball == null)
                return;

            AddDevelopmentDrop(royalGobball, AnomalyRollManager.EchoItemId);
            AddDevelopmentDrop(royalGobball, AnomalyRollManager.RemanenceItemId);
            AddFixedDrop(royalGobball, AnomalyRollManager.ToisonItemId, 1d);
        }

        private static void AddFixedDrop(MonsterRecord monster, int itemGid, double percent)
        {
            if (monster.Drops.Any(x => x.ItemGId == itemGid))
                return;

            monster.Drops.Add(new MonsterDrop
            {
                ItemGId = itemGid,
                PercentDropForGrade1 = percent,
                PercentDropForGrade2 = percent,
                PercentDropForGrade3 = percent,
                PercentDropForGrade4 = percent,
                PercentDropForGrade5 = percent,
                DropLimit = 1,
                ProspectingLock = 0,
                RollsCounter = 1,
                criteria = string.Empty,
                HasCriteria = false,
            });
        }

        private static void AddDevelopmentDrop(MonsterRecord monster, int itemGid)
        {
            if (monster.Drops.Any(x => x.ItemGId == itemGid))
                return;

            monster.Drops.Add(new MonsterDrop
            {
                ItemGId = itemGid,
                PercentDropForGrade1 = 100,
                PercentDropForGrade2 = 100,
                PercentDropForGrade3 = 100,
                PercentDropForGrade4 = 100,
                PercentDropForGrade5 = 100,
                DropLimit = 1,
                ProspectingLock = 0,
                RollsCounter = 1,
                criteria = string.Empty,
                HasCriteria = false,
            });
        }
    }
}
