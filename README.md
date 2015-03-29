# ReflectionHelperOSS
ABL helper class to simplify routine tasks with .NET Reflection

The Consultingwerk.Util.ReflectionHelper allows usage of Telerik Generic methods, such as the GetService Method of the RadGridViewElement class.

Progress does currently not intend to provide this functionality as part of the ABL:

http://knowledgebase.progress.com/articles/Article/000057503?popup=true

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

