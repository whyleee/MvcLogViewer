using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;

namespace MvcLogViewer
{
    public class MvcLogViewerAreaRegistration : AreaRegistration
    {
        public override void RegisterArea(AreaRegistrationContext context)
        {
            context.MapRoute(
                name: "MvcLogViewer_Default",
                url: "logs/{log}/{action}",
                defaults: new { controller = "Log", action = "Index", log = UrlParameter.Optional }
            );
        }

        public override string AreaName
        {
            get { return "MvcLogViewer"; }
        }
    }
}
