using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;

namespace $rootnamespace$.Areas.LogViewer
{
    public class LogViewerAreaRegistration : AreaRegistration
    {
        public override string AreaName
        {
            get { return "LogViewer"; }
        }

        public override void RegisterArea(AreaRegistrationContext context)
        {
            context.MapRoute(
                name: "LogViewer_Default",
                url: "logs/{log}/{action}",
                defaults: new { controller = "Log", action = "Index", log = UrlParameter.Optional }
            );

            context.MapRoute(
                name: "LogViewer_LogsAction",
                url: "logs/actions/{action}",
                defaults: new {controller = "Log", action = "Index", AreaName});
        }
    }
}
