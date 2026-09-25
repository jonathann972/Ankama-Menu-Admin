using System.Buffers.Binary;
using System.Reflection;
using Giny.IO.D2I;
using Giny.IO.D2O;
using Giny.IO.D2OClasses;
using Giny.IO.D2P;

const int TemplateItemId = 32761;
const int ToisonItemId = 32762;
const int AnomalyTypeId = 290;
const int RoyalGobballMonsterId = 147;

if (args.Length < 2 || args[0] is not ("audit" or "apply" or "apply-drop" or "verify"))
{
    Console.Error.WriteLine("Usage: ToisonIntegrator <audit|apply-drop|verify> <Dofus directory> | apply <Dofus directory> <Toison_64x64.png>");
    return 2;
}

var mode = args[0];
var dofus = Path.GetFullPath(args[1]);
var common = Path.Combine(dofus, "data", "common");
var i18nDirectory = Path.Combine(dofus, "data", "i18n");
var itemsFile = Path.Combine(common, "Items.d2o");
var monstersFile = Path.Combine(common, "Monsters.d2o");
var i18nFile = Path.Combine(i18nDirectory, "i18n_fr.d2i");
var bitmapFile = Path.Combine(dofus, "content", "gfx", "items", "bitmap0_1.d2p");

var initialReader = new D2OReader(itemsFile);
var occupiedBefore = initialReader.Indexes.ContainsKey(ToisonItemId);
initialReader.Close();

if (mode == "audit")
{
    Console.WriteLine($"GID {ToisonItemId}: {(occupiedBefore ? "OCCUPIED" : "FREE")}");
    D2OManager.Initialize(common);
    var royalGobball = D2OManager.GetObjects("Monsters.d2o").Cast<Monster>().First(x => x.id == RoyalGobballMonsterId);
    var allDropIds = D2OManager.GetObjects("Monsters.d2o").Cast<Monster>()
        .SelectMany(x => x.drops ?? new List<MonsterDrop>()).Select(x => x.dropId).ToArray();
    Console.WriteLine($"MONSTER id={royalGobball.id} drops={royalGobball.drops.Count} toison={royalGobball.drops.Count(x => x.objectId == ToisonItemId)} maxDropId={allDropIds.Max()}");
    return occupiedBefore ? 1 : 0;
}

if (mode == "apply")
{
    if (args.Length != 3)
        throw new ArgumentException("Le chemin de Toison_64x64.png est requis.");
    if (occupiedBefore)
        throw new InvalidOperationException($"Le GID {ToisonItemId} est déjà occupé.");

    var iconFile = Path.GetFullPath(args[2]);
    if (!File.Exists(iconFile))
        throw new FileNotFoundException("Icône Toison introuvable", iconFile);

    BackupOnce(itemsFile, itemsFile + ".before-toison-20260923.bak");
    BackupOnce(i18nFile, i18nFile + ".before-toison-20260923.bak");
    BackupOnce(bitmapFile, bitmapFile + ".before-toison-20260923.bak");

    var reader = new D2OReader(itemsFile);
    var item = Clone(reader.ReadObject<Item>(TemplateItemId));
    reader.Close();

    D2IManager.Initialize(i18nDirectory);
    var nextTextId = D2IManager.GetAllText().Max(x => x.Key) + 1;
    item.id = ToisonItemId;
    item.nameId = (uint)nextTextId;
    item.descriptionId = (uint)(nextTextId + 1);
    item.typeId = AnomalyTypeId;
    item.iconId = ToisonItemId;
    item.level = 6;
    item.changeVersion = "Anomalies-3";
    D2IManager.SetText(nextTextId, "Toison");
    D2IManager.SetText(nextTextId + 1, "Rareté : Commune\nAprès avoir subi des dégâts de mêlée, Toison peut restaurer une petite partie des points de vie perdus.");
    D2IManager.SaveAll();

    UpsertObjectOnly(itemsFile, ToisonItemId, item);
    using var d2p = new D2PFile(bitmapFile);
    if (d2p.Entries.Any(x => x.FullFileName == $"{ToisonItemId}.png"))
        throw new InvalidOperationException($"L'asset {ToisonItemId}.png existe déjà.");
    d2p.AddFile($"{ToisonItemId}.png", File.ReadAllBytes(iconFile));
    d2p.Save();
}

if (mode == "apply-drop")
{
    var reader = new D2OReader(monstersFile);
    var royalGobball = reader.ReadObject<Monster>(RoyalGobballMonsterId);
    reader.Close();
    if (royalGobball.drops.Any(x => x.objectId == ToisonItemId))
        throw new InvalidOperationException("Le drop Toison existe déjà sur le Bouftou Royal.");

    D2OManager.Initialize(common);
    var nextDropId = D2OManager.GetObjects("Monsters.d2o").Cast<Monster>()
        .SelectMany(x => x.drops ?? new List<MonsterDrop>()).Max(x => x.dropId) + 1;
    royalGobball.drops.Add(new MonsterDrop
    {
        dropId = nextDropId,
        monsterId = RoyalGobballMonsterId,
        objectId = ToisonItemId,
        percentDropForGrade1 = 1d,
        percentDropForGrade2 = 1d,
        percentDropForGrade3 = 1d,
        percentDropForGrade4 = 1d,
        percentDropForGrade5 = 1d,
        count = 1,
        criteria = string.Empty,
        hasCriteria = false,
        hiddenIfInvalidCriteria = false,
        specificDropCoefficient = new List<MonsterDropCoefficient>()
    });
    BackupOnce(monstersFile, monstersFile + ".before-toison-20260923.bak");
    ReplaceObjectOnly(monstersFile, RoyalGobballMonsterId, royalGobball);
}

D2OManager.Initialize(common);
D2IManager.Initialize(i18nDirectory);
var verified = D2OManager.GetObjects("Items.d2o").Cast<Item>().FirstOrDefault(x => x.id == ToisonItemId);
Console.WriteLine(verified == null
    ? "ITEM missing"
    : $"ITEM id={verified.id} name='{D2IManager.GetText((int)verified.nameId)}' type={verified.typeId} icon={verified.iconId} level={verified.level} description='{D2IManager.GetText((int)verified.descriptionId).Replace("\n", " | ")}'");
using (var d2p = new D2PFile(bitmapFile))
{
    var icon = d2p.Entries.FirstOrDefault(x => x.FullFileName == $"{ToisonItemId}.png");
    Console.WriteLine(icon == null ? "ICON missing" : $"ICON path={icon.FullFileName} bytes={d2p.ReadFile(icon).Length}");
}
var verifiedMonster = D2OManager.GetObjects("Monsters.d2o").Cast<Monster>().First(x => x.id == RoyalGobballMonsterId);
var verifiedDrop = verifiedMonster.drops.SingleOrDefault(x => x.objectId == ToisonItemId);
Console.WriteLine(verifiedDrop == null
    ? "DROP missing"
    : $"DROP id={verifiedDrop.dropId} monster={verifiedDrop.monsterId} object={verifiedDrop.objectId} rates={verifiedDrop.percentDropForGrade1}/{verifiedDrop.percentDropForGrade2}/{verifiedDrop.percentDropForGrade3}/{verifiedDrop.percentDropForGrade4}/{verifiedDrop.percentDropForGrade5} count={verifiedDrop.count}");
return verified is { typeId: AnomalyTypeId, iconId: ToisonItemId, level: 6 }
    && verifiedDrop is { monsterId: RoyalGobballMonsterId, objectId: ToisonItemId, count: 1 }
    && verifiedDrop.percentDropForGrade1 == 1d && verifiedDrop.percentDropForGrade5 == 1d ? 0 : 1;

static T Clone<T>(T source) where T : new()
{
    var clone = new T();
    foreach (var field in typeof(T).GetFields(BindingFlags.Instance | BindingFlags.Public))
        field.SetValue(clone, field.GetValue(source));
    return clone;
}

static void BackupOnce(string source, string backup)
{
    if (!File.Exists(backup))
        File.Copy(source, backup);
}

static void UpsertObjectOnly(string filename, int index, object value)
{
    byte[] serialized;
    using (var serializer = new D2OWriter(filename))
        serialized = serializer.SerializeObject(value);

    var original = File.ReadAllBytes(filename);
    var indexTableOffset = BinaryPrimitives.ReadInt32BigEndian(original.AsSpan(3, 4));
    var indexLength = BinaryPrimitives.ReadInt32BigEndian(original.AsSpan(indexTableOffset, 4));
    var insertionOffset = indexTableOffset + 4 + indexLength;
    var result = new byte[original.Length + 8 + serialized.Length];
    original.AsSpan(0, insertionOffset).CopyTo(result);
    BinaryPrimitives.WriteInt32BigEndian(result.AsSpan(indexTableOffset, 4), indexLength + 8);
    for (var offset = indexTableOffset + 4; offset < insertionOffset; offset += 8)
    {
        var objectOffset = BinaryPrimitives.ReadInt32BigEndian(result.AsSpan(offset + 4, 4));
        if (objectOffset >= insertionOffset)
            BinaryPrimitives.WriteInt32BigEndian(result.AsSpan(offset + 4, 4), objectOffset + 8);
    }
    BinaryPrimitives.WriteInt32BigEndian(result.AsSpan(insertionOffset, 4), index);
    BinaryPrimitives.WriteInt32BigEndian(result.AsSpan(insertionOffset + 4, 4), original.Length + 8);
    original.AsSpan(insertionOffset).CopyTo(result.AsSpan(insertionOffset + 8));
    serialized.CopyTo(result.AsSpan(original.Length + 8));
    File.WriteAllBytes(filename, result);
}

static void ReplaceObjectOnly(string filename, int index, object value)
{
    byte[] serialized;
    using (var serializer = new D2OWriter(filename))
        serialized = serializer.SerializeObject(value);

    var original = File.ReadAllBytes(filename);
    var indexTableOffset = BinaryPrimitives.ReadInt32BigEndian(original.AsSpan(3, 4));
    var indexLength = BinaryPrimitives.ReadInt32BigEndian(original.AsSpan(indexTableOffset, 4));
    var result = new byte[original.Length + serialized.Length];
    original.CopyTo(result, 0);

    var found = false;
    for (var offset = indexTableOffset + 4; offset < indexTableOffset + 4 + indexLength; offset += 8)
    {
        if (BinaryPrimitives.ReadInt32BigEndian(result.AsSpan(offset, 4)) != index)
            continue;
        BinaryPrimitives.WriteInt32BigEndian(result.AsSpan(offset + 4, 4), original.Length);
        found = true;
        break;
    }
    if (!found)
        throw new InvalidOperationException($"Index D2O {index} introuvable dans {Path.GetFileName(filename)}.");

    serialized.CopyTo(result.AsSpan(original.Length));
    File.WriteAllBytes(filename, result);
}
