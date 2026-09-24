using System.Buffers.Binary;
using System.Reflection;
using Giny.IO.D2O;
using Giny.IO.D2OClasses;

const int AnomalyTypeId = 290;
const int PreviousClientTypeId = 233;
const int EchoItemId = 32760;
const int RemanenceItemId = 32761;

if (args.Length != 2 || args[0] is not ("apply-type" or "verify"))
{
    Console.Error.WriteLine("Usage: AnomalyTooltipRepair <apply-type|verify> <Dofus directory>");
    return 2;
}

var dofus = Path.GetFullPath(args[1]);
var common = Path.Combine(dofus, "data", "common");
var itemsFile = Path.Combine(common, "Items.d2o");
var typesFile = Path.Combine(common, "ItemTypes.d2o");

if (args[0] == "apply-type")
{
    BackupOnce(itemsFile, itemsFile + ".before-anomaly-tooltip-type290-20260923.bak");
    BackupOnce(typesFile, typesFile + ".before-anomaly-tooltip-type290-20260923.bak");

    var itemReader = new D2OReader(itemsFile);
    var echo = itemReader.ReadObject<Item>(EchoItemId);
    var remanence = itemReader.ReadObject<Item>(RemanenceItemId);
    itemReader.Close();

    var typeReader = new D2OReader(typesFile);
    var anomalyType = typeReader.Indexes.ContainsKey(AnomalyTypeId)
        ? typeReader.ReadObject<ItemType>(AnomalyTypeId)
        : Clone(typeReader.ReadObject<ItemType>(PreviousClientTypeId));
    typeReader.Close();

    anomalyType.id = AnomalyTypeId;
    echo.typeId = AnomalyTypeId;
    remanence.typeId = AnomalyTypeId;

    UpsertObjectOnly(typesFile, AnomalyTypeId, anomalyType);
    UpsertObjectOnly(itemsFile, EchoItemId, echo);
    UpsertObjectOnly(itemsFile, RemanenceItemId, remanence);
}

var verifyItems = new D2OReader(itemsFile);
var verifiedEcho = verifyItems.ReadObject<Item>(EchoItemId);
var verifiedRemanence = verifyItems.ReadObject<Item>(RemanenceItemId);
verifyItems.Close();
var verifyTypes = new D2OReader(typesFile);
var verifiedType = verifyTypes.ReadObject<ItemType>(AnomalyTypeId);
verifyTypes.Close();

Console.WriteLine($"Echo GID={verifiedEcho.id} typeId={verifiedEcho.typeId} iconId={verifiedEcho.iconId}");
Console.WriteLine($"Remanence GID={verifiedRemanence.id} typeId={verifiedRemanence.typeId} iconId={verifiedRemanence.iconId}");
Console.WriteLine($"AnomalyType id={verifiedType.id} categoryId={verifiedType.categoryId} encyclopedia={verifiedType.isInEncyclopedia}");
return 0;

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
    var entryOffset = -1;
    for (var offset = indexTableOffset + 4; offset < indexTableOffset + 4 + indexLength; offset += 8)
    {
        if (BinaryPrimitives.ReadInt32BigEndian(original.AsSpan(offset, 4)) == index)
        {
            entryOffset = offset;
            break;
        }
    }

    if (entryOffset >= 0)
    {
        BinaryPrimitives.WriteInt32BigEndian(original.AsSpan(entryOffset + 4, 4), original.Length);
        using var output = new FileStream(filename, FileMode.Create, FileAccess.Write, FileShare.None);
        output.Write(original);
        output.Write(serialized);
        return;
    }

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
