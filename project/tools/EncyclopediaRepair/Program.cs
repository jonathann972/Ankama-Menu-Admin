using Giny.IO.D2O;
using Giny.IO.D2OClasses;
using Giny.IO.D2I;
using Giny.IO.D2P;
using System.Reflection;

const int EchoItemId = 32760;
const int RemanenceItemId = 32761;
const int AnomalyTypeId = 290;

if ((args.Length != 2 && args.Length != 3) || args[0] is not ("apply" or "verify" or "format" or "dependencies" or "normalize-type" or "resource"))
{
    Console.Error.WriteLine("Usage: EncyclopediaRepair <apply|verify|format|dependencies|normalize-type> <Dofus directory> | resource <Dofus directory> <icon>");
    return 2;
}

var dofus = Path.GetFullPath(args[1]);
var common = Path.Combine(dofus, "data", "common");
var itemsFile = Path.Combine(common, "Items.d2o");
var typesFile = Path.Combine(common, "ItemTypes.d2o");
var nativeItems = itemsFile + ".bak.1";
var nativeTypes = Path.Combine(common, "ItemTypes.d2o.before-echo-20260921.bak");
var i18nDirectory = Path.Combine(dofus, "data", "i18n");

if (args[0] == "resource")
{
    if (args.Length != 3)
        throw new ArgumentException("The anomaly icon path is required.");
    var itemReader = new D2OReader(itemsFile);
    var echo = itemReader.ReadObject<Item>(EchoItemId);
    var remanence = itemReader.ReadObject<Item>(RemanenceItemId);
    itemReader.Close();
    var typeReader = new D2OReader(typesFile);
    var anomalyType = typeReader.Indexes.ContainsKey(AnomalyTypeId)
        ? typeReader.ReadObject<ItemType>(AnomalyTypeId)
        : typeReader.ReadObject<ItemType>((int)echo.typeId);
    typeReader.Close();
    anomalyType.categoryId = 2;
    anomalyType.isInEncyclopedia = true;
    anomalyType.id = AnomalyTypeId;
    echo.typeId = AnomalyTypeId;
    remanence.typeId = AnomalyTypeId;
    echo.isSaleable = true;
    remanence.isSaleable = true;
    D2OWriter.UpsertObjectPreservingFile(typesFile, AnomalyTypeId, anomalyType);
    D2OWriter.UpsertObjectPreservingFile(itemsFile, EchoItemId, echo);
    D2OWriter.UpsertObjectPreservingFile(itemsFile, RemanenceItemId, remanence);
    D2OWriter.AddIndexesToIntSearchValue(itemsFile, "id", EchoItemId, EchoItemId);
    D2OWriter.AddIndexesToIntSearchValue(itemsFile, "id", RemanenceItemId, RemanenceItemId);
    D2OWriter.AddIndexesToIntSearchValue(itemsFile, "typeId", AnomalyTypeId, EchoItemId, RemanenceItemId);
    D2OWriter.AddIndexesToIntSearchValue(itemsFile, "nameId", (int)echo.nameId, EchoItemId);
    D2OWriter.AddIndexesToIntSearchValue(itemsFile, "nameId", (int)remanence.nameId, RemanenceItemId);
    D2OWriter.AddIndexesToIntSearchValue(itemsFile, "level", (int)echo.level, EchoItemId, RemanenceItemId);
    D2OWriter.AddIndexesToBoolSearchValue(itemsFile, "etheral", false, EchoItemId, RemanenceItemId);
    D2OWriter.AddIndexesToBoolSearchValue(itemsFile, "isSaleable", true, EchoItemId, RemanenceItemId);
    D2OWriter.AddIndexesToIntSearchValue(typesFile, "id", AnomalyTypeId, AnomalyTypeId);
    D2OWriter.AddIndexesToIntSearchValue(typesFile, "superTypeId", (int)anomalyType.superTypeId, AnomalyTypeId);

}

if (args[0] == "normalize-type")
{
    var itemReader = new D2OReader(itemsFile);
    var echo = itemReader.ReadObject<Item>(EchoItemId);
    var remanence = itemReader.ReadObject<Item>(RemanenceItemId);
    itemReader.Close();
    var typeReader = new D2OReader(typesFile);
    var anomalyType = typeReader.ReadObject<ItemType>(AnomalyTypeId);
    typeReader.Close();
    anomalyType.id = AnomalyTypeId;
    echo.typeId = AnomalyTypeId;
    remanence.typeId = AnomalyTypeId;
    File.Copy(nativeTypes, typesFile, true);
    D2OWriter.UpsertObjectPreservingFile(typesFile, AnomalyTypeId, anomalyType);
    D2OWriter.UpsertObjectPreservingFile(itemsFile, EchoItemId, echo);
    D2OWriter.UpsertObjectPreservingFile(itemsFile, RemanenceItemId, remanence);
}

if (args[0] == "dependencies")
{
    var effectsFile = Path.Combine(common, "Effects.d2o");
    var setsFile = Path.Combine(common, "ItemSets.d2o");
    var effectsBackup = effectsFile + ".before-encyclopedia-repair-20260923.bak";
    var setsBackup = setsFile + ".before-encyclopedia-repair-20260923.bak";
    BackupOnce(effectsFile, effectsBackup);
    BackupOnce(setsFile, setsBackup);
    var effectReader = new D2OReader(effectsBackup);
    var anomalyEffects = Enumerable.Range(3100, 5)
        .Where(effectReader.Indexes.ContainsKey)
        .Select(id => effectReader.ReadObject<Effect>(id)).ToArray();
    effectReader.Close();
    File.Copy(effectsFile + ".bak.1", effectsFile, true);
    File.Copy(setsFile + ".bak.1", setsFile, true);
    foreach (var effect in anomalyEffects)
        D2OWriter.UpsertObjectPreservingFile(effectsFile, effect.id, effect);
}

if (args[0] == "apply")
{
    var brokenItemsBackup = itemsFile + ".before-encyclopedia-repair-20260923.bak";
    var brokenTypesBackup = typesFile + ".before-encyclopedia-repair-20260923.bak";
    BackupOnce(itemsFile, brokenItemsBackup);
    BackupOnce(typesFile, brokenTypesBackup);
    var itemReader = new D2OReader(brokenItemsBackup);
    var echo = itemReader.ReadObject<Item>(EchoItemId);
    var remanence = itemReader.ReadObject<Item>(RemanenceItemId);
    itemReader.Close();
    var typeReader = new D2OReader(brokenTypesBackup);
    var anomalyType = typeReader.ReadObject<ItemType>(AnomalyTypeId);
    typeReader.Close();

    File.Copy(nativeItems, itemsFile, true);
    File.Copy(nativeTypes, typesFile, true);
    D2OWriter.UpsertObjectPreservingFile(typesFile, AnomalyTypeId, anomalyType);
    D2OWriter.UpsertObjectPreservingFile(itemsFile, EchoItemId, echo);
    D2OWriter.UpsertObjectPreservingFile(itemsFile, RemanenceItemId, remanence);
}

if (args[0] is "apply" or "format")
{
    var formattedItems = new D2OReader(itemsFile);
    var echo = formattedItems.ReadObject<Item>(EchoItemId);
    var remanence = formattedItems.ReadObject<Item>(RemanenceItemId);
    formattedItems.Close();
    D2IManager.Initialize(i18nDirectory);
    D2IManager.SetText((int)echo.descriptionId, "<b><font color='#E8C34A'>Rareté :</font> <font color='#B15CFF'>Épique</font></b><br/><b><font color='#67CFFF'>Une résonance violette venue d'ailleurs. Le Wakfu semble se souvenir de ce que vous avez déjà fait.</font></b>");
    D2IManager.SetText((int)remanence.descriptionId, "<b><font color='#E8C34A'>Rareté :</font> <font color='#B15CFF'>Épique</font></b><br/><b><font color='#67CFFF'>À la fin de votre tour, Rémanence peut conserver une partie de vos PA inutilisés pour votre prochain tour.</font></b>");
    D2IManager.SaveAll();
}

var verifyItems = new D2OReader(itemsFile);
var verifiedEcho = verifyItems.ReadObject<Item>(EchoItemId);
var verifiedRemanence = verifyItems.ReadObject<Item>(RemanenceItemId);
Console.WriteLine($"ITEM echo type={verifiedEcho.typeId} level={verifiedEcho.level} saleable={verifiedEcho.isSaleable} etheral={verifiedEcho.etheral} nameId={verifiedEcho.nameId}");
Console.WriteLine($"ITEM remanence type={verifiedRemanence.typeId} level={verifiedRemanence.level} saleable={verifiedRemanence.isSaleable} etheral={verifiedRemanence.etheral} nameId={verifiedRemanence.nameId}");
foreach (var search in verifyItems.SearchEntries.OrderBy(x => x.Key))
    Console.WriteLine($"SEARCH field={search.Key} type={search.Value.FieldType} groups={search.Value.FieldCount}");
var itemSearchCount = GetSearchCount(verifyItems, "id");
var itemTypeSearchCount = GetSearchCount(verifyItems, "typeId");
var itemNameSearchCount = GetSearchCount(verifyItems, "nameId");
Console.WriteLine($"ITEMS indexes={verifyItems.IndexCount} idSearch={itemSearchCount} typeSearch={itemTypeSearchCount} nameSearch={itemNameSearchCount} echo={verifiedEcho.id} remanence={verifiedRemanence.id}");
verifyItems.Close();
var verifyTypes = new D2OReader(typesFile);
var verifiedTypeId = AnomalyTypeId;
var verifiedType = verifyTypes.ReadObject<ItemType>(verifiedTypeId);
var typeSearchCount = GetSearchCount(verifyTypes, "id");
Console.WriteLine($"TYPES indexes={verifyTypes.IndexCount} search={typeSearchCount} anomaly={verifiedType.id}");
Console.WriteLine($"TYPE category={verifiedType.categoryId} encyclopedia={verifiedType.isInEncyclopedia}");
verifyTypes.Close();
foreach (var dependency in new[] { "ItemSets.d2o", "Effects.d2o" })
{
    var dependencyReader = new D2OReader(Path.Combine(common, dependency));
    Console.WriteLine($"DEPENDENCY file={dependency} indexes={dependencyReader.IndexCount} search={GetSearchCount(dependencyReader, "id")}");
    dependencyReader.Close();
}
using (var itemIcons = new D2PFile(Path.Combine(dofus, "content", "gfx", "items", "bitmap0_1.d2p")))
{
    var icon = itemIcons.Entries.FirstOrDefault(x => x.FullFileName == $"{RemanenceItemId}.png");
    Console.WriteLine(icon == null ? "ICON missing" : $"ICON path={icon.FullFileName} bytes={itemIcons.ReadFile(icon).Length}");
}
return 0;

static void BackupOnce(string source, string backup)
{
    if (!File.Exists(backup))
        File.Copy(source, backup);
}

static int GetSearchCount(D2OReader reader, string field)
{
    var method = typeof(D2OReader).GetMethod("BuildSortIndex", BindingFlags.Instance | BindingFlags.NonPublic)
        ?? throw new MissingMethodException("D2OReader.BuildSortIndex");
    var result = method.Invoke(reader, new object[] { field }) as System.Collections.IDictionary
        ?? throw new InvalidDataException($"Search index '{field}' could not be read.");
    return result.Count;
}
