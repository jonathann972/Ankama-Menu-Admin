using System.Reflection;
using Giny.IO.D2I;
using Giny.IO.D2O;
using Giny.IO.D2OClasses;
using Giny.IO.D2P;

const int EchoItemId = 32760;
const int RemanenceItemId = 32761;
const int RemanenceIconId = 32761;

if (args.Length < 2 || args[0] is not ("apply" or "verify"))
{
    Console.Error.WriteLine("Usage: RemanenceIntegrator <verify> <Dofus directory> | <apply> <Dofus directory> <64px icon>");
    return 2;
}

var mode = args[0];
var dofus = Path.GetFullPath(args[1]);
var common = Path.Combine(dofus, "data", "common");
var i18nDirectory = Path.Combine(dofus, "data", "i18n");
var i18nFile = Path.Combine(i18nDirectory, "i18n_fr.d2i");
var itemsFile = Path.Combine(common, "Items.d2o");
var bitmapFile = Path.Combine(dofus, "content", "gfx", "items", "bitmap0_1.d2p");

if (mode == "apply")
{
    if (args.Length != 3)
        throw new ArgumentException("Le chemin de l'icône 64 px est requis.");
    var iconFile = Path.GetFullPath(args[2]);
    if (!File.Exists(iconFile))
        throw new FileNotFoundException("Icône introuvable", iconFile);

    Backup(itemsFile);
    Backup(i18nFile);
    Backup(bitmapFile);

    var reader = new D2OReader(File.OpenRead(itemsFile));
    var template = Clone(reader.ReadObjects().Values.Cast<Item>().First(x => x.id == EchoItemId));
    reader.Close();

    D2IManager.Initialize(i18nDirectory);
    var nextTextId = D2IManager.GetAllText().Max(x => x.Key) + 1;
    template.id = RemanenceItemId;
    template.nameId = (uint)nextTextId;
    template.descriptionId = (uint)(nextTextId + 1);
    template.iconId = RemanenceIconId;
    template.changeVersion = "Anomalies-2";
    D2IManager.SetText(nextTextId, "Rémanence");
    D2IManager.SetText(nextTextId + 1, "Rareté : Épique\nÀ la fin de votre tour, Rémanence peut conserver une partie de vos PA inutilisés pour votre prochain tour.");
    D2IManager.SaveAll();

    using (var writer = new D2OWriter(itemsFile))
    {
        writer.Write(template, RemanenceItemId);
        writer.EndWriting();
    }
    using (var d2p = new D2PFile(bitmapFile))
    {
        var existing = d2p.Entries.FirstOrDefault(x => x.FullFileName == $"{RemanenceIconId}.png");
        if (existing == null) d2p.AddFile($"{RemanenceIconId}.png", File.ReadAllBytes(iconFile));
        else existing.ModifyEntry(File.ReadAllBytes(iconFile));
        d2p.Save();
    }
}

D2OManager.Initialize(common);
D2IManager.Initialize(i18nDirectory);
var item = D2OManager.GetObjects("Items.d2o").Cast<Item>().FirstOrDefault(x => x.id == RemanenceItemId);
Console.WriteLine(item == null ? "ITEM missing" : $"ITEM id={item.id} name='{D2IManager.GetText((int)item.nameId)}' type={item.typeId} icon={item.iconId} level={item.level} description='{D2IManager.GetText((int)item.descriptionId).Replace("\n", " | ")}'");
using (var d2p = new D2PFile(bitmapFile))
{
    var icon = d2p.Entries.FirstOrDefault(x => x.FullFileName == $"{RemanenceIconId}.png");
    Console.WriteLine(icon == null ? "ICON missing" : $"ICON path={icon.FullFileName} bytes={d2p.ReadFile(icon).Length}");
}
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
    var backup = path + ".before-remanence-20260923.bak";
    if (!File.Exists(backup)) File.Copy(path, backup);
}
