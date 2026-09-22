using System.Reflection;
using Giny.IO.D2I;
using Giny.IO.D2O;
using Giny.IO.D2OClasses;
using Giny.IO.D2P;

const int EchoItemId = 32760;
const int EchoTypeId = 290;
const int EchoIconId = 32760;

if (args.Length < 2 || args[0] is not ("inspect" or "apply" or "verify" or "icon"))
{
    Console.Error.WriteLine("Usage: EchoIntegrator <inspect|verify> <Dofus directory> | <apply|icon> <Dofus directory> <128px icon>");
    return 2;
}

var mode = args[0];
var dofus = Path.GetFullPath(args[1]);
var common = Path.Combine(dofus, "data", "common");
var i18nDirectory = Path.Combine(dofus, "data", "i18n");
var i18nFile = Path.Combine(i18nDirectory, "i18n_fr.d2i");
var itemsFile = Path.Combine(common, "Items.d2o");
var itemTypesFile = Path.Combine(common, "ItemTypes.d2o");
var bitmapFile = Path.Combine(dofus, "content", "gfx", "items", "bitmap0_1.d2p");

if (mode == "icon")
{
    if (args.Length != 3)
        throw new ArgumentException("Le chemin de l'icône 128 px est requis.");
    var iconFile = Path.GetFullPath(args[2]);
    if (!File.Exists(iconFile))
        throw new FileNotFoundException("Icône introuvable", iconFile);

    BackupVisual(bitmapFile);
    int iconOffset;
    int allocatedSize;
    using (var d2p = new D2PFile(bitmapFile))
    {
        var existing = d2p.Entries.FirstOrDefault(x => x.FullFileName == $"{EchoIconId}.png")
            ?? throw new InvalidOperationException($"L'icône {EchoIconId}.png n'existe pas dans le D2P.");
        iconOffset = existing.Offset;
        allocatedSize = existing.Size;
    }
    var iconBytes = File.ReadAllBytes(iconFile);
    if (iconBytes.Length > allocatedSize)
        throw new InvalidOperationException($"La nouvelle icône ({iconBytes.Length} octets) dépasse l'espace existant ({allocatedSize} octets).");
    using (var stream = new FileStream(bitmapFile, FileMode.Open, FileAccess.Write, FileShare.None))
    {
        stream.Position = iconOffset;
        stream.Write(iconBytes);
        stream.Write(new byte[allocatedSize - iconBytes.Length]);
    }
    Console.WriteLine($"ICON UPDATED id={EchoIconId} source={iconFile}");
}

if (mode == "apply")
{
    if (args.Length != 3)
        throw new ArgumentException("Le chemin de l'icône 128 px est requis.");
    var iconFile = Path.GetFullPath(args[2]);
    if (!File.Exists(iconFile))
        throw new FileNotFoundException("Icône introuvable", iconFile);

    Backup(itemsFile);
    Backup(itemTypesFile);
    Backup(i18nFile);
    Backup(bitmapFile);

    var itemReader = new D2OReader(File.OpenRead(itemsFile));
    var templateItem = Clone(itemReader.ReadObjects().Values.Cast<Item>().First(x => x.id == 21969));
    itemReader.Close();
    var typeReader = new D2OReader(File.OpenRead(itemTypesFile));
    var templateType = Clone(typeReader.ReadObjects().Values.Cast<ItemType>().First(x => x.id == 233));
    typeReader.Close();

    D2IManager.Initialize(i18nDirectory);
    var nextTextId = D2IManager.GetAllText().Max(x => x.Key) + 1;
    var typeNameId = nextTextId;
    var itemNameId = nextTextId + 1;
    var descriptionId = nextTextId + 2;
    D2IManager.SetText(typeNameId, "Anomalie");
    D2IManager.SetText(itemNameId, "Écho");
    D2IManager.SetText(descriptionId, "Rareté : Épique\nUne résonance violette venue d'ailleurs. Le Wakfu semble se souvenir de ce que vous avez déjà fait.");
    D2IManager.SaveAll();

    templateType.id = EchoTypeId;
    templateType.nameId = (uint)typeNameId;
    templateType.superTypeId = 9;
    templateType.categoryId = 2;
    templateType.isInEncyclopedia = false;
    templateType.plural = false;
    templateType.gender = 1;
    templateType.rawZone = string.Empty;
    templateType.mimickable = false;
    templateType.craftXpRatio = 0;
    templateType.evolutiveTypeId = 0;
    using (var writer = new D2OWriter(itemTypesFile))
    {
        writer.Write(templateType, EchoTypeId);
        writer.EndWriting();
    }

    templateItem.id = EchoItemId;
    templateItem.nameId = (uint)itemNameId;
    templateItem.typeId = EchoTypeId;
    templateItem.descriptionId = (uint)descriptionId;
    templateItem.iconId = EchoIconId;
    templateItem.level = 1;
    templateItem.realWeight = 1;
    templateItem.cursed = false;
    templateItem.useAnimationId = 0;
    templateItem.usable = false;
    templateItem.targetable = false;
    templateItem.exchangeable = true;
    templateItem.price = 0;
    templateItem.twoHanded = false;
    templateItem.etheral = false;
    templateItem.itemSetId = -1;
    templateItem.criteria = string.Empty;
    templateItem.criteriaTarget = string.Empty;
    templateItem.hideEffects = false;
    templateItem.enhanceable = false;
    templateItem.nonUsableOnAnother = true;
    templateItem.appearanceId = 0;
    templateItem.isColorable = false;
    templateItem.secretRecipe = true;
    templateItem.dropMonsterIds = new();
    templateItem.dropTemporisMonsterIds = new();
    templateItem.recipeSlots = 0;
    templateItem.recipeIds = new();
    templateItem.objectIsDisplayOnWeb = false;
    templateItem.bonusIsSecret = false;
    templateItem.possibleEffects = new();
    templateItem.evolutiveEffectIds = new();
    templateItem.favoriteSubAreas = new();
    templateItem.favoriteSubAreasBonus = 0;
    templateItem.craftXpRatio = 0;
    templateItem.craftVisible = string.Empty;
    templateItem.craftConditional = string.Empty;
    templateItem.craftFeasible = string.Empty;
    templateItem.needUseConfirm = false;
    templateItem.isDestructible = false;
    templateItem.isLegendary = false;
    templateItem.isSaleable = false;
    templateItem.recyclingNuggets = 0;
    templateItem.favoriteRecyclingSubareas = new();
    templateItem.containerIds = new();
    templateItem.resourcesBySubarea = new();
    templateItem.visibility = string.Empty;
    templateItem.importantNoticeId = 0;
    templateItem.changeVersion = "Anomalies-1";
    templateItem.tooltipExpirationDate = 0;
    using (var writer = new D2OWriter(itemsFile))
    {
        writer.Write(templateItem, EchoItemId);
        writer.EndWriting();
    }

    using (var d2p = new D2PFile(bitmapFile))
    {
        var existing = d2p.Entries.FirstOrDefault(x => x.FullFileName == $"{EchoIconId}.png");
        if (existing == null)
            d2p.AddFile($"{EchoIconId}.png", File.ReadAllBytes(iconFile));
        else
            existing.ModifyEntry(File.ReadAllBytes(iconFile));
        d2p.Save();
    }
    Console.WriteLine($"APPLIED item={EchoItemId} type={EchoTypeId} icon={EchoIconId} nameText={itemNameId} typeText={typeNameId} descriptionText={descriptionId}");
}

Inspect(dofus, common, i18nDirectory);
return 0;

static T Clone<T>(T source) where T : new()
{
    var clone = new T();
    foreach (var field in typeof(T).GetFields(BindingFlags.Instance | BindingFlags.Public))
        field.SetValue(clone, field.GetValue(source));
    return clone;
}

static void Backup(string path)
{
    var backup = path + ".before-echo-20260921.bak";
    if (!File.Exists(backup))
        File.Copy(path, backup);
}

static void BackupVisual(string path)
{
    var backup = path + ".before-echo-visual-20260921.bak";
    if (!File.Exists(backup))
        File.Copy(path, backup);
}

static void Inspect(string dofus, string common, string i18nDirectory)
{
    D2OManager.Initialize(common);
    D2IManager.Initialize(i18nDirectory);
    var type = D2OManager.GetObjects("ItemTypes.d2o").Cast<ItemType>().FirstOrDefault(x => x.id == EchoTypeId);
    var item = D2OManager.GetObjects("Items.d2o").Cast<Item>().FirstOrDefault(x => x.id == EchoItemId);
    Console.WriteLine(type == null ? "TYPE missing" : $"TYPE id={type.id} name='{D2IManager.GetText((int)type.nameId)}' super={type.superTypeId} category={type.categoryId}");
    Console.WriteLine(item == null
        ? "ITEM missing"
        : $"ITEM id={item.id} name='{D2IManager.GetText((int)item.nameId)}' type={item.typeId} typeName='{(type == null ? "?" : D2IManager.GetText((int)type.nameId))}' icon={item.iconId} level={item.level} weight={item.realWeight} description='{D2IManager.GetText((int)item.descriptionId).Replace("\n", " | ")}' effects={item.possibleEffects.Count}");
    var bitmapFile = Path.Combine(dofus, "content", "gfx", "items", "bitmap0_1.d2p");
    using var d2p = new D2PFile(bitmapFile);
    var icon = d2p.Entries.FirstOrDefault(x => x.FullFileName == $"{EchoIconId}.png");
    Console.WriteLine(icon == null ? "ICON missing" : $"ICON path={icon.FullFileName} bytes={d2p.ReadFile(icon).Length}");
}
