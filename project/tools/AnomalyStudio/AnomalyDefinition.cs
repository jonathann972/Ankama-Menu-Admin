namespace AnomalyStudio;

public sealed class AnomalyDefinition
{
    public int Gid { get; set; }
    public int IconId { get; set; }
    public string Name { get; set; } = "";
    public int Level { get; set; } = 1;
    public string Rarity { get; set; } = "Commune";
    public string Category { get; set; } = "";
    public string Description { get; set; } = "";
    public short BossMonsterId { get; set; }
    public string BossName { get; set; } = "";
    public string Dungeon { get; set; } = "";
    public double DropRatePercent { get; set; } = 1.0;
    public bool IgnoreProspecting { get; set; } = true;
    public string Trigger { get; set; } = "";
    public int MaxAttemptsPerTurn { get; set; } = 1;
    public List<AnomalyEffectDefinition> Effects { get; set; } = new();
}

public sealed class AnomalyEffectDefinition
{
    public short EffectId { get; set; }
    public string Label { get; set; } = "";
    public int Minimum { get; set; }
    public int Maximum { get; set; }
    public int Scale { get; set; } = 1;
    public string Suffix { get; set; } = "";
}
