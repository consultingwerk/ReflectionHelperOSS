/**********************************************************************************
 * The MIT License (MIT)                                                          *
 *                                                                                *
 * Copyright (c) 2015 Consultingwerk Ltd. - www.consultingwerk.de                 *
 *                                                                                *
 * Permission is hereby granted, free of charge, to any person obtaining a copy   *
 * of this software and associated documentation files (the "Software"), to deal  *
 * in the Software without restriction, including without limitation the rights   *
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      *
 * copies of the Software, and to permit persons to whom the Software is          *
 * furnished to do so, subject to the following conditions:                       *
 *                                                                                *
 * The above copyright notice and this permission notice shall be included in all *
 * copies or substantial portions of the Software.                                *
 *                                                                                *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     *
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       *
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    *
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         *
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  *
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  *
 * SOFTWARE.                                                                      *
 **********************************************************************************/   
/*------------------------------------------------------------------------
    File        : sample.p
    Purpose     : Sample for invoking Telerik's RadGridViewElements:GetService<T> 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Sat Mar 28 07:51:24 CET 2015
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

ROUTINE-LEVEL ON ERROR UNDO, THROW.

USING Telerik.WinControls.UI.* FROM ASSEMBLY.
USING Consultingwerk.Util.* FROM PROPATH.

DEFINE VARIABLE oRadGridView        AS RadGridView        NO-UNDO . 
DEFINE VARIABLE oRadGridViewElement AS RadGridViewElement NO-UNDO.

DEFINE VARIABLE oService AS RadGridViewDragDropService NO-UNDO . 

/* ***************************  Main Block  *************************** */

oRadGridView = NEW RadGridView () . 
oRadGridViewElement = oRadGridView:GridViewElement  . 


/* Call into RadGridViewElement:GetService<T>
   http://www.telerik.com/help/winforms/m_telerik_wincontrols_ui_radgridviewelement_getservice__1.html */

oService = CAST (ReflectionHelper:InvokeGenericMethod (oRadGridViewElement, 
                                                       "GetService":U,
                                                       "Telerik.WinControls.UI.RadGridViewDragDropService":U),
                 RadGridViewDragDropService) .


MESSAGE VALID-OBJECT (oService) SKIP (1)
        oService:GetType():FullName 
        
    VIEW-AS ALERT-BOX.


