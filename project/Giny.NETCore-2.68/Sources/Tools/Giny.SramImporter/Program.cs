using System.Reflection;
using System.Text.Json;
using Giny.ORM;
using Giny.World.Managers.Effects;
using Giny.World.Records.Spells;
using Giny.IO.D2O;
using Giny.IO.D2I;
using D2OSpell = Giny.IO.D2OClasses.Spell;
using ClientSpellLevel = Giny.IO.D2OClasses.SpellLevel;
using ClientEffect = Giny.IO.D2OClasses.EffectInstanceDice;
using MySql.Data.MySqlClient;
using ProtoBuf;

if (args.Length != 1)
    throw new ArgumentException("Usage: Giny.SramImporter <Sram3-dofusdb-import.json>");

DatabaseManager.Instance.Initialize(Assembly.GetAssembly(typeof(SpellRecord))!, "127.0.0.1", "giny_world", "root", "");
DatabaseManager.Instance.LoadTable<SpellLevelRecord>();
DatabaseManager.Instance.LoadTable<SpellRecord>();
DatabaseManager.Instance.LoadTable<SpellVariantRecord>();
SpellRecord.Initialize();

using var document = JsonDocument.Parse(File.ReadAllText(args[0]));
var imports = document.RootElement.EnumerateArray().ToArray();
using var sql = new MySqlConnection("Server=127.0.0.1;UserId=root;Password=;Database=giny_world");
sql.Open();
using var transaction = sql.BeginTransaction();

// Validation complète avant la première écriture.
foreach (var entry in imports)
{
    var spellJson = entry.GetProperty("spell");
    short spellId = checked((short)spellJson.GetProperty("id").GetInt32());
    if (SpellRecord.GetSpellRecord(spellId) is null)
        throw new InvalidOperationException($"Sort serveur introuvable : {spellId}");

    foreach (var levelJson in entry.GetProperty("levels").EnumerateArray())
    {
        int officialId = levelJson.GetProperty("id").GetInt32();
        var existingById = SpellLevelRecord.GetSpellLevel(officialId);
        if (existingById is not null && existingById.SpellId != spellId)
            throw new InvalidOperationException($"Collision du grade officiel {officialId}");
    }
}

foreach (var entry in imports)
{
    var spellJson = entry.GetProperty("spell");
    short spellId = checked((short)spellJson.GetProperty("id").GetInt32());
    var spell = SpellRecord.GetSpellRecord(spellId);
    spell.Name = spellJson.GetProperty("name").GetProperty("fr").GetString() ?? spell.Name;
    spell.Description = spellJson.GetProperty("description").GetProperty("fr").GetString() ?? spell.Description;
    spell.Verbose = GetBool(spellJson, "verboseCast", spell.Verbose);
    foreach (var levelJson in entry.GetProperty("levels").EnumerateArray())
    {
        byte importedGrade = checked((byte)levelJson.GetProperty("grade").GetInt32());
        var level = spell.Levels.FirstOrDefault(x => x.Grade == importedGrade);
        if (level is null)
        {
            level = new SpellLevelRecord
            {
                Id = levelJson.GetProperty("id").GetInt32(),
                Effects = new EffectCollection(),
                CriticalEffects = new EffectCollection()
            };
            spell.Levels.Add(level);
        }
        level.SpellId = checked((short)levelJson.GetProperty("spellId").GetInt32());
        level.Grade = importedGrade;
        level.SpellBreed = checked((short)levelJson.GetProperty("spellBreed").GetInt32());
        level.ApCost = checked((short)levelJson.GetProperty("apCost").GetInt32());
        level.MinRange = checked((short)levelJson.GetProperty("minRange").GetInt32());
        level.MaxRange = checked((short)levelJson.GetProperty("range").GetInt32());
        level.CriticalHitProbability = levelJson.GetProperty("criticalHitProbability").GetInt64();
        level.MaxStack = levelJson.GetProperty("maxStack").GetInt32();
        level.MaxCastPerTurn = levelJson.GetProperty("maxCastPerTurn").GetInt32();
        level.MaxCastPerTarget = levelJson.GetProperty("maxCastPerTarget").GetInt32();
        level.MinCastInterval = levelJson.GetProperty("minCastInterval").GetInt32();
        level.InitialCooldown = levelJson.GetProperty("initialCooldown").GetInt32();
        level.GlobalCooldown = levelJson.GetProperty("globalCooldown").GetInt32();
        level.MinPlayerLevel = levelJson.GetProperty("minPlayerLevel").GetInt32();
        level.StatesCriterion = levelJson.GetProperty("statesCriterion").GetString() ?? "";
        level.CastInLine = GetBool(levelJson, "castInLine", false);
        level.CastInDiagonal = GetBool(levelJson, "castInDiagonal", false);
        level.CastTestLos = GetBool(levelJson, "castTestLos", true);
        level.NeedFreeCell = GetBool(levelJson, "needFreeCell", false);
        level.NeedTakenCell = GetBool(levelJson, "needTakenCell", false);
        level.NeedFreeTrapCell = GetBool(levelJson, "needFreeTrapCell", false);
        level.RangeCanBeBoosted = GetBool(levelJson, "rangeCanBeBoosted", false);
        level.HideEffects = GetBool(levelJson, "hideEffects", false);
        level.Hidden = GetBool(levelJson, "hidden", false);
        level.Effects = ReadEffects(levelJson.GetProperty("effects"));
        level.CriticalEffects = ReadEffects(levelJson.GetProperty("criticalEffect"));
        SaveLevel(sql, transaction, level);
    }

    spell.SpellLevels = spell.Levels.OrderBy(x => x.Grade).Select(x => checked((int)x.Id)).ToArray();
    SaveSpell(sql, transaction, spell);

    Console.WriteLine($"{spellId}: {spell.Name}");
}

var officialVariants = new (long Id, short Base, short Variant)[]
{
    (285,12913,12930),(286,12906,12939),(287,12902,12932),(288,12907,12933),
    (289,12914,12920),(290,12904,12935),(291,12915,12936),(292,12916,12943),
    (293,12938,12947),(294,12919,12922),(295,12948,14742),(296,12910,14314),
    (297,12931,12941),(298,12911,12937),(299,12934,12917),(300,12908,12945),
    (301,12909,12949),(302,12903,14741),(303,12921,12950),(304,14312,14313),
    (305,12942,12918),(422,12905,12940)
};
foreach (var pair in officialVariants)
{
    using var command = new MySqlCommand("UPDATE spell_variants SET BreedId=4, SpellIds=@spells WHERE Id=@id", sql, transaction);
    command.Parameters.AddWithValue("@spells", Blob(new short[] { pair.Base, pair.Variant }));
    command.Parameters.AddWithValue("@id", pair.Id);
    if (command.ExecuteNonQuery() != 1) throw new InvalidOperationException($"Variante introuvable : {pair.Id}");
}

transaction.Commit();
DatabaseManager.Instance.CloseProvider();
D2OManager.Initialize(Path.GetFullPath("2.68.0.0/Dofus/data/common"));
D2IManager.Initialize(Path.GetFullPath("2.68.0.0/Dofus/data/i18n"));
var spellLevelsPath = Path.GetFullPath("2.68.0.0/Dofus/data/common/SpellLevels.d2o");
var spellsPath = Path.GetFullPath("2.68.0.0/Dofus/data/common/Spells.d2o");
using var clientLevelsWriter = new D2OWriter(spellLevelsPath);
using var clientSpellsWriter = new D2OWriter(spellsPath);
foreach (var entry in imports)
{
    var spellJson = entry.GetProperty("spell");
    int spellId = spellJson.GetProperty("id").GetInt32();
    uint newIcon = spellJson.GetProperty("iconId").GetUInt32();
    if (!D2OManager.ObjectExists("Spells.d2o", spellId))
    {
        Console.WriteLine($"CLIENT_SKIP|{spellId}|fiche technique absente du client");
        continue;
    }
    var clientSpell = D2OManager.GetObject<D2OSpell>("Spells.d2o", spellId);
    D2IManager.SetText(checked((int)clientSpell.nameId), spellJson.GetProperty("name").GetProperty("fr").GetString() ?? "");
    D2IManager.SetText(checked((int)clientSpell.descriptionId), spellJson.GetProperty("description").GetProperty("fr").GetString() ?? "");

    var clientLevelIds = new List<uint>();
    foreach (var levelJson in entry.GetProperty("levels").EnumerateArray())
    {
        int grade = levelJson.GetProperty("grade").GetInt32();
        uint levelId = grade <= clientSpell.spellLevels.Count
            ? clientSpell.spellLevels[grade - 1]
            : levelJson.GetProperty("id").GetUInt32();
        var clientLevel = D2OManager.ObjectExists("SpellLevels.d2o", checked((int)levelId))
            ? D2OManager.GetObject<ClientSpellLevel>("SpellLevels.d2o", checked((int)levelId))
            : new ClientSpellLevel { id = levelId };
        ApplyClientLevel(clientLevel, levelJson);
        clientLevelsWriter.Write(clientLevel, checked((int)levelId));
        clientLevelIds.Add(levelId);
    }
    clientSpell.spellLevels = clientLevelIds;
    clientSpellsWriter.Write(clientSpell, spellId);
    Console.WriteLine($"ICON|{spellId}|{clientSpell.IconId}|{newIcon}");
}
D2IManager.SaveAll();
clientLevelsWriter.EndWriting();
clientSpellsWriter.EndWriting();
Console.WriteLine($"Import terminé : {imports.Length} sorts Sram.");
Console.WriteLine("Variantes officielles importées : 22");
Console.WriteLine($"Sournoiserie -> {SpellVariantRecord.GetVariant(12904)}");

static EffectCollection ReadEffects(JsonElement json)
{
    var result = new EffectCollection();
    foreach (var source in json.EnumerateArray())
    {
        var effect = new EffectDice(
            checked((short)source.GetProperty("effectId").GetInt32()),
            source.GetProperty("diceNum").GetInt32(),
            source.GetProperty("diceSide").GetInt32(),
            source.GetProperty("value").GetInt32())
        {
            Order = source.GetProperty("order").GetInt32(),
            TargetId = source.GetProperty("targetId").GetInt32(),
            TargetMask = source.GetProperty("targetMask").GetString() ?? "a,A",
            Duration = source.GetProperty("duration").GetInt32(),
            Delay = source.GetProperty("delay").GetInt32(),
            Random = source.GetProperty("random").GetDouble(),
            Group = source.GetProperty("group").GetInt32(),
            Modificator = source.GetProperty("modificator").GetInt32(),
            Trigger = GetBool(source, "trigger", false),
            RawTriggers = source.GetProperty("triggers").GetString() ?? "I",
            Dispellable = source.GetProperty("dispellable").GetInt32(),
            RawZone = ReadZone(source.GetProperty("zoneDescr"))
        };
        result.Add(effect);
    }
    return result;
}

static string ReadZone(JsonElement zone)
{
    char shape = (char)zone.GetProperty("shape").GetInt32();
    int p1 = zone.GetProperty("param1").GetInt32();
    int p2 = zone.GetProperty("param2").GetInt32();
    return p2 > 0 ? $"{shape}{p1},{p2}" : $"{shape}{p1}";
}

static bool GetBool(JsonElement json, string name, bool fallback) =>
    json.TryGetProperty(name, out var value) ? value.GetBoolean() : fallback;

static void ApplyClientLevel(ClientSpellLevel x, JsonElement j)
{
    x.spellId = j.GetProperty("spellId").GetUInt32(); x.grade = j.GetProperty("grade").GetUInt32();
    x.spellBreed = j.GetProperty("spellBreed").GetUInt32(); x.apCost = j.GetProperty("apCost").GetUInt32();
    x.minRange = j.GetProperty("minRange").GetUInt32(); x.range = j.GetProperty("range").GetUInt32();
    x.castInLine = GetBool(j,"castInLine",false); x.castInDiagonal = GetBool(j,"castInDiagonal",false);
    x.castTestLos = GetBool(j,"castTestLos",true); x.criticalHitProbability = j.GetProperty("criticalHitProbability").GetUInt32();
    x.needFreeCell = GetBool(j,"needFreeCell",false); x.needTakenCell = GetBool(j,"needTakenCell",false);
    x.needFreeTrapCell = GetBool(j,"needFreeTrapCell",false); x.rangeCanBeBoosted = GetBool(j,"rangeCanBeBoosted",false);
    x.maxStack = j.GetProperty("maxStack").GetInt32(); x.maxCastPerTurn = j.GetProperty("maxCastPerTurn").GetUInt32();
    x.maxCastPerTarget = j.GetProperty("maxCastPerTarget").GetUInt32(); x.minCastInterval = j.GetProperty("minCastInterval").GetUInt32();
    x.initialCooldown = j.GetProperty("initialCooldown").GetUInt32(); x.globalCooldown = j.GetProperty("globalCooldown").GetInt32();
    x.minPlayerLevel = j.GetProperty("minPlayerLevel").GetUInt32(); x.hideEffects = GetBool(j,"hideEffects",false);
    x.hidden = GetBool(j,"hidden",false); x.playAnimation = GetBool(j,"playAnimation",true);
    x.statesCriterion = j.GetProperty("statesCriterion").GetString() ?? "";
    x.effects = ReadClientEffects(j.GetProperty("effects"));
    x.criticalEffect = ReadClientEffects(j.GetProperty("criticalEffect"));

}

static List<ClientEffect> ReadClientEffects(JsonElement json) => json.EnumerateArray().Select(e => new ClientEffect
{
    effectUid=e.GetProperty("effectUid").GetUInt32(), baseEffectId=e.GetProperty("baseEffectId").GetUInt32(), effectId=e.GetProperty("effectId").GetUInt32(),
    order=e.GetProperty("order").GetInt32(), targetId=e.GetProperty("targetId").GetInt32(), targetMask=e.GetProperty("targetMask").GetString() ?? "a,A",
    duration=e.GetProperty("duration").GetInt32(), delay=e.GetProperty("delay").GetInt32(), random=e.GetProperty("random").GetDouble(),
    group=e.GetProperty("group").GetInt32(), modificator=e.GetProperty("modificator").GetInt32(), trigger=GetBool(e,"trigger",false),
    triggers=e.GetProperty("triggers").GetString() ?? "I", visibleInTooltip=GetBool(e,"visibleInTooltip",true), visibleInBuffUi=GetBool(e,"visibleInBuffUi",true),
    visibleInFightLog=GetBool(e,"visibleInFightLog",true), visibleOnTerrain=GetBool(e,"visibleOnTerrain",true), forClientOnly=GetBool(e,"forClientOnly",false),
    dispellable=e.GetProperty("dispellable").GetInt32(), effectElement=e.GetProperty("effectElement").GetInt32(), spellId=e.GetProperty("spellId").GetInt32(),
    rawZone=ReadZone(e.GetProperty("zoneDescr")), diceNum=e.GetProperty("diceNum").GetUInt32(), diceSide=e.GetProperty("diceSide").GetUInt32(), value=e.GetProperty("value").GetInt32()
}).ToList();

static byte[] Blob<T>(T value)
{
    using var stream = new MemoryStream();
    Serializer.Serialize(stream, value);
    return stream.ToArray();
}

static void SaveSpell(MySqlConnection sql, MySqlTransaction transaction, SpellRecord spell)
{
    using var command = new MySqlCommand("UPDATE spells SET Name=@name, Description=@description, SpellLevels=@levels, Verbose=@verbose WHERE Id=@id", sql, transaction);
    command.Parameters.AddWithValue("@name", spell.Name);
    command.Parameters.AddWithValue("@description", spell.Description);
    command.Parameters.AddWithValue("@levels", Blob(spell.SpellLevels));
    command.Parameters.AddWithValue("@verbose", spell.Verbose);
    command.Parameters.AddWithValue("@id", spell.Id);
    if (command.ExecuteNonQuery() != 1) throw new InvalidOperationException($"Échec écriture sort {spell.Id}");
}

static void SaveLevel(MySqlConnection sql, MySqlTransaction transaction, SpellLevelRecord x)
{
    const string query = @"REPLACE INTO spell_levels
(Id,SpellId,Grade,SpellBreed,ApCost,MinRange,MaxRange,CastInLine,CastInDiagonal,CastTestLos,CriticalHitProbability,NeedFreeCell,NeedTakenCell,NeedFreeTrapCell,RangeCanBeBoosted,MaxStack,MaxCastPerTurn,MaxCastPerTarget,MinCastInterval,InitialCooldown,GlobalCooldown,MinPlayerLevel,HideEffects,Hidden,StatesCriterion,Effects,CriticalEffects)
VALUES
(@Id,@SpellId,@Grade,@SpellBreed,@ApCost,@MinRange,@MaxRange,@CastInLine,@CastInDiagonal,@CastTestLos,@CriticalHitProbability,@NeedFreeCell,@NeedTakenCell,@NeedFreeTrapCell,@RangeCanBeBoosted,@MaxStack,@MaxCastPerTurn,@MaxCastPerTarget,@MinCastInterval,@InitialCooldown,@GlobalCooldown,@MinPlayerLevel,@HideEffects,@Hidden,@StatesCriterion,@Effects,@CriticalEffects)";
    using var c = new MySqlCommand(query, sql, transaction);
    c.Parameters.AddWithValue("@Id", x.Id); c.Parameters.AddWithValue("@SpellId", x.SpellId);
    c.Parameters.AddWithValue("@Grade", x.Grade); c.Parameters.AddWithValue("@SpellBreed", x.SpellBreed);
    c.Parameters.AddWithValue("@ApCost", x.ApCost); c.Parameters.AddWithValue("@MinRange", x.MinRange);
    c.Parameters.AddWithValue("@MaxRange", x.MaxRange); c.Parameters.AddWithValue("@CastInLine", x.CastInLine);
    c.Parameters.AddWithValue("@CastInDiagonal", x.CastInDiagonal); c.Parameters.AddWithValue("@CastTestLos", x.CastTestLos);
    c.Parameters.AddWithValue("@CriticalHitProbability", x.CriticalHitProbability); c.Parameters.AddWithValue("@NeedFreeCell", x.NeedFreeCell);
    c.Parameters.AddWithValue("@NeedTakenCell", x.NeedTakenCell); c.Parameters.AddWithValue("@NeedFreeTrapCell", x.NeedFreeTrapCell);
    c.Parameters.AddWithValue("@RangeCanBeBoosted", x.RangeCanBeBoosted); c.Parameters.AddWithValue("@MaxStack", x.MaxStack);
    c.Parameters.AddWithValue("@MaxCastPerTurn", x.MaxCastPerTurn); c.Parameters.AddWithValue("@MaxCastPerTarget", x.MaxCastPerTarget);
    c.Parameters.AddWithValue("@MinCastInterval", x.MinCastInterval); c.Parameters.AddWithValue("@InitialCooldown", x.InitialCooldown);
    c.Parameters.AddWithValue("@GlobalCooldown", x.GlobalCooldown); c.Parameters.AddWithValue("@MinPlayerLevel", x.MinPlayerLevel);
    c.Parameters.AddWithValue("@HideEffects", x.HideEffects); c.Parameters.AddWithValue("@Hidden", x.Hidden);
    c.Parameters.AddWithValue("@StatesCriterion", x.StatesCriterion); c.Parameters.AddWithValue("@Effects", Blob(x.Effects));
    c.Parameters.AddWithValue("@CriticalEffects", Blob(x.CriticalEffects));
    c.ExecuteNonQuery();
}
