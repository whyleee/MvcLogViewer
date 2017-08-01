using System;
using System.Collections.Generic;
using System.Configuration;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Hosting;
using System.Web.Mvc;
using $rootnamespace$.Areas.LogViewer.Models;
using Ionic.Zip;

namespace $rootnamespace$.Areas.LogViewer.Controllers
{
    [Authorize(Roles = "WebAdmins, Administrators")]
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

            var logs = GetAllLogFiles()
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
        protected List<string> GetAllLogFiles()
        {
            var result = Directory.GetFiles(_logDir).ToList();
            return result;
        }


        protected IEnumerable<string> GetAllFilesForBackup()
        {
            return GetAllFilesNotEndsWith(".bak");
        }

        protected IEnumerable<string> GetAllNonZipFiles()
        {
            return GetAllFilesNotEndsWith(".zip");
        }

        protected IEnumerable<string> GetAllFilesNotEndsWith(string extension)
        {
            var result = GetAllLogFiles().Where(x => !x.EndsWith(extension, StringComparison.InvariantCultureIgnoreCase));
            return result;
        }

        private static void TryDeleteFile(string logFile)
        {
            try
            {
                System.IO.File.Delete(logFile);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Trace.WriteLine($"Error deleting file '{logFile}': {ex}");
            }
        }

        protected RedirectResult RedirectToLogs()
        {
            return Redirect("/logs/");
        }

        public ActionResult ZipAll()
        {
            var nonZipFiles = GetAllNonZipFiles().ToList();
            if (nonZipFiles.Count == 0)
                return RedirectToLogs();


            var zipDir = Path.GetDirectoryName(_logDir) ?? _logDir;
            var now = DateTime.UtcNow;
            var zipName = $"{Request.HostName().Replace(":", "-")}.logs.{now.ToString("yyyy-MM-ddTHH.mm.ss.ms", CultureInfo.InvariantCulture)}Z.zip";
            var zipFilePath = Path.Combine(zipDir, PrepareFileName(zipName));
            var filesToDelete = new List<string>();
            using (var zip = new ZipFile())
            {
                foreach (var logFile in nonZipFiles)
                {
                    try
                    {
                        zip.AddFile(logFile, string.Empty);
                        filesToDelete.Add(logFile);
                    }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Trace.WriteLine($"Error zipping file '{logFile}': {ex}");
                    }
                }

                zip.Save(zipFilePath);
                filesToDelete.ForEach(TryDeleteFile);
            }
            return RedirectToLogs();
        }

        private string PrepareFileName(string zipName)
        {
            if (zipName == null) throw new ArgumentNullException(nameof(zipName));

            var invalidChars = new HashSet<char>(Path.GetInvalidPathChars());
            var result = new string(zipName.Select(c => invalidChars.Contains(c) ? '-' : c).ToArray());
            return result;
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

    public static class HttpContextExtensions
    {
        public static string HostName(this HttpRequestBase request)
        {
            if (request == null)
                return null;
            try
            {
                return request.Headers["host"] ?? request.Url.GetSafeAuthority();
            }
            catch (HttpException /*ex*/)
            {
                return (string)null;
            }
        }

        private static string GetSafeAuthority(this Uri uri)
        {
            if (!uri.IsAbsoluteUri)
                return (string)null;
            return uri.Authority;
        }
    }
}