&IF 1=0 &THEN
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
    File        : products.i
    Purpose     : Contains compile time flags indicating the available
                  Consultingwerk framework products / developer toolkits  

    Syntax      : include file

    Description : 

    Author(s)   : Mike Fechner / Consultingwerk Ltd.
    Created     : Thu Feb 03 21:35:47 CET 2011
    Notes       : OERASI preprocessor controls the default path to the 
                  service interface procedures in include files. Used 
                  in the ServiceAdapter class and the proSI... procedures
                  
                  The comments in this file are excluded from the preprocessed
                  source code to avoid incluencing the class documentation 
                  tools which work on preprocessed source code
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

/* Mike Fechner, Consultingwerk Ltd. 08.08.2011
   The GUI for .NET products do require compilation on 
   MS Windows anyhow - so this seems like a good practice */
&ENDIF   
   
&IF "{&WINDOW-SYSTEM}":U BEGINS "MS-WIN":U &THEN  
&IF 1=0 &THEN 
/*&GLOBAL-DEFINE Dynamics4NET */
&ENDIF
&GLOBAL-DEFINE SmartComponentLibrary
&GLOBAL-DEFINE WinKit
&ENDIF
&GLOBAL-DEFINE SmartFramework
&GLOBAL-DEFINE OpenEdgeBPM
&GLOBAL-DEFINE WinKitDemo

&IF 1=0 &THEN
/* Compilation allowed that accesses .NET classes?
   In 10.2B it would be sufficient to test for
   "{&WINDOW-SYSTEM}". For OE11 support for .NET 
   on the AppServer Character client is announced.
   Currently we do expect that in OE11 the test 
   for "{&WINDOW-SYSTEM} would not be sufficient 
   to know if .NET assemblies are accesible. */
&ENDIF
&IF "{&WINDOW-SYSTEM}":U BEGINS "MS-WIN":U &THEN   
&GLOBAL-DEFINE DotNetAccessible 
&ENDIF
