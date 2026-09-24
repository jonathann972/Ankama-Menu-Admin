using Giny.World.Records.Monsters;
using System.Linq;

namespace Giny.World.Managers.Items.Anomalies
{
    public static class AnomalyDropManager
    {
        private const short RoyalGobballMonsterId = 147;
        private const short RasboulMonsterId = 1071;
        private const double RemanenceDropRate = 1d;

        public static void ConfigureDevelopmentDrops()
        {
            var royalGobball = MonsterRecord.GetMonsterRecord(RoyalGobballMonsterId);
            if (royalGobball == null)
                return;

            AddDevelopmentDrop(royalGobball, AnomalyRollManager.EchoItemId);
        }

        public static void ConfigureOfficialDrops()
        {
            var rasboul = MonsterRecord.GetMonsterRecord(RasboulMonsterId);
            if (rasboul == null)
                return;

            if (rasboul.Drops.Any(x => x.ItemGId == AnomalyRollManager.RemanenceItemId))
                return;

            rasboul.Drops.Add(new MonsterDrop
            {
                ItemGId = AnomalyRollManager.RemanenceItemId,
                PercentDropForGrade1 = RemanenceDropRate,
                PercentDropForGrade2 = RemanenceDropRate,
                PercentDropForGrade3 = RemanenceDropRate,
                PercentDropForGrade4 = RemanenceDropRate,
                PercentDropForGrade5 = RemanenceDropRate,
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
