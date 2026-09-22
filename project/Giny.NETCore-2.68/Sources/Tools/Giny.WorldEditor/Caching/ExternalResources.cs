using Giny.Core.Network;
using Giny.IO;
using Giny.IO.D2P;
using Giny.Core.IO.Configuration;
using Giny.WorldEditor.Config;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Diagnostics;
using System.IO;

namespace Giny.WorldEditor.Caching
{
    public class ExternalResources
    {
        static D2PFile ItemIconsFile;

        static D2PFile MonsterIconsFile;

        public static void Initialize()
        {
            var clientPath = ConfigManager<WorldViewConfig>.Instance.ClientPath;
            ItemIconsFile = new D2PFile(Path.Combine(clientPath, ClientConstants.ItemBitmap0Path));

            MonsterIconsFile = new D2PFile(Path.Combine(clientPath, ClientConstants.MonsterBitmap0Path));
        }

        public static async Task<string> GetSpellIcon(int iconId)
        {
            var local = await GetLocalSpellIcon(iconId);
            if (!string.IsNullOrEmpty(local)) return local;
            string url = string.Format("https://api.dofusdb.fr/img/spells/sort_{0}.png", iconId);
            return await GetBase64FromUrlAsync(url);

        }

        private static async Task<string> GetLocalSpellIcon(int iconId)
        {
            try
            {
                var cfg = ConfigManager<WorldViewConfig>.Instance;
                var ffdec = string.IsNullOrWhiteSpace(cfg.FfdecPath)
                    ? Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "tools", "ffdec", "ffdec-cli.exe"))
                    : cfg.FfdecPath;
                var swf = Path.Combine(cfg.ClientPath, "content", "gfx", "spells", "all.swf");
                var cache = Path.Combine(cfg.ClientPath, ".worldeditor-spell-icons");
                var icon = Directory.Exists(cache) ? Directory.GetFiles(cache, "1.png", SearchOption.AllDirectories).FirstOrDefault(x => Path.GetDirectoryName(x)!.Contains("sort_" + iconId + "_")) : null;
                if (icon == null && File.Exists(ffdec) && File.Exists(swf))
                {
                    Directory.CreateDirectory(cache);
                    var psi = new ProcessStartInfo(ffdec, $"-export sprite \"{cache}\" \"{swf}\"") { UseShellExecute = false, CreateNoWindow = true };
                    using var p = Process.Start(psi)!;
                    await p.WaitForExitAsync();
                    icon = Directory.GetFiles(cache, "1.png", SearchOption.AllDirectories).FirstOrDefault(x => Path.GetDirectoryName(x)!.Contains("sort_" + iconId + "_"));
                }
                return icon == null ? string.Empty : Convert.ToBase64String(await File.ReadAllBytesAsync(icon));
            }
            catch { return string.Empty; }
        }

        public static async Task<string> GetEntityLookIcon(string look, int size)
        {
            byte[] bytes = Encoding.Default.GetBytes(look);
            var hexString = BitConverter.ToString(bytes);
            hexString = hexString.Replace("-", "").ToLower();

            // 
            string url = string.Format("https://www.dofusbook.net/flash/{0}/full/1/{1}_{1}.png", hexString, size);
            return await GetBase64FromUrlAsync(url);
        }

        public static string GetMonsterIcon(short monsterId)
        {
            var icon = MonsterIconsFile.Entries.FirstOrDefault(x => Path.GetFileNameWithoutExtension(x.FileName) == monsterId.ToString());
            var entryData = MonsterIconsFile.ReadFile(icon);
            string base64String = Convert.ToBase64String(entryData);
            return base64String;
        }
        public static string GetItemIcon(int iconId)
        {
            var icon = ItemIconsFile.Entries.FirstOrDefault(x => Path.GetFileNameWithoutExtension(x.FileName) == iconId.ToString());
            var entryData = ItemIconsFile.ReadFile(icon);
            string base64String = Convert.ToBase64String(entryData);
            return base64String;
        }

        static async Task<string> GetBase64FromUrlAsync(string url)
        {
            using (HttpClient client = new HttpClient())
            {
                HttpResponseMessage response = await client.GetAsync(url);

                if (response.IsSuccessStatusCode)
                {
                    byte[] bytes = await response.Content.ReadAsByteArrayAsync();
                    string base64String = Convert.ToBase64String(bytes);
                    return base64String;
                }
                else
                {
                    throw new Exception($"Failed to download image. Status code: {response.StatusCode}");
                }
            }
        }

    }
}
