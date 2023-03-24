class HostApplication {
    constructor(name, slug) {
        this.name = name;
        this.slug = slug;
    }
}

/**
 * Static class to retrieve host application names and their shortened name(slug).
 * Call HostApplications.GetHostAppFromString(appname) method to get name and slug.
 * @example
 *    const hostApp = HostApplications.GetHostAppFromString("Revit2022")
 *    console.log(hostApp.name) -> "Revit"
 *    console.log(hostApp.slug) -> "revit"
 */
export class HostApplications {
    static Rhino = new HostApplication("Rhino", "rhino");
    static Grasshopper = new HostApplication("Grasshopper", "grasshopper");
    static Revit = new HostApplication("Revit", "revit");
    static Dynamo = new HostApplication("Dynamo", "dynamo");
    static Unity = new HostApplication("Unity", "unity");
    static GSA = new HostApplication("GSA", "gsa");
    static Civil = new HostApplication("Civil 3D", "civil3d");
    static AutoCAD = new HostApplication("AutoCAD", "autocad");
    static MicroStation = new HostApplication("MicroStation", "microstation");
    static OpenRoads = new HostApplication("OpenRoads", "openroads");
    static OpenRail = new HostApplication("OpenRail", "openrail");
    static OpenBuildings = new HostApplication("OpenBuildings", "openbuildings");
    static ETABS = new HostApplication("ETABS", "etabs");
    static SAP2000 = new HostApplication("SAP2000", "sap2000");
    static CSIBridge = new HostApplication("CSIBridge", "csibridge");
    static SAFE = new HostApplication("SAFE", "safe");
    static TeklaStructures = new HostApplication("Tekla Structures", "teklastructures");
    static Dxf = new HostApplication("DXF Converter", "dxf");
    static Excel = new HostApplication("Excel", "excel");
    static Unreal = new HostApplication("Unreal", "unreal");
    static PowerBI = new HostApplication("Power BI", "powerbi");
    static Blender = new HostApplication("Blender", "blender");
    static QGIS = new HostApplication("QGIS", "qgis");
    static ArcGIS = new HostApplication("ArcGIS", "arcgis");
    static SketchUp = new HostApplication("SketchUp", "sketchup");
    static Archicad = new HostApplication("Archicad", "archicad");
    static TopSolid = new HostApplication("TopSolid", "topsolid");
    static Python = new HostApplication("Python", "python");
    static NET = new HostApplication(".NET", "net");
    static Navisworks = new HostApplication("Navisworks", "navisworks");
    static AdvanceSteel = new HostApplication("Advance Steel", "advancesteel");
    static Other = new HostApplication("Other", "other");

    static GetHostAppFromString(appname){
        if (!appname) return HostApplications.Other;
        appname = appname.toLowerCase().replace(/ /g, "");
        if (appname.includes("dynamo")) return HostApplications.Dynamo;
        if (appname.includes("revit")) return HostApplications.Revit;
        if (appname.includes("autocad")) return HostApplications.AutoCAD;
        if (appname.includes("civil")) return HostApplications.Civil;
        if (appname.includes("rhino")) return HostApplications.Rhino;
        if (appname.includes("grasshopper")) return HostApplications.Grasshopper;
        if (appname.includes("unity")) return HostApplications.Unity;
        if (appname.includes("gsa")) return HostApplications.GSA;
        if (appname.includes("microstation")) return HostApplications.MicroStation;
        if (appname.includes("openroads")) return HostApplications.OpenRoads;
        if (appname.includes("openrail")) return HostApplications.OpenRail;
        if (appname.includes("openbuildings")) return HostApplications.OpenBuildings;
        if (appname.includes("etabs")) return HostApplications.ETABS;
        if (appname.includes("sap")) return HostApplications.SAP2000;
        if (appname.includes("csibridge")) return HostApplications.CSIBridge;
        if (appname.includes("safe")) return HostApplications.SAFE;
        if (appname.includes("teklastructures")) return HostApplications.TeklaStructures;
        if (appname.includes("dxf")) return HostApplications.Dxf;
        if (appname.includes("excel")) return HostApplications.Excel;
        if (appname.includes("unreal")) return HostApplications.Unreal;
        if (appname.includes("powerbi")) return HostApplications.PowerBI;
        if (appname.includes("blender")) return HostApplications.Blender;
        if (appname.includes("qgis")) return HostApplications.QGIS;
        if (appname.includes("arcgis")) return HostApplications.ArcGIS;
        if (appname.includes("sketchup")) return HostApplications.SketchUp;
        if (appname.includes("archicad")) return HostApplications.Archicad;
        if (appname.includes("topsolid")) return HostApplications.TopSolid;
        if (appname.includes("python")) return HostApplications.Python;
        if (appname.includes(".net")) return HostApplications.NET;
        if (appname.includes("navisworks")) return HostApplications.Navisworks;
        if (appname.includes("advancesteel")) return HostApplications.AdvanceSteel;
        return appname;
    }
}