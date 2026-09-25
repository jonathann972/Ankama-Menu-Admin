using System.Buffers.Binary;
using System.Reflection;
using System.Text;
using System.Text.Json;
using Giny.IO.D2I;
using Giny.IO.D2O;
using Giny.IO.D2OClasses;
using Giny.IO.D2P;

if (args.Length == 3 && args[0] == "bosses")
{
    var bossDofus = Path.GetFullPath(args[1]);
    var bossOutput = Path.GetFullPath(args[2]);
    D2OManager.Initialize(Path.Combine(bossDofus, "data", "common"));
    D2IManager.Initialize(Path.Combine(bossDofus, "data", "i18n"));
    var bosses = D2OManager.GetObjects("Monsters.d2o").Cast<Monster>()
        .Where(x => x.isBoss && !x.isMiniBoss)
        .Select(x => new
        {
            x.id,
            Name = D2IManager.GetText((int)x.nameId),
            MinLevel = x.grades.Count == 0 ? 0u : x.grades.Min(g => g.level),
            MaxLevel = x.grades.Count == 0 ? 0u : x.grades.Max(g => g.level)
        })
        .OrderBy(x => x.Name, StringComparer.CurrentCultureIgnoreCase)
        .ToArray();
    var lines = new List<string>
    {
        "LISTE DES BOSS — DOFUS 2.68",
        "================================",
        $"Total : {bosses.Length} boss",
        "Valeur à copier dans anomaly.json : bossMonsterId",
        "",
        "bossMonsterId | Niveau | Nom"
    };
    lines.AddRange(bosses.Select(x => $"{x.id,-13} | {(x.MinLevel == x.MaxLevel ? x.MinLevel : $"{x.MinLevel}-{x.MaxLevel}"),-7} | {x.Name}"));
    Directory.CreateDirectory(Path.GetDirectoryName(bossOutput)!);
    File.WriteAllLines(bossOutput, lines, new UTF8Encoding(true));
    Console.WriteLine($"BOSSES OK count={bosses.Length} file={bossOutput}");
    return 0;
}

if (args.Length != 3 || args[0] is not ("audit" or "apply" or "verify" or "rollback" or "repair-drop"))
{
    Console.Error.WriteLine("Usage: AnomalyCreator <audit|apply|verify|rollback|repair-drop> <anomaly.json> <Dofus directory> | bosses <Dofus directory> <output.txt>");
    return 2;
}

var mode = args[0];
var configFile = Path.GetFullPath(args[1]);
var cfg = JsonSerializer.Deserialize<Config>(File.ReadAllText(configFile), new JsonSerializerOptions { PropertyNameCaseInsensitive = true })
          ?? throw new InvalidOperationException("Configuration JSON invalide.");
ValidateConfig(cfg, configFile);
var bossMonsterIds = cfg.GetBossMonsterIds();

var dofus = Path.GetFullPath(args[2]);
var common = Path.Combine(dofus, "data", "common");
var i18nDirectory = Path.Combine(dofus, "data", "i18n");
var itemsFile = Path.Combine(common, "Items.d2o");
var monstersFile = Path.Combine(common, "Monsters.d2o");
var i18nFile = Path.Combine(i18nDirectory, "i18n_fr.d2i");
var bitmapFile = Path.Combine(dofus, "content", "gfx", "items", "bitmap0_1.d2p");
var files = new[] { itemsFile, monstersFile, i18nFile, bitmapFile };
foreach (var file in files)
    if (!File.Exists(file)) throw new FileNotFoundException("Fichier client requis introuvable.", file);

var iconFile = Path.IsPathRooted(cfg.IconFile) ? cfg.IconFile : Path.Combine(Path.GetDirectoryName(configFile)!, cfg.IconFile);
var state = Inspect(common, bitmapFile, cfg);
PrintState(state, cfg);

if (mode == "audit")
{
    GenerateIntegrationNotes(cfg, configFile);
    return state.ItemExists || state.IconExists || state.DropExists || state.EffectCollisions.Count > 0 ? 1 : 0;
}

var backupRoot = Path.Combine(dofus, "AnomalyCreatorBackups", cfg.Gid.ToString());
if (mode == "rollback")
{
    if (!Directory.Exists(backupRoot)) throw new InvalidOperationException("Aucune sauvegarde disponible pour ce GID.");
    var latest = Directory.GetDirectories(backupRoot).OrderByDescending(x => x).First();
    foreach (var file in files)
    {
        var backup = Path.Combine(latest, Path.GetFileName(file));
        if (!File.Exists(backup)) throw new InvalidOperationException($"Sauvegarde incomplète : {backup}");
        File.Copy(backup, file, true);
    }
    Console.WriteLine($"ROLLBACK OK <- {latest}");
    return 0;
}

if (mode == "repair-drop")
{
    D2OManager.Initialize(common);
    var monsters = D2OManager.GetObjects("Monsters.d2o").Cast<Monster>().ToArray();
    var sourceMonsters = monsters.Where(x => x.drops?.Any(d => d.objectId == cfg.Gid) == true).ToArray();
    var existingDrop = sourceMonsters.SelectMany(x => x.drops).FirstOrDefault(x => x.objectId == cfg.Gid);
    var backup = Path.Combine(backupRoot, DateTime.Now.ToString("yyyyMMdd-HHmmss") + "-repair-drop");
    Directory.CreateDirectory(backup);
    File.Copy(monstersFile, Path.Combine(backup, Path.GetFileName(monstersFile)));

    foreach (var source in sourceMonsters.Where(x => !bossMonsterIds.Contains(x.id)))
    {
        var reader = new D2OReader(monstersFile);
        var current = reader.ReadObject<Monster>(source.id);
        reader.Close();
        current.drops.RemoveAll(x => x.objectId == cfg.Gid);
        ReplaceObject(monstersFile, source.id, current);
    }

    var nextRepairDropId = monsters.SelectMany(x => x.drops ?? new List<MonsterDrop>()).Max(x => x.dropId) + 1;
    foreach (var bossId in bossMonsterIds)
    {
        var targetReader = new D2OReader(monstersFile);
        var target = targetReader.ReadObject<Monster>(bossId);
        targetReader.Close();
        target.drops.RemoveAll(x => x.objectId == cfg.Gid);
        var drop = new MonsterDrop
        {
            dropId = nextRepairDropId++, monsterId = bossId, objectId = cfg.Gid,
            count = 1, criteria = string.Empty, hasCriteria = false,
            hiddenIfInvalidCriteria = false, specificDropCoefficient = new List<MonsterDropCoefficient>(),
            percentDropForGrade1 = cfg.DropPercent, percentDropForGrade2 = cfg.DropPercent,
            percentDropForGrade3 = cfg.DropPercent, percentDropForGrade4 = cfg.DropPercent,
            percentDropForGrade5 = cfg.DropPercent
        };
        target.drops.Add(drop);
        ReplaceObject(monstersFile, bossId, target);
    }
    Console.WriteLine($"REPAIR DROP OK gid={cfg.Gid} anciensBoss=[{string.Join(',', sourceMonsters.Select(x => x.id))}] nouveauxBoss=[{string.Join(',', bossMonsterIds)}] sauvegarde={backup}");
    return 0;
}

if (mode == "apply")
{
    if (state.ItemExists || state.IconExists || state.DropExists)
        throw new InvalidOperationException("Le GID, l'icône ou le drop existe déjà. Utilisez un identifiant libre.");
    if (state.EffectCollisions.Count > 0)
        throw new InvalidOperationException("Collision EffectId : " + string.Join(", ", state.EffectCollisions));
    if (!File.Exists(iconFile)) throw new FileNotFoundException("PNG introuvable.", iconFile);
    var png = File.ReadAllBytes(iconFile);
    if (png.Length < 24 || BinaryPrimitives.ReadInt32BigEndian(png.AsSpan(16, 4)) != 64 || BinaryPrimitives.ReadInt32BigEndian(png.AsSpan(20, 4)) != 64)
        throw new InvalidOperationException("L'icône doit être un PNG 64×64.");

    var backup = Path.Combine(backupRoot, DateTime.Now.ToString("yyyyMMdd-HHmmss"));
    Directory.CreateDirectory(backup);
    foreach (var file in files) File.Copy(file, Path.Combine(backup, Path.GetFileName(file)));

    var itemReader = new D2OReader(itemsFile);
    var item = Clone(itemReader.ReadObject<Item>(cfg.TemplateGid));
    itemReader.Close();
    D2IManager.Initialize(i18nDirectory);
    var textId = D2IManager.GetAllText().Max(x => x.Key) + 1;
    item.id = cfg.Gid; item.nameId = (uint)textId; item.descriptionId = (uint)(textId + 1);
    item.typeId = 290; item.iconId = (uint)cfg.Gid; item.level = (uint)cfg.Level; item.changeVersion = "AnomalyCreator";
    D2IManager.SetText(textId, cfg.Name);
    D2IManager.SetText(textId + 1, $"Rareté : {cfg.Rarity}\n{cfg.Description}");
    D2IManager.SaveAll();
    AddObject(itemsFile, cfg.Gid, item);

    using (var d2p = new D2PFile(bitmapFile)) { d2p.AddFile($"{cfg.Gid}.png", png); d2p.Save(); }

    D2OManager.Initialize(common);
    var nextDropId = D2OManager.GetObjects("Monsters.d2o").Cast<Monster>()
        .SelectMany(x => x.drops ?? new List<MonsterDrop>()).Max(x => x.dropId) + 1;
    foreach (var bossId in bossMonsterIds)
    {
        var monsterReader = new D2OReader(monstersFile);
        var monster = monsterReader.ReadObject<Monster>(bossId);
        monsterReader.Close();
        monster.drops.Add(new MonsterDrop
        {
            dropId = nextDropId++, monsterId = bossId, objectId = cfg.Gid,
            percentDropForGrade1 = cfg.DropPercent, percentDropForGrade2 = cfg.DropPercent,
            percentDropForGrade3 = cfg.DropPercent, percentDropForGrade4 = cfg.DropPercent,
            percentDropForGrade5 = cfg.DropPercent, count = 1, criteria = string.Empty,
            hasCriteria = false, hiddenIfInvalidCriteria = false,
            specificDropCoefficient = new List<MonsterDropCoefficient>()
        });
        ReplaceObject(monstersFile, bossId, monster);
    }
    GenerateIntegrationNotes(cfg, configFile);
    Console.WriteLine($"APPLY OK - sauvegarde : {backup}");
}

var verified = Inspect(common, bitmapFile, cfg);
PrintState(verified, cfg);
return verified.ItemExists && verified.IconExists && verified.DropExists ? 0 : 1;

static State Inspect(string common, string bitmap, Config cfg)
{
    D2OManager.Initialize(common);
    var items = D2OManager.GetObjects("Items.d2o").Cast<Item>().ToArray();
    var monsters = D2OManager.GetObjects("Monsters.d2o").Cast<Monster>().ToArray();
    var item = items.FirstOrDefault(x => x.id == cfg.Gid);
    var bossIds = cfg.GetBossMonsterIds();
    var missingBossIds = bossIds.Where(id => monsters.All(x => x.id != id)).ToArray();
    if (missingBossIds.Length > 0)
        throw new InvalidOperationException($"Boss MonsterId introuvable(s): {string.Join(',', missingBossIds)}.");
    using var d2p = new D2PFile(bitmap);
    var usedEffects = cfg.Effects.Select(x => x.Id).Where(id => id is < 3000 or > 3999).ToList();
    return new State(item != null, d2p.Entries.Any(x => x.FullFileName == $"{cfg.Gid}.png"),
        bossIds.All(id => monsters.First(x => x.id == id).drops.Any(x => x.objectId == cfg.Gid)), usedEffects);
}

static void PrintState(State state, Config cfg) => Console.WriteLine(
    $"AUDIT gid={cfg.Gid} item={(state.ItemExists ? "EXISTS" : "FREE")} icon={(state.IconExists ? "EXISTS" : "FREE")} " +
    $"boss=[{string.Join(',', cfg.GetBossMonsterIds())}] drop={(state.DropExists ? "EXISTS" : "FREE")} effects={(state.EffectCollisions.Count == 0 ? "OK" : string.Join(',', state.EffectCollisions))}");

static void ValidateConfig(Config c, string file)
{
    if (c.Gid <= 0 || c.TemplateGid <= 0 || c.GetBossMonsterIds().Count == 0 || c.GetBossMonsterIds().Any(x => x <= 0) || c.Level < 1 || c.DropPercent is <= 0 or > 100)
        throw new InvalidOperationException("GID/template/boss/niveau/taux invalides.");
    if (string.IsNullOrWhiteSpace(c.Name) || string.IsNullOrWhiteSpace(c.Description) || string.IsNullOrWhiteSpace(c.IconFile))
        throw new InvalidOperationException("Nom, description et iconFile sont obligatoires.");
    if (c.Effects.Count == 0 || c.Effects.Select(x => x.Id).Distinct().Count() != c.Effects.Count)
        throw new InvalidOperationException("La liste d'effets est vide ou contient des doublons.");
}

static void GenerateIntegrationNotes(Config c, string configFile)
{
    var dir = Path.Combine(Path.GetDirectoryName(configFile)!, "generated"); Directory.CreateDirectory(dir);
    var lines = new List<string> { $"// GID {c.Gid} — {c.Name}", $"public const int {Safe(c.Name)}ItemId = {c.Gid};", "", "// Effets serveur / tooltip" };
    lines.AddRange(c.Effects.Select(e => $"{e.Id} => {e.Label} | roll={e.Minimum}..{e.Maximum} | scale={e.Scale} | suffix={e.Suffix}"));
    lines.AddRange(new[] { "", $"Tooltip catalog: gid={c.Gid}, rarity={c.Rarity}", "ATTENTION : implémenter et tester séparément la mécanique gameplay spécifique." });
    File.WriteAllLines(Path.Combine(dir, $"anomaly-{c.Gid}.txt"), lines);
}
static string Safe(string value) => new(value.Normalize().Where(char.IsLetterOrDigit).ToArray());
static T Clone<T>(T source) where T : new() { var clone = new T(); foreach (var f in typeof(T).GetFields(BindingFlags.Instance | BindingFlags.Public)) f.SetValue(clone, f.GetValue(source)); return clone; }

static void AddObject(string file, int index, object value)
{
    byte[] data; using (var w = new D2OWriter(file)) data = w.SerializeObject(value);
    var src = File.ReadAllBytes(file); var table = BinaryPrimitives.ReadInt32BigEndian(src.AsSpan(3, 4));
    var len = BinaryPrimitives.ReadInt32BigEndian(src.AsSpan(table, 4)); var insert = table + 4 + len;
    var dst = new byte[src.Length + 8 + data.Length]; src.AsSpan(0, insert).CopyTo(dst);
    BinaryPrimitives.WriteInt32BigEndian(dst.AsSpan(table, 4), len + 8);
    for (var p = table + 4; p < insert; p += 8) { var o = BinaryPrimitives.ReadInt32BigEndian(dst.AsSpan(p + 4, 4)); if (o >= insert) BinaryPrimitives.WriteInt32BigEndian(dst.AsSpan(p + 4, 4), o + 8); }
    BinaryPrimitives.WriteInt32BigEndian(dst.AsSpan(insert, 4), index); BinaryPrimitives.WriteInt32BigEndian(dst.AsSpan(insert + 4, 4), src.Length + 8);
    src.AsSpan(insert).CopyTo(dst.AsSpan(insert + 8)); data.CopyTo(dst.AsSpan(src.Length + 8)); File.WriteAllBytes(file, dst);
}

static void ReplaceObject(string file, int index, object value)
{
    byte[] data; using (var w = new D2OWriter(file)) data = w.SerializeObject(value);
    var src = File.ReadAllBytes(file); var table = BinaryPrimitives.ReadInt32BigEndian(src.AsSpan(3, 4));
    var len = BinaryPrimitives.ReadInt32BigEndian(src.AsSpan(table, 4)); var dst = new byte[src.Length + data.Length]; src.CopyTo(dst, 0); var found = false;
    for (var p = table + 4; p < table + 4 + len; p += 8) if (BinaryPrimitives.ReadInt32BigEndian(dst.AsSpan(p, 4)) == index) { BinaryPrimitives.WriteInt32BigEndian(dst.AsSpan(p + 4, 4), src.Length); found = true; break; }
    if (!found) throw new InvalidOperationException($"Index {index} introuvable."); data.CopyTo(dst.AsSpan(src.Length)); File.WriteAllBytes(file, dst);
}

record State(bool ItemExists, bool IconExists, bool DropExists, List<int> EffectCollisions);
sealed class Config { public int Gid { get; set; } public int TemplateGid { get; set; } = 32762; public string Name { get; set; } = ""; public string Description { get; set; } = ""; public string Rarity { get; set; } = "Commune"; public int Level { get; set; } = 1; public string IconFile { get; set; } = ""; public int BossMonsterId { get; set; } public List<int> BossMonsterIds { get; set; } = new(); public List<long> DropMapIds { get; set; } = new(); public double DropPercent { get; set; } = 1; public List<EffectConfig> Effects { get; set; } = new(); public List<int> GetBossMonsterIds() => BossMonsterIds.Count > 0 ? BossMonsterIds.Distinct().ToList() : (BossMonsterId > 0 ? new List<int> { BossMonsterId } : new List<int>()); }
sealed class EffectConfig { public int Id { get; set; } public string Label { get; set; } = ""; public int Minimum { get; set; } public int Maximum { get; set; } public double Scale { get; set; } = 1; public string Suffix { get; set; } = ""; }
