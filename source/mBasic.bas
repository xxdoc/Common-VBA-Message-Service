Attribute VB_Name = "mBasic"
Option Explicit
' ----------------------------------------------------------------------------
' Standard Module mBasic
' Declarations, procedures, methods and function likely to be required in any
' VB-Project, optionally just being copied
'
' Note: The mBasic component may be installed 'all allone'. However, when the
'       Common VBA Message Services Component (mMsg) and or the Common VBA
'       Error Handling Component (mErH) is installed an error message is
'       passed on to their corresponding procedure which provides a much
'       better service.
'
' Procedures, Functions, Services:
' - AppErr 3)           Converts a positive error number into a negative to
'                       ensures an error number not conflicting with a VB
'                       runt time error or any other system error number.
'                       Returns the origin positive error number when called
'                       with the negative Application Error number. 3)
' - AppIsInstalled      Returns TRUE when a named exec is found in the system
'                       path.
' - ArrayCompare        Compares two one-dimensional arrays. Returns an array
'                       with all different items.
' - ArrayIsAllocated    Returns TRUE when the provided array has at least one
'                       item.
' - ArrayNoOfDims       Returns the number of dimensions of an array.
' - ArrayRemoveItem     Removes an array's item by its index or element number
' - ArrayToRange        Transferres the content of a one- or two-dimensional
'                       array to a range
' - ArrayTrim           Removes any leading or trailing empty items.
' - BoP/EoP 1), 2)
' - BoC/EoC 1), 2)
' - CleanTrim           Clears a string from any unprinable characters.
' - ErrMsg              Displays a common error message by means of the
'                       VB MsgBox. 1), 2)
'                       component where the code has BoP/EoP statements.
' - ErrSrc 3)           Unambigous identification of a procedure. Used with
'                       error message for example
' - TimedDoEvents       Performs a DoEvent by taking the elapsed time printed
'                       in VBE's immediate window
' - TimerBegin          Starts a timer (counting system ticks)
' - TimerEnd            Returns the elapsed system ticks converted to milliseconds
'
' Requires:             Reference to:
'                       "Microsoft Scripting Runtime"
'                       "Microsoft Visual Basic Application Extensibility .."
' Optional:             fMsg, mMsg, mErH
'
' 1) Serves for a comprehensive display of an error message when the Common
'    VBA Error Services Component mErH is installed and the Conditional
'    Compile Argument 'ErHComp = 1' and serves for the execution trace (when
'    the Common VBA Execution Trace Service Component mTrc is installed and
'    the Conditional Compile Argument 'ExecTrace = 1'.
' 2) When this mBasic module is not used in a VB-Project the procedures may
'    be copied as Private Sub into any component. The procedure(s) ensure
'    that the Common VBA Error Services 4) and/or the Common VBA Execution
'    Trace Service 5) are optional components.
' 3) To be copied as Private procedure into any component which raises
'    Application Errors by means of Err.Raise.
' 4) https://github.com/warbe-maker/Common-VBA-Error-Services
' 5) https://github.com/warbe-maker/Common-VBA-Execution-Trace-Service
'
' W. Rauschenberger, Berlin Feb. 2022
'
' See https://github.com/warbe-maker/VBA-Basic-Procedures
' ----------------------------------------------------------------------------
' Basic declarations potentially uesefull in any VB-Project
Public Declare PtrSafe Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)
Public Declare PtrSafe Function GetSystemMetrics32 Lib "user32" Alias "GetSystemMetrics" (ByVal nIndex As Long) As Long

' Timer means
Private Declare PtrSafe Function getFrequency Lib "kernel32" _
Alias "QueryPerformanceFrequency" (TimerSystemFrequency As Currency) As Long
Private Declare PtrSafe Function getTickCount Lib "kernel32" _
Alias "QueryPerformanceCounter" (cyTickCount As Currency) As Long

'Functions to get DPI
Private Declare PtrSafe Function GetDC Lib "user32" (ByVal hWnd As Long) As Long
Private Declare PtrSafe Function GetDeviceCaps Lib "gdi32" (ByVal hDC As Long, ByVal nIndex As Long) As Long
Private Declare PtrSafe Function ReleaseDC Lib "user32" (ByVal hWnd As Long, ByVal hDC As Long) As Long
Private Const LOGPIXELSX = 88               ' Pixels/inch in X
Private Const POINTS_PER_INCH As Long = 72  ' A point is defined as 1/72 inches
Private Declare PtrSafe Function GetForegroundWindow _
  Lib "User32.dll" () As Long

Private Declare PtrSafe Function GetWindowLongPtr _
  Lib "User32.dll" Alias "GetWindowLongA" _
    (ByVal hWnd As LongPtr, _
     ByVal nIndex As Long) _
  As LongPtr

Private Declare PtrSafe Function SetWindowLongPtr _
  Lib "User32.dll" Alias "SetWindowLongA" _
    (ByVal hWnd As LongPtr, _
     ByVal nIndex As LongPtr, _
     ByVal dwNewLong As LongPtr) _
  As LongPtr

Private Const WS_THICKFRAME As Long = &H40000
Private Const GWL_STYLE As Long = -16
                
Public Const DCONCAT    As String = "||"    ' For concatenating and error with a general message (info) to the error description
Public Const DGT        As String = ">"
Public Const DLT        As String = "<"
Public Const DAPOST     As String = "'"
Public Const DKOMMA     As String = ","
Public Const DBSLASH    As String = "\"
Public Const DDOT       As String = "."
Public Const DCOLON     As String = ":"
Public Const DEQUAL     As String = "="
Public Const DSPACE     As String = " "
Public Const DEXCL      As String = "!"
Public Const DQUOTE     As String = """" ' one " character
Private vMsgReply       As Variant

' Common xl constants grouped ----------------------------
Public Enum YesNo   ' ------------------------------------
    xlYes = 1       ' System constants (identical values)
    xlNo = 2        ' grouped for being used as Enum Type.
End Enum            ' ------------------------------------
Public Enum xlOnOff ' ------------------------------------
    xlOn = 1        ' System constants (identical values)
    xlOff = -4146   ' grouped for being used as Enum Type.
End Enum            ' ------------------------------------
Public Enum StringAlign
    AlignLeft = 1
    AlignRight = 2
    AlignCentered = 3
End Enum

Private cyTimerTicksBegin       As Currency
Private cyTimerTicksEnd         As Currency
Private TimerSystemFrequency    As Currency

Public Property Get MsgReply() As Variant:          MsgReply = vMsgReply:   End Property

Public Property Let MsgReply(ByVal v As Variant):   vMsgReply = v:          End Property

Private Property Get SysFrequency() As Currency
    If TimerSystemFrequency = 0 Then getFrequency TimerSystemFrequency
    SysFrequency = TimerSystemFrequency
End Property

Private Property Get TimerSecsElapsed() As Currency:        TimerSecsElapsed = TimerTicksElapsed / SysFrequency:        End Property

Private Property Get TimerSysCurrentTicks() As Currency:    getTickCount TimerSysCurrentTicks:  End Property

Private Property Get TimerTicksElapsed() As Currency:       TimerTicksElapsed = cyTimerTicksEnd - cyTimerTicksBegin:    End Property

Public Function Align( _
                ByVal align_s As String, _
                ByVal align_lngth As Long, _
       Optional ByVal align_mode As StringAlign = AlignLeft, _
       Optional ByVal align_margin As String = vbNullString, _
       Optional ByVal align_fill As String = " ") As String
' ---------------------------------------------------------
' Returns a string (align_s) with a lenght (align_lngth)
' aligned (aligned) filled with characters (align_fill).
' ---------------------------------------------------------
    Dim SpaceLeft       As Long
    Dim LengthRemaining As Long
    
    Select Case align_mode
        Case AlignLeft
            If Len(align_s & align_margin) >= align_lngth _
            Then Align = VBA.Left$(align_s & align_margin, align_lngth) _
            Else Align = align_s & align_margin & VBA.String$(align_lngth - (Len(align_s & align_margin)), align_fill)
        Case AlignRight
            If Len(align_margin & align_s) >= align_lngth _
            Then Align = VBA.Left$(align_margin & align_s, align_lngth) _
            Else Align = VBA.String$(align_lngth - (Len(align_margin & align_s)), align_fill) & align_margin & align_s
        Case AlignCentered
            If Len(align_margin & align_s & align_margin) >= align_lngth Then
                Align = align_margin & Left$(align_s, align_lngth - (2 * Len(align_margin))) & align_margin
            Else
                SpaceLeft = Max(1, ((align_lngth - Len(align_s) - (2 * Len(align_margin))) / 2))
                Align = VBA.String$(SpaceLeft, align_fill) & align_margin & align_s & align_margin & VBA.String$(SpaceLeft, align_fill)
                Align = VBA.Right$(Align, align_lngth)
            End If
    End Select

End Function

Private Function AppErr(ByVal app_err_no As Long) As Long
' ------------------------------------------------------------------------------
' Ensures that a programmed 'Application' error number not conflicts with the
' number of a 'VB Runtime Error' or any other system error.
' - Returns a given positive 'Application Error' number (app_err_no) into a
'   negative by adding the system constant vbObjectError
' - Returns the original 'Application Error' number when called with a negative
'   error number.
' ------------------------------------------------------------------------------
    If app_err_no >= 0 Then AppErr = app_err_no + vbObjectError Else AppErr = Abs(app_err_no - vbObjectError)
End Function

Public Function AppIsInstalled(ByVal exe As String) As Boolean
' ------------------------------------------------------------------------------
' Returns TRUE when an application (exe) is installed, i.e. the provided name
' is found in the VBA.Environ$ Path.
' ------------------------------------------------------------------------------
    Dim i As Long: i = 1
    Do Until VBA.Environ$(i) Like "Path=*": i = i + 1: Loop
    AppIsInstalled = Environ$(i) Like "*" & exe & "*"
End Function

Public Function ArrayCompare(ByVal ac_a1 As Variant, _
                             ByVal ac_a2 As Variant, _
                    Optional ByVal ac_stop_after As Long = 0, _
                    Optional ByVal ac_id1 As String = vbNullString, _
                    Optional ByVal ac_id2 As String = vbNullString, _
                    Optional ByVal ac_ignore_case As Boolean = True, _
                    Optional ByVal ac_ignore_empty As Boolean = True) As Dictionary
' --------------------------------------------------------------------------
' Returns a Dictionary with n (ac_stop_after) lines which are different
' between array 1 (ac_a1) and array 2 (ac_a2) with the line number as the
' key and the two different lines as item in the form: '<line>'vbLf'<line>'
' When no differnece is encountered the returned Dictionary is empty.
' When no ac_stop_after <> 0 is provided all lines different are returned
' --------------------------------------------------------------------------
    Const PROC = "ArrayCompare"
    
    On Error GoTo eh
    Dim j       As Long
    Dim l       As Long
    Dim i       As Long
    Dim lMethod As VbCompareMethod
    Dim dct     As New Dictionary
    
    If ac_ignore_case Then lMethod = vbTextCompare Else lMethod = vbBinaryCompare
    
    If Not mBasic.ArrayIsAllocated(ac_a1) And mBasic.ArrayIsAllocated(ac_a2) Then
        If ac_ignore_empty Then mBasic.ArrayTrimm ac_a2
        For i = LBound(ac_a2) To UBound(ac_a2)
            dct.Add i + 1, "'" & ac_a2(i) & "'" & vbLf
        Next i
    ElseIf mBasic.ArrayIsAllocated(ac_a1) And Not mBasic.ArrayIsAllocated(ac_a2) Then
        If ac_ignore_empty Then mBasic.ArrayTrimm ac_a1
        For i = LBound(ac_a1) To UBound(ac_a1)
            dct.Add i + 1, "'" & ac_a1(i) & "'" & vbLf
        Next i
    ElseIf Not mBasic.ArrayIsAllocated(ac_a1) And Not mBasic.ArrayIsAllocated(ac_a2) Then
        GoTo xt
    End If
    
    If ac_ignore_empty Then mBasic.ArrayTrimm ac_a1
    If ac_ignore_empty Then mBasic.ArrayTrimm ac_a2
    
    l = 0
    For i = LBound(ac_a1) To Min(UBound(ac_a1), UBound(ac_a2))
        If StrComp(ac_a1(i), ac_a2(i), lMethod) <> 0 Then
            dct.Add i + 1, "'" & ac_a1(i) & "'" & vbLf & "'" & ac_a2(i) & "'"
            l = l + 1
            If ac_stop_after <> 0 And l >= ac_stop_after Then
                GoTo xt
            End If
        End If
    Next i
    
    If UBound(ac_a1) < UBound(ac_a2) Then
        For i = UBound(ac_a1) + 1 To UBound(ac_a2)
            dct.Add i + 1, "''" & vbLf & " '" & ac_a2(i) & "'"
            l = l + 1
            If ac_stop_after <> 0 And l >= ac_stop_after Then
                GoTo xt
            End If
        Next i
        
    ElseIf UBound(ac_a2) < UBound(ac_a1) Then
        For i = UBound(ac_a2) + 1 To UBound(ac_a1)
            dct.Add i + 1, "'" & ac_a1(i) & "'" & vbLf & "''"
            l = l + 1
            If ac_stop_after <> 0 And l >= ac_stop_after Then
                GoTo xt
            End If
        Next i
    End If

xt: Set ArrayCompare = dct
    Exit Function
    
eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbYes: Stop: Resume
        Case Else:  GoTo xt
    End Select
End Function

Public Function ArrayDiffers(ByVal a1 As Variant, _
                             ByVal a2 As Variant) As Boolean
' ----------------------------------------------------------
' Returns TRUE when array (a1) differs from array (a2).
' ----------------------------------------------------------
    Const PROC  As String = "ArrayDiffers"
    
    Dim i       As Long
    Dim va()    As Variant

    On Error GoTo eh
    
    If Not mBasic.ArrayIsAllocated(a1) And mBasic.ArrayIsAllocated(a2) Then
        va = a2
    ElseIf mBasic.ArrayIsAllocated(a1) And Not mBasic.ArrayIsAllocated(a2) Then
        va = a1
    ElseIf Not mBasic.ArrayIsAllocated(a1) And Not mBasic.ArrayIsAllocated(a2) Then
        GoTo xt
    End If
    
    On Error Resume Next
    ArrayDiffers = Join(a1) <> Join(a2)
    If Err.Number = 0 Then GoTo xt
    
    '~~ At least one of the joins resulted in a string exeeding the maximum possible lenght
    For i = LBound(a1) To Min(UBound(a1), UBound(a2))
        If a1(i) <> a2(i) Then
            ArrayDiffers = True
            Exit Function
        End If
    Next i
    
xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbYes: Stop: Resume
        Case Else:  GoTo xt
    End Select
End Function

Public Function ArrayIsAllocated(arr As Variant) As Boolean
    
    On Error Resume Next
    ArrayIsAllocated = _
    IsArray(arr) _
    And Not IsError(LBound(arr, 1)) _
    And LBound(arr, 1) <= UBound(arr, 1)
    
End Function

Public Function ArrayNoOfDims(arr As Variant) As Integer
' ------------------------------------------------------
' Returns the number of dimensions of an array. An un-
' allocated dynamic array has 0 dimensions. This may as
' as well be tested by means of ArrayIsAllocated.
' ------------------------------------------------------

    On Error Resume Next
    Dim Ndx As Integer
    Dim Res As Integer
    
    ' Loop, increasing the dimension index Ndx, until an error occurs.
    ' An error will occur when Ndx exceeds the number of dimension
    ' in the array. Return Ndx - 1.
    Do
        Ndx = Ndx + 1
        Res = UBound(arr, Ndx)
    Loop Until Err.Number <> 0
    Err.Clear
    ArrayNoOfDims = Ndx - 1

End Function

Public Sub ArrayRemoveItems(ByRef ri_va As Variant, _
                   Optional ByVal ri_element As Variant, _
                   Optional ByVal ri_index As Variant, _
                   Optional ByVal ri_no_of_elements = 1)
' ------------------------------------------------------------------------------
' Returns the 'one dimensional'! array (ri_va) with the number of elements
' (ri_no_of_elements) removed whereby the start element may be indicated by the
' element number 1,2,... (ri_element) or the index (ri_index) which must be
' within the array's LBound to Ubound. Any inappropriate provision of arguments
' raises a clear error message. When the last item in an array is removed the
' returned array is erased (no longer allocated).
'
' W. Rauschenberger, Berlin Feb 2022
' ------------------------------------------------------------------------------
    Const PROC = "ArrayRemoveItems"

    On Error GoTo eh
    Dim a                   As Variant
    Dim iElement            As Long
    Dim iIndex              As Long
    Dim NoOfElementsInArray As Long
    Dim i                   As Long
    Dim iNewUBound          As Long
    
    BoP ErrSrc(PROC)
    If Not mBasic.ArrayIsAllocated(ri_va) Then
        Err.Raise AppErr(1), ErrSrc(PROC), "Array not provided!"
    Else
        a = ri_va
        NoOfElementsInArray = UBound(a) - LBound(a) + 1
    End If
    If Not ArrayNoOfDims(a) = 1 Then
        Err.Raise AppErr(2), ErrSrc(PROC), "Array must not be multidimensional!"
    End If
    If Not IsNumeric(ri_element) And Not IsNumeric(ri_index) Then
        Err.Raise AppErr(3), ErrSrc(PROC), "Neither FromElement nor FromIndex is a numeric value!"
    End If
    If IsNumeric(ri_element) Then
        iElement = ri_element
        If iElement < 1 _
        Or iElement > NoOfElementsInArray Then
            Err.Raise AppErr(4), ErrSrc(PROC), "vFromElement is not between 1 and " & NoOfElementsInArray & " !"
        Else
            iIndex = LBound(a) + iElement - 1
        End If
    End If
    If IsNumeric(ri_index) Then
        iIndex = ri_index
        If iIndex < LBound(a) _
        Or iIndex > UBound(a) Then
            Err.Raise AppErr(5), ErrSrc(PROC), "FromIndex is not between " & LBound(a) & " and " & UBound(a) & " !"
        Else
            iElement = ElementOfIndex(a, iIndex)
        End If
    End If
    If iElement + ri_no_of_elements - 1 > NoOfElementsInArray Then
        Err.Raise AppErr(6), ErrSrc(PROC), "FromElement (" & iElement & ") plus the number of elements to remove (" & ri_no_of_elements & ") is beyond the number of elelemnts in the array (" & NoOfElementsInArray & ")!"
    End If
    
    For i = iIndex + ri_no_of_elements To UBound(a)
        a(i - ri_no_of_elements) = a(i)
    Next i
    
    iNewUBound = UBound(a) - ri_no_of_elements
    If iNewUBound < 0 Then Erase a Else ReDim Preserve a(LBound(a) To iNewUBound)
    ri_va = a
    
xt: EoP ErrSrc(PROC)
    Exit Sub

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbYes: Stop: Resume
        Case Else:  GoTo xt
    End Select
End Sub

Public Sub ArrayToRange(ByVal vArr As Variant, _
                        ByVal r As Range, _
               Optional ByVal bOneCol As Boolean = False)
' -------------------------------------------------------
' Copy the content of the Arry (vArr) to the range (r).
' -------------------------------------------------------
    Const PROC = "ArrayToRange"
    
    On Error GoTo eh
    Dim rTarget As Range

    If bOneCol Then
        '~~ One column, n rows
        Set rTarget = r.Cells(1, 1).Resize(UBound(vArr), 1)
        rTarget.Value = Application.Transpose(vArr)
    Else
        '~~ One column, n rows
        Set rTarget = r.Cells(1, 1).Resize(1, UBound(vArr))
        rTarget.Value = vArr
    End If
    
xt: Exit Sub

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbYes: Stop: Resume
        Case Else:  GoTo xt
    End Select
End Sub

Public Sub ArrayTrimm(ByRef a As Variant)
' ------------------------------------------------------------------------------
' Returns the array (a) with all leading and trailing blank items removed. Any
' vbCr, vbCrLf, vbLf are ignored. When the array contains only blank items the
' returned array is erased.
' ------------------------------------------------------------------------------
    Const PROC  As String = "ArrayTrimm"

    On Error GoTo eh
    Dim i As Long
    
    '~~ Eliminate leading blank lines
    If Not mBasic.ArrayIsAllocated(a) Then Exit Sub
    
    Do While (Len(Trim$(a(LBound(a)))) = 0 Or Trim$(a(LBound(a))) = " ") And UBound(a) >= 0
        mBasic.ArrayRemoveItems ri_va:=a, ri_index:=i
        If Not mBasic.ArrayIsAllocated(a) Then Exit Do
    Loop
    
    If mBasic.ArrayIsAllocated(a) Then
        Do While (Len(Trim$(a(UBound(a)))) = 0 Or Trim$(a(LBound(a))) = " ") And UBound(a) >= 0
            If UBound(a) = 0 Then
                Erase a
            Else
                ReDim Preserve a(UBound(a) - 1)
            End If
            If Not mBasic.ArrayIsAllocated(a) Then Exit Do
        Loop
    End If

xt: Exit Sub
    
eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbYes: Stop: Resume
        Case Else:  GoTo xt
    End Select
End Sub

Public Function BaseName(ByVal v As Variant) As String
' -----------------------------------------------------
' Returns the file name without the extension. v may be
' a file name a file path (full name) a File object or
' a Workbook object.
' -----------------------------------------------------
    Const PROC  As String = "BaseName"
    
    On Error GoTo eh
    Dim fso As New FileSystemObject
    
    With fso
        Select Case TypeName(v)
            Case "String":      BaseName = .GetBaseName(v)
            Case "Workbook":    BaseName = .GetBaseName(v.FullName)
            Case "File":        BaseName = .GetBaseName(v.ShortName)
            Case Else:          Err.Raise AppErr(1), ErrSrc(PROC), "The parameter (v) is neither a string nor a File or Workbook object (TypeName = '" & TypeName(v) & "')!"
        End Select
    End With

xt: Exit Function
    
eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbYes: Stop: Resume
        Case Else:  GoTo xt
    End Select
End Function

Public Sub BoC(ByVal boc_id As String, ParamArray b_arguments() As Variant)
' ------------------------------------------------------------------------------
' (B)egin-(o)f-(C)ode with id (boc_id) trace. Procedure to be copied as Private
' into any module potentially using the Common VBA Execution Trace Service. Has
' no effect when Conditional Compile Argument is 0 or not set at all.
' Note: The begin id (boc_id) has to be identical with the paired EoC statement.
' ------------------------------------------------------------------------------
    Dim s As String: If UBound(b_arguments) >= 0 Then s = Join(b_arguments, ",")
#If ExecTrace = 1 Then
    mTrc.BoC boc_id, s
#End If
End Sub

Public Sub BoP(ByVal b_proc As String, ParamArray b_arguments() As Variant)
' ------------------------------------------------------------------------------
' (B)egin-(o)f-(P)rocedure named (b_proc). Procedure to be copied as Private
' into any module potentially either using the Common VBA Error Service and/or
' the Common VBA Execution Trace Service. Has no effect when Conditional Compile
' Arguments are 0 or not set at all.
' ------------------------------------------------------------------------------
    Dim s As String: If UBound(b_arguments) >= 0 Then s = Join(b_arguments, ",")
#If ErHComp = 1 Then
    mErH.BoP b_proc, s
#ElseIf ExecTrace = 1 Then
    mTrc.BoP b_proc, s
#End If
End Sub

Public Function Center(ByVal s1 As String, _
                       ByVal l As Long, _
               Optional ByVal sFill As String = " ") As String
' ------------------------------------------------------------
' Returns s1 centered in a string with length l.
' ------------------------------------------------------------
    Dim lSpace As Long
    lSpace = Max(1, ((l - Len(s1)) / 2))
    Center = VBA.String$(lSpace, sFill) & s1 & VBA.String$(lSpace, sFill)
    Center = Right(Center, l)
End Function

Public Function CleanTrim(ByVal s As String, _
                 Optional ByVal ConvertNonBreakingSpace As Boolean = True) As String
' ----------------------------------------------------------------------------------
' Returns the string 's' cleaned from any non-printable characters.
' ----------------------------------------------------------------------------------
    Const PROC = "CleanTrim"
    
    On Error GoTo eh
    Dim l           As Long
    Dim asToClean   As Variant
    
    asToClean = Array(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, _
                     21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 127, 129, 141, 143, 144, 157)
    If ConvertNonBreakingSpace Then s = Replace(s, Chr$(160), " ")
    For l = LBound(asToClean) To UBound(asToClean)
        If InStr(s, Chr$(asToClean(l))) Then s = Replace(s, Chr$(asToClean(l)), vbNullString)
    Next
    
xt: CleanTrim = s
    Exit Function
    
eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbYes: Stop: Resume
        Case Else:  GoTo xt
    End Select
End Function

Public Function ElementOfIndex(ByVal a As Variant, _
                                ByVal i As Long) As Long
' ------------------------------------------------------
' Returns the element number of index (i) in array (a).
' ------------------------------------------------------
    
    Dim ia  As Long
    
    For ia = LBound(a) To i
        ElementOfIndex = ElementOfIndex + 1
    Next ia
    
End Function

Public Sub EoC(ByVal eoc_id As String, ParamArray b_arguments() As Variant)
' ------------------------------------------------------------------------------
' (E)nd-(o)f-(C)ode id (eoc_id) trace. Procedure to be copied as Private into
' any module potentially using the Common VBA Execution Trace Service. Has no
' effect when the Conditional Compile Argument is 0 or not set at all.
' Note: The end id (eoc_id) has to be identical with the paired BoC statement.
' ------------------------------------------------------------------------------
    Dim s As String: If UBound(b_arguments) >= 0 Then s = Join(b_arguments, ",")
#If ExecTrace = 1 Then
    mTrc.BoC eoc_id, s
#End If
End Sub

Public Sub EoP(ByVal e_proc As String, _
      Optional ByVal e_inf As String = vbNullString)
' ------------------------------------------------------------------------------
' (E)nd-(o)f-(P)rocedure named (e_proc). Procedure to be copied as Private Sub
' into any module potentially either using the Common VBA Error Service and/or
' the Common VBA Execution Trace Service. Has no effect when Conditional Compile
' Arguments are 0 or not set at all.
' ------------------------------------------------------------------------------
#If ErHComp = 1 Then
    mErH.EoP e_proc
#ElseIf ExecTrace = 1 Then
    mTrc.EoP e_proc, e_inf
#End If
End Sub

Public Function ErrMsg(ByVal err_source As String, _
              Optional ByVal err_no As Long = 0, _
              Optional ByVal err_dscrptn As String = vbNullString, _
              Optional ByVal err_line As Long = 0) As Variant
' ------------------------------------------------------------------------------
' Universal error message display service. See:
' https://warbe-maker.github.io/vba/common/2022/02/15/Personal-and-public-Common-Components.html
'
' - Displays a debugging option button when the Conditional Compile Argument
'   'Debugging = 1'
' - Displays an optional additional "About the error:" section when a string is
'   concatenated with the error message by two vertical bars (||)
' - Invokes mErH.ErrMsg when the Conditional Compile Argument ErHComp = !
' - Invokes mMsg.ErrMsg when the Conditional Compile Argument MsgComp = ! (and
'   the mErH module is not installed / MsgComp not set)
' - Displays the error message by means of VBA.MsgBox when neither of the two
'   components is installed
'
' Uses:
' - AppErr For programmed application errors (Err.Raise AppErr(n), ....) to
'          turn them into negative and in the error message back into a
'          positive number.
' - ErrSrc To provide an unambiguous procedure name by prefixing is with the
'          module name.
'
' See:
' https://github.com/warbe-maker/Common-VBA-Error-Services
'
' W. Rauschenberger Berlin, Feb 2022
' ------------------------------------------------------------------------------' ------------------------------------------------------------------------------
#If ErHComp = 1 Then
    '~~ When Common VBA Error Services (mErH) is availabel in the VB-Project
    '~~ (which includes the mMsg component) the mErh.ErrMsg service is invoked.
    ErrMsg = mErH.ErrMsg(err_source, err_no, err_dscrptn, err_line): GoTo xt
#ElseIf MsgComp = 1 Then
    '~~ When (only) the Common Message Service (mMsg, fMsg) is available in the
    '~~ VB-Project, mMsg.ErrMsg is invoked for the display of the error message.
    ErrMsg = mMsg.ErrMsg(err_source, err_no, err_dscrptn, err_line): GoTo xt
#End If
    '~~ When neither of the Common Component is available in the VB-Project
    '~~ the error message is displayed by means of the VBA.MsgBox
    Dim ErrBttns    As Variant
    Dim ErrAtLine   As String
    Dim ErrDesc     As String
    Dim ErrLine     As Long
    Dim ErrNo       As Long
    Dim ErrSrc      As String
    Dim ErrText     As String
    Dim ErrTitle    As String
    Dim ErrType     As String
    Dim ErrAbout    As String
        
    '~~ Obtain error information from the Err object for any argument not provided
    If err_no = 0 Then err_no = Err.Number
    If err_line = 0 Then ErrLine = Erl
    If err_source = vbNullString Then err_source = Err.source
    If err_dscrptn = vbNullString Then err_dscrptn = Err.Description
    If err_dscrptn = vbNullString Then err_dscrptn = "--- No error description available ---"
    
    '~~ Consider extra information is provided with the error description
    If InStr(err_dscrptn, "||") <> 0 Then
        ErrDesc = Split(err_dscrptn, "||")(0)
        ErrAbout = Split(err_dscrptn, "||")(1)
    Else
        ErrDesc = err_dscrptn
    End If
    
    '~~ Determine the type of error
    Select Case err_no
        Case Is < 0
            ErrNo = AppErr(err_no)
            ErrType = "Application Error "
        Case Else
            ErrNo = err_no
            If err_dscrptn Like "*DAO*" _
            Or err_dscrptn Like "*ODBC*" _
            Or err_dscrptn Like "*Oracle*" _
            Then ErrType = "Database Error " _
            Else ErrType = "VB Runtime Error "
    End Select
    
    If err_source <> vbNullString Then ErrSrc = " in: """ & err_source & """"   ' assemble ErrSrc from available information"
    If err_line <> 0 Then ErrAtLine = " at line " & err_line                    ' assemble ErrAtLine from available information
    ErrTitle = Replace(ErrType & ErrNo & ErrSrc & ErrAtLine, "  ", " ")         ' assemble ErrTitle from available information
       
    ErrText = "Error: " & vbLf & ErrDesc & vbLf & vbLf & "Source: " & vbLf & err_source & ErrAtLine
    If ErrAbout <> vbNullString Then ErrText = ErrText & vbLf & vbLf & "About: " & vbLf & ErrAbout
    
#If Debugging Then
    ErrBttns = vbYesNo
    ErrText = ErrText & vbLf & vbLf & "Debugging:" & vbLf & "Yes    = Resume Error Line" & vbLf & "No     = Terminate"
#Else
    ErrBttns = vbCritical
#End If
    ErrMsg = MsgBox(Title:=ErrTitle, Prompt:=ErrText, Buttons:=ErrBttns)
xt:
End Function

Private Function ErrSrc(ByVal sProc As String) As String
    ErrSrc = "mBasic." & sProc
End Function

Public Function IsCvName(ByVal v As Variant) As Boolean
    If VarType(v) = vbString Then IsCvName = True
End Function

Public Function IsCvObject(ByVal v As Variant) As Boolean

    If VarType(v) = vbObject Then
        If Not TypeName(v) = "Nothing" Then
            IsCvObject = TypeOf v Is CustomView
        End If
    End If
    
End Function

Public Function IsPath(ByVal v As Variant) As Boolean
    
    If VarType(v) = vbString Then
        If InStr(v, "\") <> 0 Then
            If InStr(Right$(v, 6), ".") = 0 Then
                IsPath = True
            End If
        End If
    End If

End Function

Public Function IsString(ByVal v As Variant, _
                Optional ByVal vbnullstring_is_a_string = False) As Boolean
' ----------------------------------------------------------------------------
' Returns TRUE when v is neither an object nor numeric.
' ----------------------------------------------------------------------------
    Dim s As String
    On Error Resume Next
    s = v
    If Err.Number = 0 Then
        If Not IsNumeric(v) Then
            If (s = vbNullString And vbnullstring_is_a_string) _
            Or s <> vbNullString _
            Then IsString = True
        End If
    End If
End Function

Public Sub MakeFormResizable()
' ---------------------------------------------------------------------------
' This part is from Leith Ross                                              |
' Found this Code on:                                                       |
' https://www.mrexcel.com/forum/excel-questions/485489-resize-userform.html |
'                                                                           |
' All credits belong to him                                                 |
' ---------------------------------------------------------------------------
    Const WS_THICKFRAME = &H40000
    Const GWL_STYLE As Long = (-16)
    
    Dim lStyle As LongPtr
    Dim hWnd As LongPtr
    Dim RetVal

    hWnd = GetForegroundWindow
    
    lStyle = GetWindowLongPtr(hWnd, GWL_STYLE Or WS_THICKFRAME)
    RetVal = SetWindowLongPtr(hWnd, GWL_STYLE, lStyle)

End Sub

Public Function Max(ParamArray va() As Variant) As Variant
' --------------------------------------------------------
' Returns the maximum value of all values provided (va).
' --------------------------------------------------------
    
    Dim v As Variant
    
    Max = va(LBound(va)): If LBound(va) = UBound(va) Then Exit Function
    For Each v In va
        If v > Max Then Max = v
    Next v
    
End Function

Public Function Min(ParamArray va() As Variant) As Variant
' --------------------------------------------------------
' Returns the minimum (smallest) of all provided values.
' --------------------------------------------------------
    
    Dim v As Variant
    
    Min = va(LBound(va)): If LBound(va) = UBound(va) Then Exit Function
    For Each v In va
        If v < Min Then Min = v
    Next v
    
End Function

Public Function PointsPerPixel() As Double
' ----------------------------------------
' Return DPI
' ----------------------------------------
    
    Dim hDC             As Long
    Dim lDotsPerInch    As Long
    
    hDC = GetDC(0)
    lDotsPerInch = GetDeviceCaps(hDC, LOGPIXELSX)
    PointsPerPixel = POINTS_PER_INCH / lDotsPerInch
    ReleaseDC 0, hDC

End Function

Public Function ProgramIsInstalled(ByVal sProgram As String) As Boolean
        ProgramIsInstalled = InStr(Environ$(18), sProgram) <> 0
End Function

Public Function SelectFolder( _
                Optional ByVal sTitle As String = "Select a Folder") As String
' ----------------------------------------------------------------------------
' Returns the selected folder or a vbNullString if none had been selected.
' ----------------------------------------------------------------------------
    
    Dim sFolder As String
    
    SelectFolder = vbNullString
    ' Open the select folder prompt
    With Application.FileDialog(msoFileDialogFolderPicker)
        .Title = sTitle
        If .Show = -1 Then ' if OK is pressed
            sFolder = .SelectedItems(1)
        End If
    End With
    SelectFolder = sFolder

End Function

Public Function Spaced(ByVal s As String) As String
' ----------------------------------------------------------------------------
' Returns a non-breaking-spaced string with any spaces already in the string
' doubled and leading or trailing spaces unstripped.
' Example: Spaced("Ab c") returns = "A b  c"
' ----------------------------------------------------------------------------
    Dim a() As Byte
    Dim i   As Long
    
    If s = vbNullString Then Exit Function
    a = StrConv(Trim$(s), vbFromUnicode)
    Spaced = Chr$(a(LBound(a)))
    For i = LBound(a) + 1 To UBound(a)
        If Chr$(a(i)) = " " Then Spaced = Spaced & Chr$(160) Else Spaced = Spaced & Chr$(160) & Chr$(a(i))
    Next i

End Function

Public Function StackEd(ByVal stck As Collection, _
               Optional ByRef stck_item As Variant = vbNullString, _
               Optional ByRef stck_lvl As Long = 0) As Variant
' ----------------------------------------------------------------------------
' Common "Stacked" service.
' - When an item (stck_item) is provided: Returns TRUE when the item
'   (stck_item) is on the stack (stck). In case a stack level is provided,
'   TRUE is returned when the item is stacked on the provided level, else
'   FALSE is returned. In case no stack level is provided (stck_lvl = 0) the
'   level of the stacked item is returned when on the stack else FALSE is
'   returned
' - When no item (stck_item) is provided and a stack level (stck_lvl <> 0)
'   is provided: The item stacked on level (stck_lvl) is returned.
' - When no item (stck_item) and no level (stck_lvl = 0) or a level > then
'   the current top level is provided a vbNullString is returned.
' Note: The item (stck_item) may be anything.
' ----------------------------------------------------------------------------
    Const PROC = "StckEd"
    
    On Error GoTo eh
    Dim v       As Variant
    Dim i       As Long
    
    If stck Is Nothing Then Set stck = New Collection
    
    If Not IsString(stck_item) And Not IsNumeric(stck_item) And Not IsObject(stck_item) Then
        '~~ An argument stack item has not been provided
        If stck_lvl = 0 Or stck_lvl > stck.Count Then GoTo xt
        '~~ The item of the stack level is returned
        If IsObject(stck(stck_lvl)) _
        Then Set StackEd = stck(stck_lvl) _
        Else StackEd = stck(stck_lvl)
    Else
        '~~ The provided stack item is either an object, a string, or numeric
        For i = 1 To stck.Count
            If IsObject(stck(i)) Then
                Set v = stck(i)
                If v Is stck_item Then
                    If stck_lvl <> 0 Then
                        If i = stck_lvl Then
                            StackEd = True
                            GoTo xt
                        End If
                    Else
                        stck_lvl = i
                    End If
                    StackEd = True
                    GoTo xt
                End If
            Else
                v = stck(i)
                If v = stck_item Then
                    If stck_lvl <> 0 Then
                        If i = stck_lvl Then
                            StackEd = True
                            GoTo xt
                        End If
                    Else
                        stck_lvl = i
                    End If
                    StackEd = True
                    GoTo xt
                End If
            End If
        Next i
    End If
    
xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbYes: Stop: Resume
        Case Else:  GoTo xt
    End Select
End Function

Public Function StackIsEmpty(ByVal stck As Collection) As Boolean
' ----------------------------------------------------------------------------
' Common Stack Empty check service. Returns True when either there is no stack
' (stck Is Nothing) or when the stack is empty (items count is 0).
' ----------------------------------------------------------------------------
    StackIsEmpty = stck Is Nothing
    If Not StackIsEmpty Then StackIsEmpty = stck.Count = 0
End Function

Public Function StackPop(ByVal stck As Collection) As Variant
' ----------------------------------------------------------------------------
' Common Stack Pop service. Returns the last item pushed on the stack (stck)
' and removes the item from the stack. When the stack (stck) is empty a
' vbNullString is returned.
' ----------------------------------------------------------------------------
    Const PROC = "StckPop"
    
    On Error GoTo eh
    If StackIsEmpty(stck) Then GoTo xt
    
    On Error Resume Next
    Set StackPop = stck(stck.Count)
    If Err.Number <> 0 _
    Then StackPop = stck(stck.Count)
    stck.Remove stck.Count

xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbYes: Stop: Resume
        Case Else:  GoTo xt
    End Select
End Function

Public Sub StackPush(ByRef stck As Collection, _
                     ByVal stck_item As Variant)
' ----------------------------------------------------------------------------
' Common Stack Push service. Pushes (adds) an item (stck_item) to the stack
' (stck). When the provided stack (stck) is Nothing the stack is created.
' ----------------------------------------------------------------------------
    Const PROC = "StckPush"
    
    On Error GoTo eh
    If stck Is Nothing Then Set stck = New Collection
    stck.Add stck_item

xt: Exit Sub

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbYes: Stop: Resume
        Case Else:  GoTo xt
    End Select
End Sub

Public Function StackTop(ByVal stck As Collection) As Variant
' ----------------------------------------------------------------------------
' Common Stack Top service. Returns the top item from the stack (stck), i.e.
' the item last pushed. If the stack is empty a vbNullString is returned.
' ----------------------------------------------------------------------------
    Const PROC = "StckTop"
    
    On Error GoTo eh
    If StackIsEmpty(stck) Then GoTo xt
    If IsObject(stck(stck.Count)) _
    Then Set StackTop = stck(stck.Count) _
    Else StackTop = stck(stck.Count)

xt: Exit Function

eh: Select Case ErrMsg(ErrSrc(PROC))
        Case vbYes: Stop: Resume
        Case Else:  GoTo xt
    End Select
End Function

Public Function TimedDoEvents(ByVal tde_source As String) As String
' ---------------------------------------------------------------------------
' For the execution of a DoEvents statement. Provides the information in
' which procedure it had been executed and the msecs delay it has caused.
'
' Note: DoEvents every now and then is able to solve timing problems. When
'       looking at the description of its effect this often appears
'       miraculous. However, when it helps ... . But DoEvents allow keyboard
'       interaction while a process executes. In case of a loop - and when
'       the DoEvents lies within it, this may be a godsend. But it as well
'       may cause unpredictable results. This little procedure at least
'       documents in the Immediate window when (with milliseconds) and where
'       it had been executed.
' ---------------------------------------------------------------------------
    Dim s As String
    
    mBasic.TimerBegin
    DoEvents
    s = Format(Now(), "hh:mm:ss") & ":" _
      & Right(Format(Timer, "0.000"), 3) _
      & " DoEvents paused the execution for " _
      & Format(mBasic.TimerEnd, "00000") _
      & " msecs in '" & tde_source & "'"
    Debug.Print s
    TimedDoEvents = s
    
End Function

Public Sub TimerBegin()
    cyTimerTicksBegin = TimerSysCurrentTicks
End Sub

Public Function TimerEnd() As Currency
    cyTimerTicksEnd = TimerSysCurrentTicks
    TimerEnd = TimerSecsElapsed * 1000
End Function

