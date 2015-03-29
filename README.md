# ReflectionHelperOSS
ABL helper class to simplify routine tasks with .NET Reflection

The Consultingwerk.Util.ReflectionHelper allows usage of Telerik Generic methods, such as the GetService Method of the RadGridViewElement class.

Progress does currently not intend to provide this functionality as part of the ABL (http://knowledgebase.progress.com/articles/Article/000057503?popup=true)

# API Reference

The ReflectionHelper is part of the SmartComponent Library from Consultingwerk (http://www.consultingwerk.de). The API is described here:

http://help.consultingwerkcloud.com/smartcomponent_library/release/Consultingwerk.Util.ReflectionHelper.html

# Code sample:

```
DEFINE VARIABLE oRadGridView        AS RadGridView        NO-UNDO . 
DEFINE VARIABLE oRadGridViewElement AS RadGridViewElement NO-UNDO.

DEFINE VARIABLE oService AS RadGridViewDragDropService NO-UNDO . 

/* ***************************  Main Block  *************************** */

oRadGridView = NEW RadGridView () . 
oRadGridViewElement = oRadGridView:GridViewElement  . 


oService = CAST (ReflectionHelper:InvokeGenericMethod (oRadGridViewElement, 
                                                       "GetService":U,
                                                       "Telerik.WinControls.UI.RadGridViewDragDropService":U),
                 RadGridViewDragDropService) .

```

