using Giny.Core;
using Giny.Core.Logging;
using Giny.IO;
using Giny.IO.D2I;
using Giny.IO.D2O;
using Giny.IO.D2OClasses;
using Giny.IO.D2OTypes;
using Giny.ORM;
using Giny.ORM.Interfaces;
using Giny.ORM.IO;
using Giny.Protocol.Custom.Enums;
using Giny.World.Managers.Effects;
using Giny.World.Managers.Entities.Look;
using Giny.World.Records;
using Giny.World.Records.Breeds;
using Giny.World.Records.Characters;
using Giny.World.Records.Items;
using Giny.World.Records.Maps;
using Giny.World.Records.Monsters;
using Giny.World.Records.Quests;
using Swashbuckle.AspNetCore.SwaggerGen;
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using Effect = Giny.World.Managers.Effects.Effect;

namespace Giny.DatabaseSynchronizer
{
    class D2OSynchronizer
    {
        public static List<D2OReader> d2oReaders = new List<D2OReader>();

        public static void Synchronize()
        {
            string d2oDirectory = Path.Combine(ClientConstants.ClientPath, ClientConstants.D2oDirectory);

            foreach (var file in Directory.GetFiles(d2oDirectory))
            {
                if (Path.GetExtension(file) == ".d2o")
                    d2oReaders.Add(new D2OReader(file));
            }

            if (!Program.SYNC_D2O)
            {
                return;
            }

            Logger.Write("Building D2O", Channels.Info);

            var tables = DatabaseManager.Instance.TableTypes.OrderBy(x => x.Name);

            foreach (var tableType in tables)
            {
                var attributes = tableType.GetCustomAttributes<D2OClassAttribute>();

                foreach (var attribute in attributes)
                {
                    if (attribute != null)
                    {
                        var reader = d2oReaders.FirstOrDefault(x => x.Classes.Values.Any(j => j.Name == attribute.Name));

                        if (reader == null)
                        {
                            throw new Exception($"Unable to find D2O class '{attribute.Name}' in D2O files");
                        }
                        Logger.Write("Building " + tableType.Name + "...");

                        IEnumerable<object> d2o = null;

                        if (attribute.Types == null || attribute.Types.Length == 0)
                        {
                            d2o = reader.EnumerateObjects().Where(x => x.GetType().Name == attribute.Name);

                        }
                        else
                        {
                            d2o = reader.EnumerateObjects().Where(x => attribute.Types.Contains(x.GetType()));
                        }

                        var objects = d2o.ToArray();

                        BuildFromObjects(objects, tableType);
                    }
                }

            }

        }


        private static void BuildFromObjects(object[] objects, Type tableType, DatabaseAction action = DatabaseAction.Add)
        {
            var objectType = objects.First().GetType();

            int current = 0;

            ProgressLogger logger = new ProgressLogger();
            const int itemStudioWriteBatchSize = 100;
            var itemStudioPending = new List<IRecord>(itemStudioWriteBatchSize);

            foreach (var obj in objects)
            {
                current++;
                IRecord record = (IRecord)Convert.ChangeType(Activator.CreateInstance(tableType), tableType);

                foreach (var property in tableType.GetProperties())
                {
                    var d2oFieldAttribute = property.GetCustomAttribute<D2OFieldAttribute>();

                    if (d2oFieldAttribute != null)
                    {
                        var d2oField = objectType.GetField(d2oFieldAttribute.FieldName);

                        if (d2oField == null)
                        {
                            throw new Exception("Unknown D2O field : " + d2oFieldAttribute.FieldName +
                                " in " + tableType.Name + " ID=" + record.Id);
                        }
                        var i18nField = property.GetCustomAttribute<I18NFieldAttribute>();

                        if (i18nField != null)
                        {
                            int key = int.Parse(d2oField.GetValue(obj).ToString()); // uint / int cast
                            property.SetValue(record, D2IManager.GetText(key));
                        }
                        else
                        {
                            var value = d2oField.GetValue(obj);

                            if (value == null)
                            {
                                property.SetValue(record, null);
                                continue;
                            }
                            if (value.GetType() == property.PropertyType)
                            {
                                property.SetValue(record, Convert.ChangeType(value, property.PropertyType));
                                continue;
                            }
                            if (value.GetType() == typeof(Point))
                            {
                                value = ConvertPoint((Point)value);
                            }
                            else if (property.PropertyType == typeof(StatUpgradeCost[]))
                            {
                                value = ConvertToStatUpgradeCost(value);
                            }
                            else if (property.PropertyType == typeof(ObjectMapPosition[]))
                            {
                                value = ConvertToObjectMapPosition(value);
                            }
                            else if (property.PropertyType == typeof(EffectCollection))
                            {
                                value = ConvertToServerEffects(((IEnumerable)value).Cast<EffectInstance>());
                            }
                            else if (property.PropertyType == typeof(ServerEntityLook))
                            {
                                value = EntityLookManager.Instance.Parse(value.ToString());
                            }
                            else if (property.PropertyType == typeof(MonsterRacesEnum))
                            {
                                value = Enum.ToObject(property.PropertyType, value);
                            }
                            else if (property.PropertyType == typeof(List<World.Records.Monsters.MonsterGrade>))
                            {
                                value = ConvertToMonsterGrades((List<IO.D2OClasses.MonsterGrade>)value);
                            }
                            else if (property.PropertyType == typeof(List<MonsterRoom>))
                            {
                                value = ConvertMonsterRooms((List<double>)value);
                            }
                            else if (property.PropertyType == typeof(List<World.Records.Monsters.MonsterDrop>))
                            {
                                value = ConvertToMonsterDrop((List<IO.D2OClasses.MonsterDrop>)value);
                            }
                            else if (property.PropertyType == typeof(List<EffectCollection>))
                            {
                                value = ConvertItemSetEffects((List<List<EffectInstance>>)value);
                            }
                            else if (property.PropertyType == typeof(QuestObjectiveParametersRecord))
                            {
                                value = ConvertQuestObjectiveParameters((QuestObjectiveParameters)value);
                            }
                            else if (property.PropertyType == typeof(List<ItemWithQuantity>))
                            {
                                value = ConvertItemWithQuantities((List<List<uint>>)value);
                            }
                            else if (value.GetType().IsGenericType)
                            {
                                var pType = property.PropertyType.GetElementType();

                                if (pType == null)
                                {
                                    pType = property.PropertyType.GetGenericArguments()[0];

                                    var list = (IList)Activator.CreateInstance(typeof(List<>).MakeGenericType(pType));

                                    foreach (var element in (IList)value)
                                    {
                                        list.Add(Convert.ChangeType(element, pType));
                                    }
                                    value = list;

                                }
                                else
                                {
                                    var list = (IList)Activator.CreateInstance(typeof(List<>).MakeGenericType(pType));

                                    foreach (var element in (IList)value)
                                    {
                                        list.Add(Convert.ChangeType(element, pType));
                                    }
                                    value = list.GetType().GetMethod("ToArray").Invoke(list, new object[0]);
                                }
                            }
                            try
                            {
                                property.SetValue(record, Convert.ChangeType(value, property.PropertyType));
                            }
                            catch (Exception ex)
                            {
                                Logger.Write($"Unable to set property {property.Name} to value ({value}) : {ex}", Channels.Warning);
                            }
                        }
                    }
                }

                logger.WriteProgressBar(current, objects.Length);
                itemStudioPending.Add(record);
                if (itemStudioPending.Count >= itemStudioWriteBatchSize)
                    FlushItemStudioBatch(tableType, action, itemStudioPending, current, objects.Length);
            }
            FlushItemStudioBatch(tableType, action, itemStudioPending, current, objects.Length);
            logger.Flush();
        }

        private static void FlushItemStudioBatch(Type tableType, DatabaseAction action, List<IRecord> pending, int current, int total)
        {
            if (pending.Count == 0) return;
            var writer = TableManager.Instance.GetWriter(tableType);
            try
            {
                writer.Use(pending.ToArray(), action);
            }
            catch (Exception batchException)
            {
                foreach (var failedRecord in pending)
                {
                    try { writer.Use(new IRecord[] { failedRecord }, action); }
                    catch (Exception rowException)
                    {
                        throw new Exception($"Échec écriture {tableType.Name} ID={failedRecord.Id} ({current}/{total})", rowException);
                    }
                }
                throw new Exception($"Échec lot {tableType.Name} ({current}/{total})", batchException);
            }
            pending.Clear();
        }

        private static List<ItemWithQuantity> ConvertItemWithQuantities(List<List<uint>> items)
        {
            return items.Select(x => new ItemWithQuantity((short)x[0], (int)x[1])).ToList();
        }
        private static QuestObjectiveParametersRecord ConvertQuestObjectiveParameters(QuestObjectiveParameters value)
        {
            return new QuestObjectiveParametersRecord()
            {
                DungeonOnly = value.DungeonOnly,
                NumParams = value.NumParams,
                Param0 = value.parameter0,
                Param1 = value.parameter1,
                Param2 = value.parameter2,
                Param3 = value.parameter3,
                Param4 = value.parameter4,
            };
        }

        private static PointRecord ConvertPoint(Point? point)
        {
            return new PointRecord(point.y, point.x);
        }
        private static List<MonsterRoom> ConvertMonsterRooms(List<double> mapIds)
        {
            var results = new List<MonsterRoom>();

            foreach (long map in mapIds)
            {
                results.Add(new MonsterRoom(10f, map, new short[0]));
            }
            return results;
        }
        private static List<EffectCollection> ConvertItemSetEffects(List<List<EffectInstance>> value)
        {
            List<EffectCollection> results = new List<EffectCollection>();

            foreach (var list in value)
            {
                EffectCollection effects = ConvertToServerEffects(list);
                results.Add(effects);
            }

            return results;
        }

        private static List<World.Records.Monsters.MonsterDrop> ConvertToMonsterDrop(List<IO.D2OClasses.MonsterDrop> value)
        {
            List<World.Records.Monsters.MonsterDrop> drops = new List<World.Records.Monsters.MonsterDrop>();

            foreach (var val in value)
            {
                drops.Add(new World.Records.Monsters.MonsterDrop()
                {
                    DropLimit = val.count,
                    criteria = val.criteria,
                    ItemGId = val.objectId,
                    HasCriteria = val.hasCriteria,
                    PercentDropForGrade1 = val.PercentDropForGrade1,
                    PercentDropForGrade2 = val.PercentDropForGrade2,
                    PercentDropForGrade3 = val.percentDropForGrade3,
                    PercentDropForGrade4 = val.percentDropForGrade4,
                    PercentDropForGrade5 = val.PercentDropForGrade5
                });
                ; ;
            }
            return drops;
        }

        private static List<World.Records.Monsters.MonsterGrade> ConvertToMonsterGrades(List<IO.D2OClasses.MonsterGrade> value)
        {
            List<World.Records.Monsters.MonsterGrade> grades = new List<World.Records.Monsters.MonsterGrade>();

            foreach (var val in value)
            {
                grades.Add(new World.Records.Monsters.MonsterGrade()
                {
                    Level = (short)val.level,
                    GradeId = (byte)val.grade,
                    ActionPoints = (short)val.ActionPoints,
                    Agility = (short)val.agility,
                    AirResistance = (short)val.airResistance,
                    StartingSpellLevelId = val.startingSpellId,
                    ApDodge = (short)val.paDodge,
                    Chance = (short)val.chance,
                    DamageReflect = (short)val.damageReflect,
                    EarthResistance = (short)val.earthResistance,
                    FireResistance = (short)val.fireResistance,
                    GradeXp = val.gradeXp,
                    HiddenLevel = (short)val.hiddenLevel,
                    Intelligence = (short)val.intelligence,
                    LifePoints = val.lifePoints,
                    MovementPoints = (short)val.movementPoints,
                    MpDodge = (short)val.pmDodge,
                    NeutralResistance = (short)val.neutralResistance,
                    Strength = (short)val.Strength,
                    Vitality = (short)val.vitality,
                    WaterResistance = (short)val.waterResistance,
                    Wisdom = (short)val.wisdom,
                    BonusCharacteristics = ConvertToMonsterBonusCharacteristics(val.BonusCharacteristics),


                }); ; ;
            }
            return grades;
        }

        private static World.Records.Monsters.MonsterBonusCharacteristics ConvertToMonsterBonusCharacteristics(IO.D2OClasses.MonsterBonusCharacteristics input)
        {
            var result = new World.Records.Monsters.MonsterBonusCharacteristics()
            {
                Agility = input.Agility,
                AirResistance = input.AirResistance,
                APRemoval = input.APRemoval,
                BonusAirDamage = input.BonusAirDamage,
                BonusEarthDamage = input.BonusEarthDamage,
                BonusFireDamage = input.BonusFireDamage,
                BonusWaterDamage = input.BonusWaterDamage,
                Chance = input.Chance,
                EarthResistance = input.EarthResistance,
                FireResistance = input.FireResistance,
                Intelligence = input.Intelligence,
                LifePoints = input.LifePoints,
                NeutralResistance = input.NeutralResistance,
                Strength = input.Strength,
                TackleBlock = input.TackleBlock,
                TackleEvade = input.TackleEvade,
                WaterResistance = input.WaterResistance,
                Wisdom = input.Wisdom,
            };

            return result;

        }
        private static EffectCollection ConvertToServerEffects(IEnumerable<EffectInstance> effectInstances)
        {
            EffectCollection results = new EffectCollection();

            foreach (var effectInstance in effectInstances)
            {
                if (effectInstance == null)
                {
                    continue;
                }
                else
                {
                    if (!effectInstance.ForClientOnly)
                        results.Add(BuildEffect(effectInstance));

                }
            }
            return results;
        }
        private static Effect BuildEffect(EffectInstance effectInstance)
        {
            var effectDice = effectInstance as EffectInstanceDice;

            if (effectDice != null)
            {
                return new EffectDice((short)effectDice.EffectId, (int)effectDice.diceNum, (int)effectDice.DiceSide, effectDice.value)
                {

                    Delay = effectDice.delay,
                    Dispellable = effectDice.dispellable,
                    Duration = effectDice.duration,
                    Group = effectDice.group,
                    Modificator = effectDice.modificator,
                    Order = effectDice.order,
                    Trigger = effectDice.trigger,
                    RawTriggers = effectDice.triggers,
                    RawZone = effectDice.rawZone,
                    TargetMask = effectDice.TargetMask,
                    Random = effectDice.random,
                    TargetId = effectDice.targetId,
                };
            }


            throw new Exception();
        }
        private static ObjectMapPosition[] ConvertToObjectMapPosition(object value)
        {
            var l1 = ((IEnumerable)value).Cast<object>().ToList();

            ObjectMapPosition[] result = new ObjectMapPosition[l1.Count];

            for (int i = 0; i < l1.Count; i++)
            {
                var l2 = ((IEnumerable)l1[i]).Cast<object>().ToList();
                result[i] = new ObjectMapPosition((int)Convert.ChangeType(l2[0], typeof(int)), (int)Convert.ChangeType(l2[1], typeof(int)));
            }

            return result;
        }

        private static StatUpgradeCost[] ConvertToStatUpgradeCost(object value)
        {
            var l1 = ((IEnumerable)value).Cast<object>().ToList();

            StatUpgradeCost[] upgradeCost = new StatUpgradeCost[l1.Count];

            for (int i = 0; i < l1.Count; i++)
            {
                var l2 = ((IEnumerable)l1[i]).Cast<object>().ToList();

                upgradeCost[i] = new StatUpgradeCost((short)Convert.ChangeType(l2[0], typeof(short)), (short)Convert.ChangeType(l2[1], typeof(short)));
            }


            return upgradeCost;
        }
    

        // === DOFUS ITEM STUDIO BATCH D2O CACHE ===
        private static List<D2OReader> itemStudioReaders;
        private static string itemStudioReaderPath;

        // === SINGLE ITEM IMPORTER V2 ===
        /// <summary>
        /// Importe un seul item depuis le client choisi en argument.
        /// N'utilise pas ClientConstants.ClientPath.
        /// Ne supprime aucune table.
        /// </summary>
        public static void ImportSingleItem(int itemId, string clientPath)
        {
            string d2oDirectory = Path.Combine(clientPath, ClientConstants.D2oDirectory);

            if (!Directory.Exists(d2oDirectory))
                throw new DirectoryNotFoundException("Dossier D2O introuvable : " + d2oDirectory);

            // On utilise une liste locale pour être sûr de lire le client choisi,
            // même si une autre synchro a déjà alimenté d2oReaders.
            if (itemStudioReaders == null ||
                !String.Equals(itemStudioReaderPath, d2oDirectory, StringComparison.OrdinalIgnoreCase))
            {
                itemStudioReaders = new List<D2OReader>();
                itemStudioReaderPath = d2oDirectory;
                foreach (var file in Directory.GetFiles(d2oDirectory))
                {
                    if (Path.GetExtension(file).Equals(".d2o", StringComparison.OrdinalIgnoreCase))
                        itemStudioReaders.Add(new D2OReader(file));
                }
            }
            var localReaders = itemStudioReaders;

            try
            {
                var itemReader = localReaders.FirstOrDefault(
                    x => x.Classes.Values.Any(c => c.Name == "Item"));

                if (itemReader == null)
                    throw new Exception("Aucun D2O contenant la classe Item n'a été trouvé.");

                if (!itemReader.ObjectExists(itemId))
                    throw new Exception(
                        $"L'item {itemId} n'existe pas dans le Items.d2o du client choisi.");

                object itemObject = itemReader.ReadObject(itemId, true);

                if (itemObject == null)
                    throw new Exception($"Impossible de lire l'item {itemId}.");

                string itemClassName = itemObject.GetType().Name;
                bool isWeapon = itemClassName == "Weapon";
                if (itemClassName != "Item" && !isWeapon)
                    throw new Exception(
                        $"L'index {itemId} correspond à {itemClassName}, ni à Item ni à Weapon.");

                // Import the server dependency before ItemRecord. HasSet is based
                // on ItemSetId, so allowing a dangling foreign reference makes
                // ItemRecord.Initialize resolve ItemSet to null.
                var setProperty = itemObject.GetType().GetProperty("itemSetId");
                var setField = itemObject.GetType().GetField("itemSetId");
                object setValue = setProperty != null ? setProperty.GetValue(itemObject) : setField?.GetValue(itemObject);
                int itemSetId = setValue == null ? -1 : Convert.ToInt32(setValue);
                if (itemSetId >= 0)
                {
                    var setReader = localReaders.FirstOrDefault(
                        x => x.Classes.Values.Any(c => c.Name == "ItemSet"));
                    if (setReader == null || !setReader.ObjectExists(itemSetId))
                        throw new Exception($"ItemSet {itemSetId} référencé par l'item {itemId} absent du client.");
                    object setObject = setReader.ReadObject(itemSetId, true);
                    bool setExists = DatabaseReader.ReadFirst<ItemSetRecord>("Id", itemSetId.ToString()) != null;
                    BuildFromObjects(new object[] { setObject }, typeof(ItemSetRecord),
                        setExists ? DatabaseAction.Update : DatabaseAction.Add);
                    var verifiedSet = DatabaseReader.ReadFirst<ItemSetRecord>("Id", itemSetId.ToString());
                    if (verifiedSet == null || verifiedSet.Id != itemSetId)
                        throw new Exception($"Vérification DB impossible pour ItemSetRecord {itemSetId}.");
                    Console.WriteLine("ITEMSTUDIO_ITEMSET_VERIFIED:" + itemSetId);
                }

                bool existedBefore = DatabaseReader.ReadFirst<ItemRecord>("Id", itemId.ToString()) != null;
                if (isWeapon)
                {
                    bool weaponExists = DatabaseReader.ReadFirst<WeaponRecord>("Id", itemId.ToString()) != null;
                    BuildFromObjects(new object[] { itemObject }, typeof(WeaponRecord),
                        weaponExists ? DatabaseAction.Update : DatabaseAction.Add);
                    var verifiedWeapon = DatabaseReader.ReadFirst<WeaponRecord>("Id", itemId.ToString());
                    if (verifiedWeapon == null || verifiedWeapon.Id != itemId)
                        throw new Exception($"Vérification DB impossible pour WeaponRecord {itemId}.");
                    var itemFromWeapon = verifiedWeapon.ToItemRecord();
                    TableManager.Instance.GetWriter(typeof(ItemRecord)).Use(new IRecord[] { itemFromWeapon },
                        existedBefore ? DatabaseAction.Update : DatabaseAction.Add);
                    Console.WriteLine("ITEMSTUDIO_WEAPON_VERIFIED:" + itemId);
                }
                else
                {
                    BuildFromObjects(new object[] { itemObject }, typeof(ItemRecord),
                        existedBefore ? DatabaseAction.Update : DatabaseAction.Add);
                }

                // === DOFUS ITEM STUDIO VERIFIED SINGLE IMPORT ===
                var verified = DatabaseReader.ReadFirst<ItemRecord>("Id", itemId.ToString());
                if (verified == null || verified.Id != itemId)
                    throw new Exception($"Vérification DB impossible pour ItemRecord {itemId}.");
                Console.WriteLine("ITEMSTUDIO_SERVER_VERIFIED:" + itemId);
            }
            finally
            {
                // Readers are shared by every ID in this CLI process and released on exit.
            }
        }


        // === DOFUS ITEM STUDIO SPELL IMPORT ===
        public static void ImportAllSpells(string clientPath)
        {
            string d2oDirectory = Path.Combine(clientPath, ClientConstants.D2oDirectory);
            var levelReader = new D2OReader(Path.Combine(d2oDirectory, "SpellLevels.d2o"));
            var spellReader = new D2OReader(Path.Combine(d2oDirectory, "Spells.d2o"));
            try
            {
                object[] levels = levelReader.EnumerateObjects().Where(x => x.GetType().Name == "SpellLevel").ToArray();
                object[] spells = spellReader.EnumerateObjects().Where(x => x.GetType().Name == "Spell").ToArray();
                DatabaseManager.Instance.DeleteTable<Giny.World.Records.Spells.SpellLevelRecord>();
                DatabaseManager.Instance.DeleteTable<Giny.World.Records.Spells.SpellRecord>();
                BuildFromObjects(levels, typeof(Giny.World.Records.Spells.SpellLevelRecord), DatabaseAction.Add);
                BuildFromObjects(spells, typeof(Giny.World.Records.Spells.SpellRecord), DatabaseAction.Add);
                int verifiedLevels = DatabaseReader.Select<Giny.World.Records.Spells.SpellLevelRecord>().Count();
                int verifiedSpells = DatabaseReader.Select<Giny.World.Records.Spells.SpellRecord>().Count();
                if (verifiedLevels != levels.Length || verifiedSpells != spells.Length)
                    throw new Exception("Comptage SQL incorrect après import : " +
                        verifiedSpells + "/" + spells.Length + " sorts, " +
                        verifiedLevels + "/" + levels.Length + " niveaux.");
                Console.WriteLine("ITEMSTUDIO_SPELLS_VERIFIED:" + verifiedSpells + ":" + verifiedLevels);
            }
            finally
            {
                levelReader.Close();
                spellReader.Close();
            }
        }

}
}
