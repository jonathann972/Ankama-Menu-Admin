using Giny.Core;
using Giny.Core.IO;
using Giny.IO;
using Giny.IO.D2I;
using Giny.IO.D2O;
using Giny.IO.D2OClasses;
using Giny.IO.D2P;
using Giny.ORM;
using Giny.ORM.Interfaces;
using Giny.ORM.IO;
using Giny.World.Managers.Entities.Look;
using Giny.World.Records;
using Giny.World.Records.Achievements;
using Giny.World.Records.Breeds;
using Giny.World.Records.Challenges;
using Giny.World.Records.Characters;
using Giny.World.Records.Effects;
using Giny.World.Records.Items;
using Giny.World.Records.Jobs;
using Giny.World.Records.Maps;
using Giny.World.Records.Monsters;
using Giny.World.Records.Npcs;
using Giny.World.Records.Quests;
using Giny.World.Records.Spells;
using Giny.World.Records.Tinsel;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using static System.Net.Mime.MediaTypeNames;

namespace Giny.DatabaseSynchronizer
{
    class Program
    {
        public static bool SYNC_D2O = true;
        public static bool SYNC_MAPS = true;

        static void Main(string[] args)
        {

            Logger.DrawLogo();

            Logger.Write("Starting synchronization...", Channels.Info);

            


            // === DOFUS ITEM STUDIO SPELL IMPORT ===
            if (args.Length >= 2 && args[0].Equals("--spells", StringComparison.OrdinalIgnoreCase))
            {
                string spellClientPath = args[1];
                try
                {
                    string i18nDirectory = Path.Combine(spellClientPath, ClientConstants.i18nPath);
                    string d2oDirectory = Path.Combine(spellClientPath, ClientConstants.D2oDirectory);
                    if (!Directory.Exists(i18nDirectory) || !Directory.Exists(d2oDirectory))
                        throw new DirectoryNotFoundException("Client Dofus incomplet : " + spellClientPath);
                    D2IManager.Initialize(i18nDirectory);
                    DatabaseManager.Instance.Initialize(Assembly.GetAssembly(typeof(BreedRecord)),
                        "127.0.0.1", "giny_world", "root", "");
                    DatabaseManager.Instance.CreateAllTablesIfNotExists();
                    D2OSynchronizer.ImportAllSpells(spellClientPath);
                }
                catch (Exception ex)
                {
                    Logger.Write("Échec synchronisation sorts : " + ex, Channels.Critical);
                    Environment.ExitCode = 1;
                }
                return;
            }

            // === DOFUS ITEM STUDIO VERIFIED BATCH IMPORT ===
            // One process and one database initialization. No table is dropped.
            if (args.Length >= 4 &&
                args[0].Equals("--items-file", StringComparison.OrdinalIgnoreCase) &&
                args[2].Equals("--client", StringComparison.OrdinalIgnoreCase))
            {
                string itemListPath = args[1];
                string batchClientPath = args[3];
                try
                {
                    if (!File.Exists(itemListPath))
                        throw new FileNotFoundException("Liste d'items introuvable", itemListPath);
                    if (!Directory.Exists(batchClientPath))
                        throw new DirectoryNotFoundException("Client Dofus introuvable : " + batchClientPath);
                    string i18nDirectory = Path.Combine(batchClientPath, ClientConstants.i18nPath);
                    string d2oDirectory = Path.Combine(batchClientPath, ClientConstants.D2oDirectory);
                    if (!Directory.Exists(i18nDirectory) || !Directory.Exists(d2oDirectory))
                        throw new DirectoryNotFoundException("Client incomplet : data/common ou data/i18n absent.");

                    int[] batchItemIds = File.ReadAllText(itemListPath)
                        .Split(new char[] { ',', ';', ' ', '\t', '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries)
                        .Select(int.Parse).Distinct().OrderBy(x => x).ToArray();
                    if (batchItemIds.Length == 0)
                        throw new Exception("La liste d'items est vide.");

                    D2IManager.Initialize(i18nDirectory);
                    DatabaseManager.Instance.Initialize(Assembly.GetAssembly(typeof(BreedRecord)),
                        "127.0.0.1", "giny_world", "root", "");
                    DatabaseManager.Instance.CreateAllTablesIfNotExists();
                    var failures = new List<string>();
                    for (int batchIndex = 0; batchIndex < batchItemIds.Length; batchIndex++)
                    {
                        int batchItemId = batchItemIds[batchIndex];
                        try
                        {
                            D2OSynchronizer.ImportSingleItem(batchItemId, batchClientPath);
                            Console.WriteLine("ITEMSTUDIO_BATCH_VERIFIED:" + batchItemId + ":" +
                                (batchIndex + 1) + "/" + batchItemIds.Length);
                        }
                        catch (Exception itemException)
                        {
                            failures.Add(batchItemId + " => " + itemException.Message);
                            Logger.Write("Échec batch item " + batchItemId + ": " + itemException, Channels.Critical);
                        }
                    }
                    if (failures.Count > 0)
                        throw new Exception(failures.Count + " item(s) en échec : " + String.Join(" | ", failures));
                    Logger.WriteColor1(batchItemIds.Length + " ItemRecord importés et vérifiés.");
                }
                catch (Exception ex)
                {
                    Logger.Write("Échec import batch : " + ex, Channels.Critical);
                    Environment.ExitCode = 1;
                }
                return;
            }

            // === SINGLE ITEM IMPORTER V2 ===
            // Usage:
            //   Giny.DatabaseSynchronizer --item 28563 --client "C:\...\Dofus"
            //
            // Ce bloc doit rester AVANT D2IManager.Initialize(ClientConstants.ClientPath)
            // et AVANT tous les DropTableIfExists.
            if (args.Length >= 4 &&
                args[0].Equals("--item", StringComparison.OrdinalIgnoreCase) &&
                int.TryParse(args[1], out int singleItemId) &&
                args[2].Equals("--client", StringComparison.OrdinalIgnoreCase))
            {
                string singleClientPath = args[3];

                try
                {
                    if (!Directory.Exists(singleClientPath))
                        throw new DirectoryNotFoundException("Client Dofus introuvable : " + singleClientPath);

                    string i18nDirectory = Path.Combine(singleClientPath, ClientConstants.i18nPath);
                    string d2oDirectory = Path.Combine(singleClientPath, ClientConstants.D2oDirectory);

                    if (!Directory.Exists(i18nDirectory))
                        throw new DirectoryNotFoundException("Dossier i18n introuvable : " + i18nDirectory);

                    if (!Directory.Exists(d2oDirectory))
                        throw new DirectoryNotFoundException("Dossier D2O introuvable : " + d2oDirectory);

                    D2IManager.Initialize(i18nDirectory);

                    DatabaseManager.Instance.Initialize(
                        Assembly.GetAssembly(typeof(BreedRecord)),
                        "127.0.0.1", "giny_world", "root", "");

                    DatabaseManager.Instance.CreateAllTablesIfNotExists();

                    D2OSynchronizer.ImportSingleItem(singleItemId, singleClientPath);

                    Logger.WriteColor1(
                        $"Item {singleItemId} importé dans la base serveur depuis {singleClientPath}.");
                }
                catch (Exception ex)
                {
                    Logger.Write(
                        $"Échec import item {singleItemId}: {ex}",
                        Channels.Critical);
                    Environment.ExitCode = 1;
                }

                // V7.0.1 : mode non interactif
                return;
            }


            D2IManager.Initialize(Path.Combine(ClientConstants.ClientPath, ClientConstants.i18nPath));

            DatabaseManager.Instance.Initialize(Assembly.GetAssembly(typeof(BreedRecord)),
              "127.0.0.1", "giny_world", "root", "");

            if (SYNC_D2O)
            {
                DatabaseManager.Instance.DropTableIfExists<RecipeRecord>();
                DatabaseManager.Instance.DropTableIfExists<SubareaRecord>();
                DatabaseManager.Instance.DropTableIfExists<AreaRecord>();
                DatabaseManager.Instance.DropTableIfExists<ItemSetRecord>();
                DatabaseManager.Instance.DropTableIfExists<BreedRecord>();
                DatabaseManager.Instance.DropTableIfExists<ExperienceRecord>();
                DatabaseManager.Instance.DropTableIfExists<HeadRecord>();
                DatabaseManager.Instance.DropTableIfExists<EffectRecord>();
                DatabaseManager.Instance.DropTableIfExists<MapScrollActionRecord>();
                DatabaseManager.Instance.DropTableIfExists<SpellRecord>();
                DatabaseManager.Instance.DropTableIfExists<SpellVariantRecord>();
                DatabaseManager.Instance.DropTableIfExists<ItemRecord>();
                DatabaseManager.Instance.DropTableIfExists<QuestStepRecord>();
                DatabaseManager.Instance.DropTableIfExists<QuestStepRewardRecord>();
                DatabaseManager.Instance.DropTableIfExists<QuestObjectiveRecord>();
                DatabaseManager.Instance.DropTableIfExists<QuestRecord>();
                DatabaseManager.Instance.DropTableIfExists<SpellStateRecord>();
                DatabaseManager.Instance.DropTableIfExists<WeaponRecord>();
                DatabaseManager.Instance.DropTableIfExists<MapReferenceRecord>();
                DatabaseManager.Instance.DropTableIfExists<LivingObjectRecord>();
                DatabaseManager.Instance.DropTableIfExists<EmoteRecord>();
                DatabaseManager.Instance.DropTableIfExists<SpellLevelRecord>();
                DatabaseManager.Instance.DropTableIfExists<OrnamentRecord>();
                DatabaseManager.Instance.DropTableIfExists<TitleRecord>();
                DatabaseManager.Instance.DropTableIfExists<MonsterRecord>();
                DatabaseManager.Instance.DropTableIfExists<SkillRecord>();
                DatabaseManager.Instance.DropTableIfExists<DungeonRecord>();
                DatabaseManager.Instance.DropTableIfExists<MapPositionRecord>();
                DatabaseManager.Instance.DropTableIfExists<NpcRecord>();
                DatabaseManager.Instance.DropTableIfExists<SpellBombRecord>();
                DatabaseManager.Instance.DropTableIfExists<ChallengeRecord>();
                DatabaseManager.Instance.DropTableIfExists<AchievementRewardRecord>();
                DatabaseManager.Instance.DropTableIfExists<AchievementRecord>();
                DatabaseManager.Instance.DropTableIfExists<AchievementObjectiveRecord>();
            }


            if (SYNC_MAPS)
                DatabaseManager.Instance.DropTableIfExists<MapRecord>();

            DatabaseManager.Instance.CreateAllTablesIfNotExists();

            D2OSynchronizer.Synchronize();

            MapSynchronizer.Synchronize();

            Logger.WriteColor1("Build finished.");
            Console.Read();

        }

    }
}
