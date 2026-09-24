using Giny.IO.D2O;
using Giny.IO.D2OClasses;
using Giny.IO.D2P;
using System.Buffers.Binary;

const int RasboulMonsterId = 1071;
const int RemanenceItemId = 32761;
const double DropRate = 1d;

if ((args.Length != 2 && args.Length != 3) || args[0] is not ("apply" or "verify"))
{
    Console.Error.WriteLine("Usage: RemanenceDropIntegrator <verify> <Dofus directory> | <apply> <Dofus directory> [64px icon]");
    return 2;
}

var mode = args[0];
var dofus = Path.GetFullPath(args[1]);
var monstersFile = Path.Combine(dofus, "data", "common", "Monsters.d2o");
var bitmapFile = Path.Combine(dofus, "content", "gfx", "items", "bitmap0_1.d2p");

if (mode == "apply")
{
    var reader = new D2OReader(monstersFile);
    var monsters = reader.ReadObjects().Values.OfType<Monster>().ToArray();
    var rasboul = monsters.Single(x => x.id == RasboulMonsterId);
    var indexTableOffset = reader.IndexTableOffset;
    reader.Close();

    rasboul.drops.RemoveAll(x => x.objectId == RemanenceItemId);
    var nextDropId = monsters.SelectMany(x => x.drops).Select(x => x.dropId).DefaultIfEmpty().Max() + 1;
    rasboul.drops.Add(new MonsterDrop
    {
        dropId = nextDropId,
        monsterId = RasboulMonsterId,
        objectId = RemanenceItemId,
        percentDropForGrade1 = DropRate,
        percentDropForGrade2 = DropRate,
        percentDropForGrade3 = DropRate,
        percentDropForGrade4 = DropRate,
        percentDropForGrade5 = DropRate,
        count = 1,
        criteria = string.Empty,
        hasCriteria = false,
        hiddenIfInvalidCriteria = false,
        specificDropCoefficient = new List<MonsterDropCoefficient>(),
    });

    using var writer = new D2OWriter(monstersFile);
    var serializedRasboul = writer.SerializeObject(rasboul);
    var d2oBytes = File.ReadAllBytes(monstersFile);
    var replacementOffset = d2oBytes.Length;
    var indexLength = BinaryPrimitives.ReadInt32BigEndian(d2oBytes.AsSpan(indexTableOffset, 4));
    var rasboulIndexFound = false;
    for (var offset = indexTableOffset + 4; offset < indexTableOffset + 4 + indexLength; offset += 8)
    {
        if (BinaryPrimitives.ReadInt32BigEndian(d2oBytes.AsSpan(offset, 4)) != RasboulMonsterId)
            continue;

        BinaryPrimitives.WriteInt32BigEndian(d2oBytes.AsSpan(offset + 4, 4), replacementOffset);
        rasboulIndexFound = true;
        break;
    }

    if (!rasboulIndexFound)
        throw new InvalidDataException($"Monster index {RasboulMonsterId} was not found.");

    using (var stream = new FileStream(monstersFile, FileMode.Create, FileAccess.Write, FileShare.None))
    {
        stream.Write(d2oBytes);
        stream.Write(serializedRasboul);
    }

    if (args.Length == 3)
    {
        var iconFile = Path.GetFullPath(args[2]);
        using var d2p = new D2PFile(bitmapFile);
        var icon = d2p.Entries.FirstOrDefault(x => x.FullFileName == $"{RemanenceItemId}.png");
        if (icon == null)
            d2p.AddFile($"{RemanenceItemId}.png", File.ReadAllBytes(iconFile));
        else
            icon.ModifyEntry(File.ReadAllBytes(iconFile));
        d2p.Save();
    }

    Console.WriteLine("APPLY completed; run verify in a fresh process.");
    return 0;
}

var verifyReader = new D2OReader(File.OpenRead(monstersFile));
var verifiedRasboul = verifyReader.ReadObject<Monster>(RasboulMonsterId);
var drops = verifiedRasboul.drops.Where(x => x.objectId == RemanenceItemId).ToArray();
Console.WriteLine($"MONSTER id={verifiedRasboul.id} remanenceDrops={drops.Length}");
foreach (var drop in drops)
    Console.WriteLine($"DROP id={drop.dropId} item={drop.objectId} rates={drop.percentDropForGrade1}/{drop.percentDropForGrade2}/{drop.percentDropForGrade3}/{drop.percentDropForGrade4}/{drop.percentDropForGrade5} count={drop.count} criteria='{drop.criteria}'");
verifyReader.Close();
var d2pIconValid = true;
using (var d2p = new D2PFile(bitmapFile))
{
    var icon = d2p.Entries.FirstOrDefault(x => x.FullFileName == $"{RemanenceItemId}.png");
    d2pIconValid = icon != null && d2p.ReadFile(icon).Length > 0;
    Console.WriteLine(icon == null ? "ICON missing" : $"ICON path={icon.FullFileName} bytes={d2p.ReadFile(icon).Length}");
}
return d2pIconValid && drops.Length == 1 && drops.All(x =>
    x.percentDropForGrade1 == DropRate && x.percentDropForGrade2 == DropRate &&
    x.percentDropForGrade3 == DropRate && x.percentDropForGrade4 == DropRate &&
    x.percentDropForGrade5 == DropRate) ? 0 : 1;
