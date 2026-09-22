using Giny.Core.DesignPattern;
using Giny.ORM;
using Giny.World.Managers.Effects;
using Giny.World.Managers.Entities.Characters;
using Giny.World.Records.Items;
using System;
using System.Collections.Generic;

namespace Giny.World.Managers.Items.Anomalies
{
    public sealed class AnomalyRollDefinition
    {
        public short EffectId { get; }
        public int Minimum { get; }
        public int Maximum { get; }

        public AnomalyRollDefinition(short effectId, int minimum, int maximum)
        {
            EffectId = effectId;
            Minimum = minimum;
            Maximum = maximum;
        }

        public EffectInteger Roll(Random random) => new EffectInteger(EffectId, random.Next(Minimum, Maximum + 1));
    }

    public sealed class AnomalyRollManager : Singleton<AnomalyRollManager>
    {
        public const int EchoItemId = 32760;
        public const short RepetitionChanceEffectId = 3100;
        public const short RepeatedSpellPowerEffectId = 3101;
        public const short ActiveAnomalyEffectId = 3102;

        private readonly Random m_random = new Random();
        private readonly object m_randomLock = new object();

        private readonly Dictionary<int, AnomalyRollDefinition[]> m_definitions = new()
        {
            [EchoItemId] = new[]
            {
                // Tenths preserve one decimal between 17.0% and 20.0%.
                new AnomalyRollDefinition(RepetitionChanceEffectId, 170, 200),
                new AnomalyRollDefinition(RepeatedSpellPowerEffectId, 40, 60),
            }
        };

        public bool HasDefinition(int itemId) => m_definitions.ContainsKey(itemId);

        public void AddGeneratedRolls(int itemId, EffectCollection effects)
        {
            if (!m_definitions.TryGetValue(itemId, out var definitions))
                return;

            lock (m_randomLock)
            {
                foreach (var definition in definitions)
                    effects.Add(definition.Roll(m_random));
            }
        }

        public CharacterItemRecord GetActiveAnomaly(Character character)
        {
            var uid = character.Record.ActiveAnomalyItemUid;
            if (uid <= 0)
                return null;

            var item = character.Inventory.GetItem(uid);
            return item != null && HasDefinition(item.GId) ? item : null;
        }

        public void SynchronizeActiveMarker(Character character, bool notifyClient = false)
        {
            var activeUid = character.Record.ActiveAnomalyItemUid;
            foreach (var item in character.Inventory.GetItems())
            {
                if (!HasDefinition(item.GId))
                    continue;

                var shouldBeActive = item.UId == activeUid;
                var isActive = GetRoll(item, ActiveAnomalyEffectId) > 0;
                if (shouldBeActive == isActive)
                    continue;

                item.Effects.RemoveAll((Giny.Protocol.Enums.EffectsEnum)ActiveAnomalyEffectId);
                if (shouldBeActive)
                    item.Effects.Add(new EffectInteger(ActiveAnomalyEffectId, 1));
                item.UpdateLater();
                if (notifyClient)
                    character.Inventory.OnItemModified(item);
            }
        }

        public bool Activate(Character character, int uid)
        {
            var item = character.Inventory.GetItem(uid);
            if (item == null || !HasDefinition(item.GId))
                return false;

            character.Record.ActiveAnomalyItemUid = uid;
            character.Record.UpdateLater();
            SynchronizeActiveMarker(character, true);
            return true;
        }

        public void Deactivate(Character character)
        {
            character.Record.ActiveAnomalyItemUid = 0;
            character.Record.UpdateLater();
            SynchronizeActiveMarker(character, true);
        }

        public static int GetRoll(CharacterItemRecord item, short effectId)
        {
            return item?.Effects.GetFirst<EffectInteger>((Giny.Protocol.Enums.EffectsEnum)effectId)?.Value ?? 0;
        }

        public static int EncodeFightResultRolls(CharacterItemRecord item)
        {
            var chance = GetRoll(item, RepetitionChanceEffectId) & 0x1FF;
            var power = GetRoll(item, RepeatedSpellPowerEffectId) & 0x7F;
            return unchecked((int)0x40000000) | (chance << 7) | power;
        }
    }
}
