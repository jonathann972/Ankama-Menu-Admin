using Giny.World.Records.Monsters;
using System.Linq;

namespace Giny.World.Managers.Items.Anomalies
{
    public static class AnomalyDropManager
    {
        private const short RoyalGobballMonsterId = 147;

        public static void ConfigureDevelopmentDrops()
        {
            var royalGobball = MonsterRecord.GetMonsterRecord(RoyalGobballMonsterId);
            if (royalGobball == null)
                return;

            AddDevelopmentDrop(royalGobball, AnomalyRollManager.EchoItemId);
            AddDevelopmentDrop(royalGobball, AnomalyRollManager.RemanenceItemId);
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
