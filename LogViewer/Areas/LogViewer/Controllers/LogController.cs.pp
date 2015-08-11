using System;
using System.Collections.Generic;
using System.Configuration;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Web.Hosting;
using System.Web.Mvc;
using $rootnamespace$.Areas.LogViewer.Models;

namespace $rootnamespace$.Areas.LogViewer.Controllers
{
    [Authorize]
    public class LogController : Controller
    {
        private readonly string _logDir;

        public LogController()
        {
            _logDir = ConfigurationManager.AppSettings["LogViewer.LogDir"] ?? "~/App_Data/logs/";

            if (_logDir.StartsWith("~/") || _logDir.StartsWith("/"))
            {
                _logDir = HostingEnvironment.MapPath(_logDir);
            }
        }

        public ActionResult Index(string log)
        {
            if (!string.IsNullOrEmpty(log))
            {
                return File(Path.Combine(_logDir, log), "text/plain");
            }

            var logs = Directory.GetFiles(_logDir)
                .Where(path => path.EndsWith(".log"))
                .Select(path => new FileInfo(path))
                .Select(file => new LogFileModel
                {
                    Name = file.Name,
                    Url = "/logs/" + file.Name,
                    Size = GetFriendlyFileSize(file.Length)
                })
                .ToList();

            CorrectSortOrder(logs);

            return View(logs);
        }

        public ActionResult Delete(string log)
        {
            var logPath = Path.Combine(_logDir, log);
            System.IO.File.Delete(logPath);

            return Redirect("/logs");
        }

        private string GetFriendlyFileSize(long lengthInBytes)
        {
            var kb = Math.Round(lengthInBytes / 1024d);
            var groupSeparator = NumberFormatInfo.CurrentInfo.NumberGroupSeparator;
            var friendly = kb.ToString("N0").Replace(groupSeparator, " ") + " KB";

            return friendly;
        }

        private void CorrectSortOrder(List<LogFileModel> logs)
        {
            if (logs.Any())
            {
                var latestLog = logs.First();
                logs.Remove(latestLog);
                logs.Reverse();
                logs.Insert(0, latestLog);
            }
        }
    }
}