// (C) Wolfgang Huber 2010-2011

// Script parameters - these are set up by R in the function 'writeReport' when copying the 
//   template for this script from arrayQualityMetrics/inst/scripts into the report.

var highlightInitial = [ true, true, true, true, true, true, true, false, false, false, false, false, false, false, false, false, false, true, true, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ];
var arrayMetadata    = [ [ "1", "AC163A", "AC163", "Control", "60", "Control60" ], [ "2", "AC164A", "AC164", "Control", "60", "Control60" ], [ "3", "AC169A", "AC169", "Control", "71", "Control71" ], [ "4", "AC170A", "AC170", "Control", "71", "Control71" ], [ "5", "AC172A", "AC172", "Control", "60", "Control60" ], [ "6", "AC174A", "AC174", "Control", "71", "Control71" ], [ "7", "AC175A", "AC175", "LtH_7", "71", "LtH_771" ], [ "8", "AC176A", "AC176", "LtH_7", "71", "LtH_771" ], [ "9", "AC177A", "AC177", "LtH_6", "60", "LtH_660" ], [ "10", "AC178A", "AC178", "LtH_7", "60", "LtH_760" ], [ "11", "AC179A", "AC179", "LtH_6", "71", "LtH_671" ], [ "12", "AC180A", "AC180", "LtH_7", "71", "LtH_771" ], [ "13", "AC181A", "AC181", "LtH_6", "60", "LtH_660" ], [ "14", "AC182A", "AC182", "LtH_6", "60", "LtH_660" ], [ "15", "AC183A", "AC183", "LtH_6", "71", "LtH_671" ], [ "16", "AC184A", "AC184", "LtH_6", "71", "LtH_671" ], [ "17", "AC186A", "AC186", "LtH_7", "60", "LtH_760" ], [ "18", "AC187A", "AC187", "Hyp_T2h", "60", "Hyp_T2h60" ], [ "19", "AC188A", "AC188", "Hyp_T2h", "60", "Hyp_T2h60" ], [ "20", "AC189A", "AC189", "Hyp_T2h", "60", "Hyp_T2h60" ], [ "21", "AC190A", "AC190", "Hyp_T6h", "60", "Hyp_T6h60" ], [ "22", "AC191A", "AC191", "Hyp_T6h", "60", "Hyp_T6h60" ], [ "23", "AC192A", "AC192", "Hyp_T6h", "60", "Hyp_T6h60" ], [ "24", "AC193A", "AC193", "Recovery", "60", "Recovery60" ], [ "25", "AC194A", "AC194", "Recovery", "60", "Recovery60" ], [ "26", "AC195A", "AC195", "Recovery", "60", "Recovery60" ], [ "27", "AC196A", "AC196", "Reox", "60", "Reox60" ], [ "28", "AC197A", "AC197", "Reox", "60", "Reox60" ], [ "29", "AC198A", "AC198", "Reox", "60", "Reox60" ], [ "30", "AC199A", "AC199", "Hyp_T2h", "71", "Hyp_T2h71" ], [ "31", "AC200A", "AC200", "Hyp_T2h", "71", "Hyp_T2h71" ], [ "32", "AC201A", "AC201", "Hyp_T2h", "71", "Hyp_T2h71" ], [ "33", "AC202A", "AC202", "Hyp_T6h", "71", "Hyp_T6h71" ], [ "34", "AC203A", "AC203", "Hyp_T6h", "71", "Hyp_T6h71" ], [ "35", "AC204A", "AC204", "Hyp_T6h", "71", "Hyp_T6h71" ], [ "36", "AC205A", "AC205", "Recovery", "71", "Recovery71" ], [ "37", "AC206A", "AC206", "Recovery", "71", "Recovery71" ], [ "38", "AC207A", "AC207", "Recovery", "71", "Recovery71" ], [ "39", "AC208A", "AC208", "Reox", "71", "Reox71" ], [ "40", "AC209A", "AC209", "Reox", "71", "Reox71" ], [ "41", "AC210A", "AC210", "Reox", "71", "Reox71" ] ];
var svgObjectNames   = [ "pca", "dens" ];

var cssText = ["stroke-width:1; stroke-opacity:0.4",
               "stroke-width:3; stroke-opacity:1" ];

// Global variables - these are set up below by 'reportinit'
var tables;             // array of all the associated ('tooltips') tables on the page
var checkboxes;         // the checkboxes
var ssrules;


function reportinit() 
{
 
    var a, i, status;

    /*--------find checkboxes and set them to start values------*/
    checkboxes = document.getElementsByName("ReportObjectCheckBoxes");
    if(checkboxes.length != highlightInitial.length)
	throw new Error("checkboxes.length=" + checkboxes.length + "  !=  "
                        + " highlightInitial.length="+ highlightInitial.length);
    
    /*--------find associated tables and cache their locations------*/
    tables = new Array(svgObjectNames.length);
    for(i=0; i<tables.length; i++) 
    {
        tables[i] = safeGetElementById("Tab:"+svgObjectNames[i]);
    }

    /*------- style sheet rules ---------*/
    var ss = document.styleSheets[0];
    ssrules = ss.cssRules ? ss.cssRules : ss.rules; 

    /*------- checkboxes[a] is (expected to be) of class HTMLInputElement ---*/
    for(a=0; a<checkboxes.length; a++)
    {
	checkboxes[a].checked = highlightInitial[a];
        status = checkboxes[a].checked; 
        setReportObj(a+1, status, false);
    }

}


function safeGetElementById(id)
{
    res = document.getElementById(id);
    if(res == null)
        throw new Error("Id '"+ id + "' not found.");
    return(res)
}

/*------------------------------------------------------------
   Highlighting of Report Objects 
 ---------------------------------------------------------------*/
function setReportObj(reportObjId, status, doTable)
{
    var i, j, plotObjIds, selector;

    if(doTable) {
	for(i=0; i<svgObjectNames.length; i++) {
	    showTipTable(i, reportObjId);
	} 
    }

    /* This works in Chrome 10, ssrules will be null; we use getElementsByClassName and loop over them */
    if(ssrules == null) {
	elements = document.getElementsByClassName("aqm" + reportObjId); 
	for(i=0; i<elements.length; i++) {
	    elements[i].style.cssText = cssText[0+status];
	}
    } else {
    /* This works in Firefox 4 */
    for(i=0; i<ssrules.length; i++) {
        if (ssrules[i].selectorText == (".aqm" + reportObjId)) {
		ssrules[i].style.cssText = cssText[0+status];
		break;
	    }
	}
    }

}

/*------------------------------------------------------------
   Display of the Metadata Table
  ------------------------------------------------------------*/
function showTipTable(tableIndex, reportObjId)
{
    var rows = tables[tableIndex].rows;
    var a = reportObjId - 1;

    if(rows.length != arrayMetadata[a].length)
	throw new Error("rows.length=" + rows.length+"  !=  arrayMetadata[array].length=" + arrayMetadata[a].length);

    for(i=0; i<rows.length; i++) 
 	rows[i].cells[1].innerHTML = arrayMetadata[a][i];
}

function hideTipTable(tableIndex)
{
    var rows = tables[tableIndex].rows;

    for(i=0; i<rows.length; i++) 
 	rows[i].cells[1].innerHTML = "";
}


/*------------------------------------------------------------
  From module 'name' (e.g. 'density'), find numeric index in the 
  'svgObjectNames' array.
  ------------------------------------------------------------*/
function getIndexFromName(name) 
{
    var i;
    for(i=0; i<svgObjectNames.length; i++)
        if(svgObjectNames[i] == name)
	    return i;

    throw new Error("Did not find '" + name + "'.");
}


/*------------------------------------------------------------
  SVG plot object callbacks
  ------------------------------------------------------------*/
function plotObjRespond(what, reportObjId, name)
{

    var a, i, status;

    switch(what) {
    case "show":
	i = getIndexFromName(name);
	showTipTable(i, reportObjId);
	break;
    case "hide":
	i = getIndexFromName(name);
	hideTipTable(i);
	break;
    case "click":
        a = reportObjId - 1;
	status = !checkboxes[a].checked;
	checkboxes[a].checked = status;
	setReportObj(reportObjId, status, true);
	break;
    default:
	throw new Error("Invalid 'what': "+what)
    }
}

/*------------------------------------------------------------
  checkboxes 'onchange' event
------------------------------------------------------------*/
function checkboxEvent(reportObjId)
{
    var a = reportObjId - 1;
    var status = checkboxes[a].checked;
    setReportObj(reportObjId, status, true);
}


/*------------------------------------------------------------
  toggle visibility
------------------------------------------------------------*/
function toggle(id){
  var head = safeGetElementById(id + "-h");
  var body = safeGetElementById(id + "-b");
  var hdtxt = head.innerHTML;
  var dsp;
  switch(body.style.display){
    case 'none':
      dsp = 'block';
      hdtxt = '-' + hdtxt.substr(1);
      break;
    case 'block':
      dsp = 'none';
      hdtxt = '+' + hdtxt.substr(1);
      break;
  }  
  body.style.display = dsp;
  head.innerHTML = hdtxt;
}
