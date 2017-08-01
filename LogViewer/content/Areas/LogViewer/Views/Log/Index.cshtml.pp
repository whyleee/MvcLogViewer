﻿@model IEnumerable<$rootnamespace$.Areas.LogViewer.Models.LogFileModel>

<link rel="stylesheet" href="~/Areas/LogViewer/Content/bootstrap.grid.css" />
<style>
    a.delete-log {
        color: firebrick;
    }
</style>
<div class="container">
    <h1>Logs</h1>
    <table class="table table-striped table-hover">
            <thead>
                <tr>
                    <th>Name</th>
                    <th>Size</th>
                    <th>
                        Delete (or @Html.ActionLink("Zip ALL", "ZipAll"))
                    </th>
                </tr>
            </thead>
        <tbody>
            @foreach (var file in Model)
            {
                <tr>
                    <td><a href="@file.Url">@file.Name</a></td>
                    <td>@file.Size</td>
					<td><a class="delete-log" href="@Url.RouteUrl("LogViewer_Default", new { log = file.Name, action = "Delete" })">X</a></td>
                </tr>
            }
        </tbody>
    </table>
</div>