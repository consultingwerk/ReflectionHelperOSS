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
    File        : ReflectionHelper
    Purpose     : Provides simplified APIs for dynamic access to .NET 
                  Objects using reflection
    Syntax      : Static methods only, private constructor to disallow 
                  instance creation
    Description : 
    Author(s)   : Mike Fechner / Consultingwerk Ltd.
    Created     : Wed Sep 15 17:24:09 CEST 2010
    Notes       : See MSDN for details
    
                  This file is intended for GUI for .NET only
  ----------------------------------------------------------------------*/

ROUTINE-LEVEL ON ERROR UNDO, THROW.

{ Consultingwerk/products.i }

USING Consultingwerk.Framework.Collections.* FROM PROPATH .
USING Consultingwerk.Util.*                  FROM PROPATH . 
USING Progress.Lang.*                        FROM PROPATH .
&IF DEFINED (DotNetAccessible) NE 0 &THEN
USING System.ComponentModel.*                FROM ASSEMBLY . 
USING System.Reflection.*                    FROM ASSEMBLY . 
&ENDIF 

CLASS Consultingwerk.Util.ReflectionHelper: 

    /*------------------------------------------------------------------------------
        Purpose: Constructor for the ReflectionHelper class 
        Notes:   Disallow instance creation                                                                        
    ------------------------------------------------------------------------------*/
    CONSTRUCTOR PRIVATE ReflectionHelper ():
        SUPER ().
        
    END CONSTRUCTOR.

&IF DEFINED (DotNetAccessible) NE 0 &THEN
    /*------------------------------------------------------------------------------
        Purpose: Assigns the values of all get- and set-able properties from one object
                 to another
        Notes:   Uses .NET Reflection, so only applicible to .NET visible properties 
                 (properties of .NET objects or ABL object properties that are required 
                 for implementing a .NET Interface)
        @param poSourceObject The source object to copy the properties from 
        @param poTargetObject The target object to copy the properties to
        @param pcExceptList A comma delimited list of property names that will be skipped
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC STATIC VOID CopyInstanceProperties (poSourceObject AS System.Object,
                                                      poTargetObject AS System.Object,
                                                      pcExceptList AS CHARACTER):
        
        {Consultingwerk/foreach.i PropertyInfo oProperty in poSourceObject:GetType():GetProperties()}

            IF oProperty:CanRead AND oProperty:CanWrite AND 
               LOOKUP (oProperty:Name, pcExceptList) = 0 THEN DO ON ERROR UNDO, THROW:

                oProperty:SetValue (poTargetObject, oProperty:GetValue (poSourceObject, ?), ?) .
                
                CATCH err AS Progress.Lang.Error :
                    /*Consultingwerk.Util.ErrorHelper:ShowErrorMessage (err) .*/    
                END CATCH.                
            END.
        END. 
        
    END METHOD .

    /*------------------------------------------------------------------------------
        Purpose: Dynamically creates an instance of a .NET class using reflection                                                                         
        Notes:   http://msdn.microsoft.com/en-us/library/6ycw1y17(v=VS.90).aspx    
        @param pcType The type name to create an instance of
        @return The reference to the new object instance                                                              
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC STATIC System.Object CreateInstance (pcType AS CHARACTER):
        
        DEFINE VARIABLE oType        AS System.Type         NO-UNDO . 
        DEFINE VARIABLE oTypeArray   AS "System.Type[]":U   NO-UNDO .
        DEFINE VARIABLE oObjectArray AS "System.Object[]":U NO-UNDO .

        ASSIGN oTypeArray   = System.Type:EmptyTypes   
               oObjectArray = {Consultingwerk/new-array.i System.Object 0} .

        oType = Progress.Util.TypeHelper:GetType (pcType) .

        RETURN oType:GetConstructor (oTypeArray):Invoke (oObjectArray) . 

        FINALLY:
            DELETE OBJECT oTypeArray .
            DELETE OBJECT oObjectArray .     
        END FINALLY.

    END METHOD . 

    /*------------------------------------------------------------------------------
        Purpose: Returns the attribute of the given type from a Component class
        Notes:   The component is queries using the TypeDescriptor
        @param poType The type of the component
        @param pcPropertyName The name of the property
        @param poAttributeType The type of the attribute to return
        @return The attribute
    ------------------------------------------------------------------------------*/
	METHOD PUBLIC STATIC System.Attribute GetPropertyAttribute (poType AS System.Type,
    	                                                        pcPropertyName AS CHARACTER,
    	                                                        poAttributeType AS System.Type):
		
		DEFINE VARIABLE oProperties AS PropertyDescriptorCollection NO-UNDO . 
		DEFINE VARIABLE oProperty   AS PropertyDescriptor           NO-UNDO . 
		
		ASSIGN oProperties = TypeDescriptor:GetProperties (poType) 
		
		       oProperty   = oProperties:Find (pcPropertyName, TRUE) .
		
        {Consultingwerk/foreach.i System.Object oAttribute in oProperty:Attributes}
        
            IF VALID-OBJECT (oAttribute) AND oAttribute:GetType() = poAttributeType THEN 
                RETURN CAST (oAttribute, System.Attribute) .
        END.

	END METHOD .

    /*------------------------------------------------------------------------------
        Purpose: Dynamically Get a property value from a .NET object                                                                        
        Notes:   Uses reflection
        @param poObject The object to return a property value from
        @param pcPropertyName The name of the property to return the value from
        @return The property value                                                                        
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC STATIC System.Object GetPropertyValue (poObject AS System.Object,
                                                         pcPropertyName AS CHARACTER):
        
        DEFINE VARIABLE oType     AS System.Type                    NO-UNDO .
        DEFINE VARIABLE oProperty AS System.Reflection.PropertyInfo NO-UNDO .  
        
        ASSIGN oType     = poObject:GetType () 
               oProperty = oType:GetProperty (pcPropertyName) .

        IF VALID-OBJECT (oProperty) THEN 
            RETURN oProperty:GetValue (poObject, ?) .
        ELSE 
            RETURN ? . 

    END METHOD.

    /*------------------------------------------------------------------------------
        Purpose: Determines if the .NET object has a property with the given name 
        Notes:   
        @param poObject The object to test
        @param pcPropertyName The name of the property to test
        @return True when the property exists
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC STATIC LOGICAL HasProperty (poObject AS System.Object,
                                              pcPropertyName AS CHARACTER):
        
        DEFINE VARIABLE oType     AS System.Type                    NO-UNDO .
        DEFINE VARIABLE oProperty AS System.Reflection.PropertyInfo NO-UNDO .  
        
        ASSIGN oType     = poObject:GetType () 
               oProperty = oType:GetProperty (pcPropertyName) .

        IF VALID-OBJECT (oProperty) THEN 
            RETURN TRUE . 
         
        RETURN FALSE .
            
    END METHOD .

	/*------------------------------------------------------------------------------
	     Purpose: Invokes a public and non static .NET generic method 
	     Notes:   Currently only supports a single <T> parameter - and this parameter 
                  can not yet be used to determine overloaded method signatures
	     @param poTarget The reference of the target object instance to invoke the method on
	     @param pcMethodName The name of the generic method to invoke
	     @param pcMethodOfType The name of the .NET Type for the <T> value of the method declaration
         @return The invoked method return parameter 	     
	------------------------------------------------------------------------------*/
	METHOD PUBLIC STATIC System.Object InvokeGenericMethod (poTarget AS System.Object,
        	                                                pcMethodName AS CHARACTER,
        	                                                pcMethodOfType AS CHARACTER):
		
        RETURN ReflectionHelper:InvokeGenericMethod (poTarget,
                                                     pcMethodName, 
                                                     pcMethodOfType,
                                                     0,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?, 
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?) .

	END METHOD.

    /*------------------------------------------------------------------------------
         Purpose: Invokes a public and non static .NET generic method 
         Notes:   Currently only supports a single <T> parameter - and this parameter 
                  can not yet be used to determine overloaded method signatures
         @param poTarget The reference of the target object instance to invoke the method on
         @param pcMethodName The name of the generic method to invoke
         @param pcMethodOfType The name of the .NET Type for the <T> value of the method declaration
         @param poParameter1 The first method parameter 
         @param pcParameterType1 The type of the first method parameter (as defined in the method)
         @return The invoked method return parameter          
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC STATIC System.Object InvokeGenericMethod (poTarget AS System.Object,
                                                            pcMethodName AS CHARACTER,
                                                            pcMethodOfType AS CHARACTER,
                                                            poParameter1 AS System.Object,
                                                            pcParameterType1 AS CHARACTER):

        RETURN ReflectionHelper:InvokeGenericMethod (poTarget,
                                                     pcMethodName, 
                                                     pcMethodOfType,
                                                     1,
                                                     poParameter1,
                                                     pcParameterType1,
                                                     ?,
                                                     ?, 
                                                     ?, 
                                                     ?, 
                                                     ?, 
                                                     ?, 
                                                     ?, 
                                                     ?, 
                                                     ?, 
                                                     ?, 
                                                     ?, 
                                                     ?, 
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?) .

    END METHOD.

    /*------------------------------------------------------------------------------
         Purpose: Invokes a public and non static .NET generic method 
         Notes:   Currently only supports a single <T> parameter - and this parameter 
                  can not yet be used to determine overloaded method signatures
         @param poTarget The reference of the target object instance to invoke the method on
         @param pcMethodName The name of the generic method to invoke
         @param pcMethodOfType The name of the .NET Type for the <T> value of the method declaration
         @param poParameter1 The first method parameter 
         @param pcParameterType1 The type of the first method parameter (as defined in the method)
         @param poParameter2 The second method parameter 
         @param pcParameterType2 The type of the second method parameter (as defined in the method)
         @return The invoked method return parameter          
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC STATIC System.Object InvokeGenericMethod (poTarget AS System.Object,
                                                            pcMethodName AS CHARACTER,
                                                            pcMethodOfType AS CHARACTER,
                                                            poParameter1 AS System.Object,
                                                            pcParameterType1 AS CHARACTER, 
                                                            poParameter2 AS System.Object,
                                                            pcParameterType2 AS CHARACTER):

        RETURN ReflectionHelper:InvokeGenericMethod (poTarget,
                                                     pcMethodName, 
                                                     pcMethodOfType,
                                                     2,
                                                     poParameter1,
                                                     pcParameterType1,
                                                     poParameter2,
                                                     pcParameterType2,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?, 
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?) .

    END METHOD.

    /*------------------------------------------------------------------------------
         Purpose: Invokes a public and non static .NET generic method 
         Notes:   Currently only supports a single <T> parameter - and this parameter 
                  can not yet be used to determine overloaded method signatures
         @param poTarget The reference of the target object instance to invoke the method on
         @param pcMethodName The name of the generic method to invoke
         @param pcMethodOfType The name of the .NET Type for the <T> value of the method declaration
         @param poParameter1 The first method parameter 
         @param pcParameterType1 The type of the first method parameter (as defined in the method)
         @param poParameter2 The second method parameter 
         @param pcParameterType2 The type of the second method parameter (as defined in the method)
         @param poParameter3 The third method parameter 
         @param pcParameterType3 The type of the third method parameter (as defined in the method)
         @return The invoked method return parameter          
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC STATIC System.Object InvokeGenericMethod (poTarget AS System.Object,
                                                            pcMethodName AS CHARACTER,
                                                            pcMethodOfType AS CHARACTER,
                                                            poParameter1 AS System.Object,
                                                            pcParameterType1 AS CHARACTER, 
                                                            poParameter2 AS System.Object,
                                                            pcParameterType2 AS CHARACTER, 
                                                            poParameter3 AS System.Object,
                                                            pcParameterType3 AS CHARACTER):

        RETURN ReflectionHelper:InvokeGenericMethod (poTarget,
                                                     pcMethodName, 
                                                     pcMethodOfType,
                                                     3,
                                                     poParameter1,
                                                     pcParameterType1,
                                                     poParameter2,
                                                     pcParameterType2,
                                                     poParameter3,
                                                     pcParameterType3,
                                                     ?, 
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?) .

    END METHOD.

    /*------------------------------------------------------------------------------
         Purpose: Invokes a public and non static .NET generic method 
         Notes:   Currently only supports a single <T> parameter - and this parameter 
                  can not yet be used to determine overloaded method signatures
         @param poTarget The reference of the target object instance to invoke the method on
         @param pcMethodName The name of the generic method to invoke
         @param pcMethodOfType The name of the .NET Type for the <T> value of the method declaration
         @param poParameter1 The first method parameter 
         @param pcParameterType1 The type of the first method parameter (as defined in the method)
         @param poParameter2 The second method parameter 
         @param pcParameterType2 The type of the second method parameter (as defined in the method)
         @param poParameter3 The third method parameter 
         @param pcParameterType3 The type of the third method parameter (as defined in the method)
         @param poParameter4 The fourth method parameter 
         @param pcParameterType4 The type of the fourth method parameter (as defined in the method)
         @return The invoked method return parameter          
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC STATIC System.Object InvokeGenericMethod (poTarget AS System.Object,
                                                            pcMethodName AS CHARACTER,
                                                            pcMethodOfType AS CHARACTER,
                                                            poParameter1 AS System.Object,
                                                            pcParameterType1 AS CHARACTER, 
                                                            poParameter2 AS System.Object,
                                                            pcParameterType2 AS CHARACTER,
                                                            poParameter3 AS System.Object,
                                                            pcParameterType3 AS CHARACTER, 
                                                            poParameter4 AS System.Object,
                                                            pcParameterType4 AS CHARACTER):

        RETURN ReflectionHelper:InvokeGenericMethod (poTarget,
                                                     pcMethodName, 
                                                     pcMethodOfType,
                                                     4,
                                                     poParameter1,
                                                     pcParameterType1,
                                                     poParameter2,
                                                     pcParameterType2,
                                                     poParameter3,
                                                     pcParameterType3,
                                                     poParameter4, 
                                                     pcParameterType4,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?) .

    END METHOD.

    /*------------------------------------------------------------------------------
         Purpose: Invokes a public and non static .NET generic method 
         Notes:   Currently only supports a single <T> parameter - and this parameter 
                  can not yet be used to determine overloaded method signatures
         @param poTarget The reference of the target object instance to invoke the method on
         @param pcMethodName The name of the generic method to invoke
         @param pcMethodOfType The name of the .NET Type for the <T> value of the method declaration
         @param poParameter1 The first method parameter 
         @param pcParameterType1 The type of the first method parameter (as defined in the method)
         @param poParameter2 The second method parameter 
         @param pcParameterType2 The type of the second method parameter (as defined in the method)
         @param poParameter3 The third method parameter 
         @param pcParameterType3 The type of the third method parameter (as defined in the method)
         @param poParameter4 The fourth method parameter 
         @param pcParameterType4 The type of the fourth method parameter (as defined in the method)
         @param poParameter5 The fifth method parameter 
         @param pcParameterType5 The type of the fifth method parameter (as defined in the method)
         @return The invoked method return parameter          
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC STATIC System.Object InvokeGenericMethod (poTarget AS System.Object,
                                                            pcMethodName AS CHARACTER,
                                                            pcMethodOfType AS CHARACTER,
                                                            poParameter1 AS System.Object,
                                                            pcParameterType1 AS CHARACTER, 
                                                            poParameter2 AS System.Object,
                                                            pcParameterType2 AS CHARACTER,
                                                            poParameter3 AS System.Object,
                                                            pcParameterType3 AS CHARACTER, 
                                                            poParameter4 AS System.Object,
                                                            pcParameterType4 AS CHARACTER, 
                                                            poParameter5 AS System.Object,
                                                            pcParameterType5 AS CHARACTER):

        RETURN ReflectionHelper:InvokeGenericMethod (poTarget,
                                                     pcMethodName, 
                                                     pcMethodOfType,
                                                     5,
                                                     poParameter1,
                                                     pcParameterType1,
                                                     poParameter2,
                                                     pcParameterType2,
                                                     poParameter3,
                                                     pcParameterType3,
                                                     poParameter4, 
                                                     pcParameterType4,
                                                     poParameter5,
                                                     pcParameterType5,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?) .

    END METHOD.

    /*------------------------------------------------------------------------------
         Purpose: Invokes a public and non static .NET generic method 
         Notes:   Currently only supports a single <T> parameter - and this parameter 
                  can not yet be used to determine overloaded method signatures
         @param poTarget The reference of the target object instance to invoke the method on
         @param pcMethodName The name of the generic method to invoke
         @param pcMethodOfType The name of the .NET Type for the <T> value of the method declaration
         @param poParameter1 The first method parameter 
         @param pcParameterType1 The type of the first method parameter (as defined in the method)
         @param poParameter2 The second method parameter 
         @param pcParameterType2 The type of the second method parameter (as defined in the method)
         @param poParameter3 The third method parameter 
         @param pcParameterType3 The type of the third method parameter (as defined in the method)
         @param poParameter4 The fourth method parameter 
         @param pcParameterType4 The type of the fourth method parameter (as defined in the method)
         @param poParameter5 The fifth method parameter 
         @param pcParameterType5 The type of the fifth method parameter (as defined in the method)
         @param poParameter6 The sixth method parameter 
         @param pcParameterType6 The type of the sixth method parameter (as defined in the method)
         @return The invoked method return parameter          
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC STATIC System.Object InvokeGenericMethod (poTarget AS System.Object,
                                                            pcMethodName AS CHARACTER,
                                                            pcMethodOfType AS CHARACTER,
                                                            poParameter1 AS System.Object,
                                                            pcParameterType1 AS CHARACTER, 
                                                            poParameter2 AS System.Object,
                                                            pcParameterType2 AS CHARACTER,
                                                            poParameter3 AS System.Object,
                                                            pcParameterType3 AS CHARACTER, 
                                                            poParameter4 AS System.Object,
                                                            pcParameterType4 AS CHARACTER,
                                                            poParameter5 AS System.Object,
                                                            pcParameterType5 AS CHARACTER,
                                                            poParameter6 AS System.Object,
                                                            pcParameterType6 AS CHARACTER):

        RETURN ReflectionHelper:InvokeGenericMethod (poTarget,
                                                     pcMethodName, 
                                                     pcMethodOfType,
                                                     6,
                                                     poParameter1,
                                                     pcParameterType1,
                                                     poParameter2,
                                                     pcParameterType2,
                                                     poParameter3,
                                                     pcParameterType3,
                                                     poParameter4, 
                                                     pcParameterType4,
                                                     poParameter5,
                                                     pcParameterType5,
                                                     poParameter6,
                                                     pcParameterType6,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?) .

    END METHOD.

    /*------------------------------------------------------------------------------
         Purpose: Invokes a public and non static .NET generic method 
         Notes:   Currently only supports a single <T> parameter - and this parameter 
                  can not yet be used to determine overloaded method signatures
         @param poTarget The reference of the target object instance to invoke the method on
         @param pcMethodName The name of the generic method to invoke
         @param pcMethodOfType The name of the .NET Type for the <T> value of the method declaration
         @param poParameter1 The first method parameter 
         @param pcParameterType1 The type of the first method parameter (as defined in the method)
         @param poParameter2 The second method parameter 
         @param pcParameterType2 The type of the second method parameter (as defined in the method)
         @param poParameter3 The third method parameter 
         @param pcParameterType3 The type of the third method parameter (as defined in the method)
         @param poParameter4 The fourth method parameter 
         @param pcParameterType4 The type of the fourth method parameter (as defined in the method)
         @param poParameter5 The fifth method parameter 
         @param pcParameterType5 The type of the fifth method parameter (as defined in the method)
         @param poParameter6 The sixth method parameter 
         @param pcParameterType6 The type of the sixth method parameter (as defined in the method)
         @param poParameter7 The seventh method parameter 
         @param pcParameterType7 The type of the seventh method parameter (as defined in the method)
         @return The invoked method return parameter          
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC STATIC System.Object InvokeGenericMethod (poTarget AS System.Object,
                                                            pcMethodName AS CHARACTER,
                                                            pcMethodOfType AS CHARACTER,
                                                            poParameter1 AS System.Object,
                                                            pcParameterType1 AS CHARACTER, 
                                                            poParameter2 AS System.Object,
                                                            pcParameterType2 AS CHARACTER,
                                                            poParameter3 AS System.Object,
                                                            pcParameterType3 AS CHARACTER,
                                                            poParameter4 AS System.Object,
                                                            pcParameterType4 AS CHARACTER,
                                                            poParameter5 AS System.Object,
                                                            pcParameterType5 AS CHARACTER,
                                                            poParameter6 AS System.Object,
                                                            pcParameterType6 AS CHARACTER,
                                                            poParameter7 AS System.Object,
                                                            pcParameterType7 AS CHARACTER):

        RETURN ReflectionHelper:InvokeGenericMethod (poTarget,
                                                     pcMethodName, 
                                                     pcMethodOfType,
                                                     7,
                                                     poParameter1,
                                                     pcParameterType1,
                                                     poParameter2,
                                                     pcParameterType2,
                                                     poParameter3,
                                                     pcParameterType3,
                                                     poParameter4, 
                                                     pcParameterType4,
                                                     poParameter5,
                                                     pcParameterType5,
                                                     poParameter6,
                                                     pcParameterType6,
                                                     poParameter7,
                                                     pcParameterType7,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?) .

    END METHOD.

    /*------------------------------------------------------------------------------
         Purpose: Invokes a public and non static .NET generic method 
         Notes:   Currently only supports a single <T> parameter - and this parameter 
                  can not yet be used to determine overloaded method signatures
         @param poTarget The reference of the target object instance to invoke the method on
         @param pcMethodName The name of the generic method to invoke
         @param pcMethodOfType The name of the .NET Type for the <T> value of the method declaration
         @param poParameter1 The first method parameter 
         @param pcParameterType1 The type of the first method parameter (as defined in the method)
         @param poParameter2 The second method parameter 
         @param pcParameterType2 The type of the second method parameter (as defined in the method)
         @param poParameter3 The third method parameter 
         @param pcParameterType3 The type of the third method parameter (as defined in the method)
         @param poParameter4 The fourth method parameter 
         @param pcParameterType4 The type of the fourth method parameter (as defined in the method)
         @param poParameter5 The fifth method parameter 
         @param pcParameterType5 The type of the fifth method parameter (as defined in the method)
         @param poParameter6 The sixth method parameter 
         @param pcParameterType6 The type of the sixth method parameter (as defined in the method)
         @param poParameter7 The seventh method parameter 
         @param pcParameterType7 The type of the seventh method parameter (as defined in the method)
         @param poParameter8 The eight method parameter 
         @param pcParameterType8 The type of the eigth method parameter (as defined in the method)
         @return The invoked method return parameter          
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC STATIC System.Object InvokeGenericMethod (poTarget AS System.Object,
                                                            pcMethodName AS CHARACTER,
                                                            pcMethodOfType AS CHARACTER,
                                                            poParameter1 AS System.Object,
                                                            pcParameterType1 AS CHARACTER, 
                                                            poParameter2 AS System.Object,
                                                            pcParameterType2 AS CHARACTER, 
                                                            poParameter3 AS System.Object,
                                                            pcParameterType3 AS CHARACTER,
                                                            poParameter4 AS System.Object,
                                                            pcParameterType4 AS CHARACTER, 
                                                            poParameter5 AS System.Object,
                                                            pcParameterType5 AS CHARACTER, 
                                                            poParameter6 AS System.Object,
                                                            pcParameterType6 AS CHARACTER,
                                                            poParameter7 AS System.Object,
                                                            pcParameterType7 AS CHARACTER,
                                                            poParameter8 AS System.Object,
                                                            pcParameterType8 AS CHARACTER):

        RETURN ReflectionHelper:InvokeGenericMethod (poTarget,
                                                     pcMethodName, 
                                                     pcMethodOfType,
                                                     8,
                                                     poParameter1,
                                                     pcParameterType1,
                                                     poParameter2,
                                                     pcParameterType2,
                                                     poParameter3,
                                                     pcParameterType3,
                                                     poParameter4, 
                                                     pcParameterType4,
                                                     poParameter5,
                                                     pcParameterType5,
                                                     poParameter6,
                                                     pcParameterType6,
                                                     poParameter7,
                                                     pcParameterType7,
                                                     poParameter8,
                                                     pcParameterType8,
                                                     ?,
                                                     ?,
                                                     ?,
                                                     ?) .

    END METHOD.

    /*------------------------------------------------------------------------------
         Purpose: Invokes a public and non static .NET generic method 
         Notes:   Currently only supports a single <T> parameter - and this parameter 
                  can not yet be used to determine overloaded method signatures
         @param poTarget The reference of the target object instance to invoke the method on
         @param pcMethodName The name of the generic method to invoke
         @param pcMethodOfType The name of the .NET Type for the <T> value of the method declaration
         @param poParameter1 The first method parameter 
         @param pcParameterType1 The type of the first method parameter (as defined in the method)
         @param poParameter2 The second method parameter 
         @param pcParameterType2 The type of the second method parameter (as defined in the method)
         @param poParameter3 The third method parameter 
         @param pcParameterType3 The type of the third method parameter (as defined in the method)
         @param poParameter4 The fourth method parameter 
         @param pcParameterType4 The type of the fourth method parameter (as defined in the method)
         @param poParameter5 The fifth method parameter 
         @param pcParameterType5 The type of the fifth method parameter (as defined in the method)
         @param poParameter6 The sixth method parameter 
         @param pcParameterType6 The type of the sixth method parameter (as defined in the method)
         @param poParameter7 The seventh method parameter 
         @param pcParameterType7 The type of the seventh method parameter (as defined in the method)
         @param poParameter8 The eight method parameter 
         @param pcParameterType8 The type of the eigth method parameter (as defined in the method)
         @param poParameter9 The nineth method parameter 
         @param pcParameterType9 The type of the nineth method parameter (as defined in the method)
         @return The invoked method return parameter          
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC STATIC System.Object InvokeGenericMethod (poTarget AS System.Object,
                                                            pcMethodName AS CHARACTER,
                                                            pcMethodOfType AS CHARACTER,
                                                            poParameter1 AS System.Object,
                                                            pcParameterType1 AS CHARACTER,
                                                            poParameter2 AS System.Object,
                                                            pcParameterType2 AS CHARACTER,
                                                            poParameter3 AS System.Object,
                                                            pcParameterType3 AS CHARACTER,
                                                            poParameter4 AS System.Object,
                                                            pcParameterType4 AS CHARACTER,
                                                            poParameter5 AS System.Object,
                                                            pcParameterType5 AS CHARACTER,
                                                            poParameter6 AS System.Object,
                                                            pcParameterType6 AS CHARACTER, 
                                                            poParameter7 AS System.Object,
                                                            pcParameterType7 AS CHARACTER,
                                                            poParameter8 AS System.Object,
                                                            pcParameterType8 AS CHARACTER,
                                                            poParameter9 AS System.Object,
                                                            pcParameterType9 AS CHARACTER):

        RETURN ReflectionHelper:InvokeGenericMethod (poTarget,
                                                     pcMethodName, 
                                                     pcMethodOfType,
                                                     9,
                                                     poParameter1,
                                                     pcParameterType1,
                                                     poParameter2,
                                                     pcParameterType2,
                                                     poParameter3,
                                                     pcParameterType3,
                                                     poParameter4, 
                                                     pcParameterType4,
                                                     poParameter5,
                                                     pcParameterType5,
                                                     poParameter6,
                                                     pcParameterType6,
                                                     poParameter7,
                                                     pcParameterType7,
                                                     poParameter8,
                                                     pcParameterType8,
                                                     poParameter9,
                                                     pcParameterType9,
                                                     ?,
                                                     ?) .

    END METHOD.

    /*------------------------------------------------------------------------------
         Purpose: Invokes a public and non static .NET generic method 
         Notes:   Currently only supports a single <T> parameter - and this parameter 
                  can not yet be used to determine overloaded method signatures
         @param poTarget The reference of the target object instance to invoke the method on
         @param pcMethodName The name of the generic method to invoke
         @param pcMethodOfType The name of the .NET Type for the <T> value of the method declaration
         @param poParameter1 The first method parameter 
         @param pcParameterType1 The type of the first method parameter (as defined in the method)
         @param poParameter2 The second method parameter 
         @param pcParameterType2 The type of the second method parameter (as defined in the method)
         @param poParameter3 The third method parameter 
         @param pcParameterType3 The type of the third method parameter (as defined in the method)
         @param poParameter4 The fourth method parameter 
         @param pcParameterType4 The type of the fourth method parameter (as defined in the method)
         @param poParameter5 The fifth method parameter 
         @param pcParameterType5 The type of the fifth method parameter (as defined in the method)
         @param poParameter6 The sixth method parameter 
         @param pcParameterType6 The type of the sixth method parameter (as defined in the method)
         @param poParameter7 The seventh method parameter 
         @param pcParameterType7 The type of the seventh method parameter (as defined in the method)
         @param poParameter8 The eight method parameter 
         @param pcParameterType8 The type of the eigth method parameter (as defined in the method)
         @param poParameter9 The nineth method parameter 
         @param pcParameterType9 The type of the nineth method parameter (as defined in the method)
         @param poParameter10 The tenth method parameter 
         @param pcParameterType10 The type of the tenth method parameter (as defined in the method)
         @return The invoked method return parameter          
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC STATIC System.Object InvokeGenericMethod (poTarget AS System.Object,
                                                            pcMethodName AS CHARACTER,
                                                            pcMethodOfType AS CHARACTER,
                                                            poParameter1 AS System.Object,    
                                                            pcParameterType1 AS CHARACTER,    
                                                            poParameter2 AS System.Object,    
                                                            pcParameterType2 AS CHARACTER,    
                                                            poParameter3 AS System.Object,    
                                                            pcParameterType3 AS CHARACTER,    
                                                            poParameter4 AS System.Object,    
                                                            pcParameterType4 AS CHARACTER,    
                                                            poParameter5 AS System.Object,    
                                                            pcParameterType5 AS CHARACTER,    
                                                            poParameter6 AS System.Object,   
                                                            pcParameterType6 AS CHARACTER,   
                                                            poParameter7 AS System.Object,   
                                                            pcParameterType7 AS CHARACTER,   
                                                            poParameter8 AS System.Object,   
                                                            pcParameterType8 AS CHARACTER,   
                                                            poParameter9 AS System.Object,   
                                                            pcParameterType9 AS CHARACTER,   
                                                            poParameter10 AS System.Object,  
                                                            pcParameterType10 AS CHARACTER): 

        RETURN ReflectionHelper:InvokeGenericMethod (poTarget,
                                                     pcMethodName, 
                                                     pcMethodOfType,
                                                     10,
                                                     poParameter1,
                                                     pcParameterType1,
                                                     poParameter2,
                                                     pcParameterType2,
                                                     poParameter3,
                                                     pcParameterType3,
                                                     poParameter4, 
                                                     pcParameterType4,
                                                     poParameter5,
                                                     pcParameterType5,
                                                     poParameter6,
                                                     pcParameterType6,
                                                     poParameter7,
                                                     pcParameterType7,
                                                     poParameter8,
                                                     pcParameterType8,
                                                     poParameter9,
                                                     pcParameterType9,
                                                     poParameter10,
                                                     pcParameterType10) .

    END METHOD.

    /*------------------------------------------------------------------------------
         Purpose: Invokes a public and non static .NET generic method 
         Notes:   Currently only supports a single <T> parameter - and this parameter 
                  can not yet be used to determine overloaded method signatures
         @param poTarget The reference of the target object instance to invoke the method on
         @param pcMethodName The name of the generic method to invoke
         @param pcMethodOfType The name of the .NET Type for the <T> value of the method declaration
         @param piNumParameters The number of parameters passed to the method call
         @param poParameter1 The first method parameter 
         @param pcParameterType1 The type of the first method parameter (as defined in the method)
         @param poParameter2 The second method parameter 
         @param pcParameterType2 The type of the second method parameter (as defined in the method)
         @param poParameter3 The third method parameter 
         @param pcParameterType3 The type of the third method parameter (as defined in the method)
         @param poParameter4 The fourth method parameter 
         @param pcParameterType4 The type of the fourth method parameter (as defined in the method)
         @param poParameter5 The fifth method parameter 
         @param pcParameterType5 The type of the fifth method parameter (as defined in the method)
         @param poParameter6 The sixth method parameter 
         @param pcParameterType6 The type of the sixth method parameter (as defined in the method)
         @param poParameter7 The seventh method parameter 
         @param pcParameterType7 The type of the seventh method parameter (as defined in the method)
         @param poParameter8 The eight method parameter 
         @param pcParameterType8 The type of the eigth method parameter (as defined in the method)
         @param poParameter9 The nineth method parameter 
         @param pcParameterType9 The type of the nineth method parameter (as defined in the method)
         @param poParameter10 The tenth method parameter 
         @param pcParameterType10 The type of the tenth method parameter (as defined in the method)
         @return The invoked method return parameter 
    ------------------------------------------------------------------------------*/
    METHOD PROTECTED STATIC System.Object InvokeGenericMethod (poTarget AS System.Object,
                                                               pcMethodName AS CHARACTER,
                                                               pcMethodOfType AS CHARACTER,
                                                               piNumParameters AS INTEGER,
                                                               poParameter1 AS System.Object,
                                                               pcParameterType1 AS CHARACTER, 
                                                               poParameter2 AS System.Object,
                                                               pcParameterType2 AS CHARACTER, 
                                                               poParameter3 AS System.Object,
                                                               pcParameterType3 AS CHARACTER, 
                                                               poParameter4 AS System.Object,
                                                               pcParameterType4 AS CHARACTER, 
                                                               poParameter5 AS System.Object,
                                                               pcParameterType5 AS CHARACTER, 
                                                               poParameter6 AS System.Object,
                                                               pcParameterType6 AS CHARACTER, 
                                                               poParameter7 AS System.Object,
                                                               pcParameterType7 AS CHARACTER,
                                                               poParameter8 AS System.Object,
                                                               pcParameterType8 AS CHARACTER, 
                                                               poParameter9 AS System.Object,
                                                               pcParameterType9 AS CHARACTER, 
                                                               poParameter10 AS System.Object,
                                                               pcParameterType10 AS CHARACTER):

        DEFINE VARIABLE oMethodType        AS System.Type                  NO-UNDO . 
        DEFINE VARIABLE oMethodInfo        AS System.Reflection.MethodInfo NO-UNDO . 
        DEFINE VARIABLE oGenericMethodInfo AS System.Reflection.MethodInfo NO-UNDO . 
        DEFINE VARIABLE oMethodTypeOfArray AS "System.Type[]"              NO-UNDO . 
        DEFINE VARIABLE oParameters        AS "System.Object[]"            NO-UNDO . 
        DEFINE VARIABLE oParameterTypes    AS "System.Type[]"              NO-UNDO . 
            
        oMethodTypeOfArray = {Consultingwerk/new-array.i System.Type 1}.
            
        IF piNumParameters > 0 THEN 
            ASSIGN oParameters     = {Consultingwerk/new-array.i System.Object piNumParameters}
                   oParameterTypes = {Consultingwerk/new-array.i System.Type piNumParameters} .
        ELSE 
            ASSIGN oParameters     = ? 
                   oParameterTypes = ? .
            
        IF piNumParameters > 0 THEN 
            oParameterTypes:SetValue (poParameter1, 0) .
        IF piNumParameters > 1 THEN 
            oParameterTypes:SetValue (poParameter2, 1) .
        IF piNumParameters > 2 THEN 
            oParameterTypes:SetValue (poParameter3, 2) .
        IF piNumParameters > 3 THEN
            oParameterTypes:SetValue (poParameter4, 3) .
        IF piNumParameters > 4 THEN 
            oParameterTypes:SetValue (poParameter5, 4) .
        IF piNumParameters > 5 THEN 
            oParameterTypes:SetValue (poParameter6, 5) .
        IF piNumParameters > 6 THEN 
            oParameterTypes:SetValue (poParameter7, 6) .
        IF piNumParameters > 7 THEN 
            oParameterTypes:SetValue (poParameter8, 7) .
        IF piNumParameters > 8 THEN 
            oParameterTypes:SetValue (poParameter9, 8) .
        IF piNumParameters > 9 THEN 
            oParameterTypes:SetValue (poParameter10, 9) .
            
        IF piNumParameters > 0 THEN 
            oParameters:SetValue (Progress.Util.TypeHelper:GetType (pcParameterType1), 0) .
        IF piNumParameters > 1 THEN 
            oParameters:SetValue (Progress.Util.TypeHelper:GetType (pcParameterType2), 1) .
        IF piNumParameters > 2 THEN 
            oParameters:SetValue (Progress.Util.TypeHelper:GetType (pcParameterType3), 2) .
        IF piNumParameters > 3 THEN
            oParameters:SetValue (Progress.Util.TypeHelper:GetType (pcParameterType4), 3) .
        IF piNumParameters > 4 THEN 
            oParameters:SetValue (Progress.Util.TypeHelper:GetType (pcParameterType5), 4) .
        IF piNumParameters > 5 THEN 
            oParameters:SetValue (Progress.Util.TypeHelper:GetType (pcParameterType6), 5) .
        IF piNumParameters > 6 THEN 
            oParameters:SetValue (Progress.Util.TypeHelper:GetType (pcParameterType7), 6) .
        IF piNumParameters > 7 THEN 
            oParameters:SetValue (Progress.Util.TypeHelper:GetType (pcParameterType8), 7) .
        IF piNumParameters > 8 THEN 
            oParameters:SetValue (Progress.Util.TypeHelper:GetType (pcParameterType9), 8) .
        IF piNumParameters > 9 THEN 
            oParameters:SetValue (Progress.Util.TypeHelper:GetType (pcParameterType10), 9) .
                        
        oMethodTypeOfArray:SetValue (Progress.Util.TypeHelper:GetType (pcMethodOfType), 0) .
            
        oMethodType = poTarget:GetType () . 
        
        IF piNumParameters > 0 THEN 
            oMethodInfo = oMethodType:GetMethod (pcMethodName, oParameterTypes) .
        ELSE 
            oMethodInfo = oMethodType:GetMethod (pcMethodName) .
            
        oGenericMethodInfo = oMethodInfo:MakeGenericMethod (oMethodTypeOfArray) .
            
        RETURN oGenericMethodInfo:Invoke (poTarget, oParameters) .

    END METHOD.

    /*------------------------------------------------------------------------------
        Purpose: Dynamically Set a property value from a .NET object                                                                      
        Notes:   Uses reflection, ABL Value types need to be BOXed                  
        @param poObject The object to set a property value for
        @param pcPropertyName The name of the property to set the value for
        @param poValue The value for the property                                                            
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC STATIC VOID SetPropertyValue (poObject AS System.Object,
                                                pcPropertyName AS CHARACTER,
                                                poValue AS System.Object):
        
        DEFINE VARIABLE oType     AS System.Type                    NO-UNDO .
        DEFINE VARIABLE oProperty AS System.Reflection.PropertyInfo NO-UNDO .  
        
        ASSIGN oType     = poObject:GetType () 
               oProperty = oType:GetProperty (pcPropertyName) .

        IF VALID-OBJECT (oProperty) THEN 
            oProperty:SetValue (poObject, poValue, ?) .

    END METHOD.
&ENDIF
END CLASS.
