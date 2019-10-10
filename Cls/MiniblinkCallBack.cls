VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "MiniblinkCallBack"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit
'-Callback declarations for Paul Caton thunking magic----------------------------------------------
Private z_CbMem   As Long                                                       'Callback allocated memory address
Private Declare Function GetModuleHandleA Lib "kernel32" (ByVal lpModuleName As String) As Long
Private Declare Function GetProcAddress Lib "kernel32" (ByVal hModule As Long, ByVal lpProcName As String) As Long
Private Declare Function IsBadCodePtr Lib "kernel32" (ByVal lpfn As Long) As Long
Private Declare Function VirtualAlloc Lib "kernel32" (ByVal lpAddress As Long, ByVal dwSize As Long, ByVal flAllocationType As Long, ByVal flProtect As Long) As Long
Private Declare Function VirtualFree Lib "kernel32" (ByVal lpAddress As Long, ByVal dwSize As Long, ByVal dwFreeType As Long) As Long
Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)
'-------------------------------------------------------------------------------------------------
Private Declare Sub CopyMemory2 Lib "kernel32.dll" Alias "RtlMoveMemory" (ByVal Destination As Long, ByVal Source As Long, ByVal Length As Long)

Public Return_wkeNetResponseCallback As Boolean
Public Return_jsNativeFunction As Currency
Public Return_wkeJsNativeFunction As Currency
Public Return_wkeConfirmBoxCallback As Boolean
Public Return_wkePromptBoxCallback As Boolean
Public Return_wkeNavigationCallback As Boolean
Public Return_wkeCreateViewCallback As Long
Public Return_wkeDownloadCallback As Boolean
Public Return_wkeLoadUrlBeginCallback As Boolean
Public Return_wkeWindowClosingCallback As Boolean

Public Event wkeNetResponseCallback(ByVal webView As Long, ByVal param As Long, ByVal url As String, ByVal job As Long)
Public Event wkeCallUiThread(ByVal webView As Long, ByVal func As Long, ByVal param As Long)
Public Event wkeOnCallUiThread(ByVal webView As Long, ByVal paramOnInThread As Long)
Public Event wkeOnNetGetFavicon(ByVal webView As Long, ByVal param As Long, ByVal url As String, ByRef buf As wkeMemBuf)
Public Event jsNativeFunction(ByVal es As Long)
Public Event wkeJsNativeFunction(ByVal es As Long, ByVal param As Long)
Public Event wkeTitleChangedCallback(ByVal webView As Long, ByVal param As Long, ByVal title As String)
Public Event wkeURLChangedCallback(ByVal webView As Long, ByVal param As String, ByVal url As String)
Public Event wkeURLChangedCallback2(ByVal webView As Long, ByVal param As Long, ByVal frameId As Long, ByVal url As String)
Public Event wkePaintUpdatedCallback(ByVal webView As Long, ByVal param As Long, ByVal hdc As Long, ByVal x As Long, ByVal y As Long, ByVal cx As Long, ByVal cy As Long)
Public Event wkePaintBitUpdatedCallback(ByVal webView As Long, ByVal param As Long, ByVal buffer As Long, ByRef r As wkeRect, ByVal width As Long, ByVal height As Long)
Public Event wkeAlertBoxCallback(ByVal webView As Long, ByVal param As Long, ByVal msg As String)
Public Event wkeConfirmBoxCallback(ByVal webView As Long, ByVal param As Long, ByVal msg As String)
Public Event wkePromptBoxCallback(ByVal webView As Long, ByVal param As Long, ByVal msg As String, ByVal defaultResult As String, ByRef result As String)
Public Event wkeNavigationCallback(ByVal webView As Long, ByVal param As Long, ByVal navigationType As wkeNavigationType, ByVal url As String)
Public Event wkeCreateViewCallback(ByVal webView As Long, ByVal param As Long, ByVal navigationType As wkeNavigationType, ByVal url As String, ByRef windowFeatures As wkeWindowFeatures)
Public Event wkeDocumentReadyCallback(ByVal webView As Long, ByVal param As Long)
Public Event wkeDocumentReady2Callback(ByVal webView As Long, ByVal param As Long, ByVal frameId As Long)
Public Event wkeDownloadCallback(ByVal webView As Long, ByVal param As Long, ByVal url As String)
Public Event wkeConsoleCallback(ByVal webView As Long, ByVal param As Long, ByVal level As wkeConsoleLevel, ByVal message As String, ByVal sourceName As String, ByVal sourceLine As Long, ByVal stackTrace As String)
Public Event wkeLoadUrlBeginCallback(ByVal webView As Long, ByVal param As Long, ByVal url As String, ByVal job As Long)
Public Event wkeLoadUrlEndCallback(ByVal webView As Long, ByVal param As Long, ByVal url As String, ByVal job As Long, ByVal buf As Long, ByVal tlen As Long)
Public Event wkeDidCreateScriptContextCallback(ByVal webView As Long, ByVal param As Long, ByVal frameId As Long, ByVal context As Long, ByVal extensionGroup As Long, ByVal worldId As Long)
Public Event wkeWillReleaseScriptContextCallback(ByVal webView As Long, ByVal param As Long, ByVal frameId As Long, ByVal context As Long, ByVal worldId As Long)
Public Event wkeWillMediaLoadCallback(ByVal webView As Long, ByVal param As Long, ByVal url As String, ByRef info As wkeMediaLoadInfo)
Public Event wkeWindowClosingCallback(ByVal webWindow As Long, ByVal param As Long)
Public Event wkeWindowDestroyCallback(ByVal webWindow As Long, ByVal param As Long)

Public wkeNetResponseCallback As Long
Public wkeCallUiThread As Long
Public wkeOnCallUiThread As Long
Public wkeOnNetGetFavicon As Long
Public jsNativeFunction As Long
Public wkeJsNativeFunction As Long
Public wkeTitleChangedCallback As Long
Public wkeURLChangedCallback As Long
Public wkeURLChangedCallback2 As Long
Public wkePaintUpdatedCallback As Long
Public wkePaintBitUpdatedCallback As Long
Public wkeAlertBoxCallback As Long
Public wkeConfirmBoxCallback As Long
Public wkePromptBoxCallback As Long
Public wkeNavigationCallback As Long
Public wkeCreateViewCallback As Long
Public wkeDocumentReadyCallback As Long
Public wkeDocumentReady2Callback As Long
Public wkeDownloadCallback As Long
Public wkeConsoleCallback As Long
Public wkeLoadUrlBeginCallback As Long
Public wkeLoadUrlEndCallback As Long
Public wkeDidCreateScriptContextCallback As Long
Public wkeWillReleaseScriptContextCallback As Long
Public wkeWillMediaLoadCallback As Long
Public wkeWindowClosingCallback As Long
Public wkeWindowDestroyCallback As Long

Private SDLL As cUniversalDLLCalls
Private MiniblinkAPICls As MiniblinkAPI

Private Sub Class_Initialize()
    Set SDLL = New cUniversalDLLCalls
    Set MiniblinkAPICls = New MiniblinkAPI
    
    wkeWindowDestroyCallback = zb_AddressOf(1, 2, 0)
    wkeWindowClosingCallback = zb_AddressOf(2, 2, 1)
    wkeWillMediaLoadCallback = zb_AddressOf(3, 4, 2)
    wkeWillReleaseScriptContextCallback = zb_AddressOf(4, 5, 3)
    wkeDidCreateScriptContextCallback = zb_AddressOf(5, 6, 4)
    wkeLoadUrlEndCallback = zb_AddressOf(6, 6, 5)
    wkeLoadUrlBeginCallback = zb_AddressOf(7, 4, 6)
    wkeConsoleCallback = zb_AddressOf(8, 7, 7)
    wkeDownloadCallback = zb_AddressOf(9, 3, 8)
    wkeDocumentReady2Callback = zb_AddressOf(10, 3, 9)
    wkeDocumentReadyCallback = zb_AddressOf(11, 2, 10)
    wkeCreateViewCallback = zb_AddressOf(12, 5, 11)
    wkeNavigationCallback = zb_AddressOf(13, 4, 12)
    wkePromptBoxCallback = zb_AddressOf(14, 5, 13)
    wkeConfirmBoxCallback = zb_AddressOf(15, 3, 14)
    wkeAlertBoxCallback = zb_AddressOf(16, 3, 15)
    wkePaintBitUpdatedCallback = zb_AddressOf(17, 6, 16)
    wkePaintUpdatedCallback = zb_AddressOf(18, 7, 17)
    wkeURLChangedCallback2 = zb_AddressOf(19, 4, 18)
    wkeURLChangedCallback = zb_AddressOf(20, 3, 19)
    wkeTitleChangedCallback = zb_AddressOf(21, 3, 20)
    wkeJsNativeFunction = zb_AddressOf(22, 2, 21)
    jsNativeFunction = zb_AddressOf(23, 1, 22)
    wkeOnNetGetFavicon = zb_AddressOf(24, 4, 23)
    wkeOnCallUiThread = zb_AddressOf(25, 2, 24)
    wkeCallUiThread = zb_AddressOf(26, 3, 25)
    wkeNetResponseCallback = zb_AddressOf(27, 4, 26)
End Sub

'============================================================================================
' /////////////////// �ص���������ʽת������ \\\\\\\\\\\\\\\\\\\
'============================================================================================

'*************************************************************************************************
'* cCallback - ��ͨ�õĻص�ģ��
'��*
'*ע�⣺
'*Ϊһ�࣬������û��ؼ��Ļص������ʹ�������ȫһ���ġ�
'*�ص������������ʹ�����Թ�ͬ��������������ʹ��롣
'�������������͵Ĵ�����һ���ļ��У���*..
'*ɾ���ظ��������ʹ��룬��Ctrl+ F5�ͻᷢ������Ϊ��
'*Ҫ�ر�ע���nOrdinal������zAddressOf
'��*
'��* Paul_Caton@hotmail.com
'����Ȩ��ѵģ�����Ϊ���ʵ�ʹ�ú����á�
'��*
'*1.0���ԭ........................................... .......................... 20060408
'* v1.1�����thunk��֧��........................................ ................ 20060409
'*1.2�������˿�ѡ��IDE����......................................... ........... 20060411
'* V1.3������һ����ѡ�Ļص�Ŀ�����....................................... .. 20060413
'*************************************************************************************************

'-�ص�����-----------------------------------------------------------------------------------
Private Function zb_AddressOf(ByVal nOrdinal As Long, _
    ByVal nParamCount As Long, _
    Optional ByVal nThunkNo As Long = 0, _
    Optional ByVal oCallback As Object = Nothing, _
    Optional ByVal bIdeSafety As Boolean = True) As Long                        '���ص�ַָ���Ļص���thunk
    '*************************************************************************************************
    '* nOrdinal - �ز���ŵģ������˽�з������1�����ڶ������2���ȵ�..
    '* nParamCount - ���ص��Ĳ���
    '* nThunkNo - ��ѡ��ͬʱ��������ص����ò�ͬ��thunk... ������MAX_THUNKS const�������Ҫͬʱʹ���������ϵ�thunk
    '* oCallback - ��ѡ�������ջص��Ķ������δ���壬�ص������͵������ʵ��
    '* bIdeSafety - ��ѡ������Ϊfalse������IDE������
    '*************************************************************************************************
    Const MAX_FUNKS   As Long = 27                                               'ͬʱ���е�thunk������������ζ��
    Const FUNK_LONGS  As Long = 22                                              '��ͷ����thunk
    Const FUNK_LEN    As Long = FUNK_LONGS * 4                                  'һ��thunk�е��ֽ�
    Const MEM_LEN     As Long = MAX_FUNKS * FUNK_LEN                            '��Ҫ���ڴ��ֽڵĻص���thunk
    Const PAGE_RWX    As Long = &H40&                                           '�����ִ���ڴ�
    Const MEM_COMMIT  As Long = &H1000&                                         '�ύ������ڴ�
    Dim nAddr       As Long
    Dim nOffset     As Long
    Dim z_Cb()      As Long                                                     'Callback thunk array
    
    If nThunkNo < 0 Or nThunkNo > (MAX_FUNKS - 1) Then
        MsgBox "nThunkNo doesn't exist.", vbCritical + vbApplicationModal, "Error in " & TypeName(Me) & ".cb_Callback"
        Exit Function
    End If
    
    If oCallback Is Nothing Then                                                '����û���û��ָ���Ļص�����
        Set oCallback = Me                                                      'Ȼ��������
    End If
    
    nAddr = zAddressOf(oCallback, nOrdinal)                                     '��ȡָ����ŵĻص���ַ
    If nAddr = 0 Then
        MsgBox "Callback address not found.", vbCritical + vbApplicationModal, "Error in " & TypeName(Me) & ".cb_Callback"
        Exit Function
    End If
    
    If z_CbMem = 0 Then                                                         '����ڴ�û�б�����
        ReDim z_Cb(0 To FUNK_LONGS - 1, 0 To MAX_FUNKS - 1) As Long             '����������������
        z_CbMem = VirtualAlloc(z_CbMem, MEM_LEN, MEM_COMMIT, PAGE_RWX)          '�����ִ���ڴ�
        
        If bIdeSafety Then                                                      '����û���ҪIDE����
            z_Cb(2, 0) = GetProcAddress(GetModuleHandleA("vba6"), "EbMode")     'EbMode��ַ
        End If
        z_Cb(3, 0) = GetProcAddress(GetModuleHandleA("kernel32"), "IsBadCodePtr")
        z_Cb(4, 0) = &HBB60E089
        z_Cb(6, 0) = &H73FFC589: z_Cb(7, 0) = &HC53FF04: z_Cb(8, 0) = &H7B831F75: z_Cb(9, 0) = &H20750008: z_Cb(10, 0) = &HE883E889: z_Cb(11, 0) = &HB9905004: z_Cb(13, 0) = &H74FF06E3: z_Cb(14, 0) = &HFAE2008D: z_Cb(15, 0) = &H53FF33FF: z_Cb(16, 0) = &HC2906104: z_Cb(18, 0) = &H830853FF: z_Cb(19, 0) = &HD87401F8: z_Cb(20, 0) = &H4589C031: z_Cb(21, 0) = &HEAEBFC
        
        For nOffset = 1 To MAX_FUNKS - 1                                        ' ÿ��thunk�ģ����ƵĻ�����thunk
            CopyMemory z_Cb(0, nOffset), z_Cb(0, 0), FUNK_LEN
        Next
        CopyMemory ByVal z_CbMem, z_Cb(0, 0), MEM_LEN                           '����thunk�����ִ���ڴ�
    End If
    
    nOffset = z_CbMem + nThunkNo * FUNK_LEN
    CopyMemory ByVal nOffset, ObjPtr(oCallback), 4&                             '���Ƶ����thunk��VMEM��objPtr
    CopyMemory ByVal nOffset + 4, nAddr, 4&                                     '�ص���ַ���Ƶ�VMEM
    CopyMemory ByVal nOffset + 20, nOffset, 4&                                  '���Ƶ�VMEM���thunk�Ŀ�ʼ
    CopyMemory ByVal nOffset + 48, nParamCount, 4&                              '�����Ƶ�VMEM�Ĳ�����
    CopyMemory ByVal nOffset + 68, nParamCount * 4, 4&                          '���Ƶ�VMEM�������ܳ���
    zb_AddressOf = nOffset + 16                                                 '������VMEM����������Ա���Ϊ
    
End Function

'���صĻص�����ĵ�ַָ����ŵķ�����1 =���һ��˽�з�����2=�����ڶ���˽�з�����
Private Function zAddressOf(ByVal oCallback As Object, ByVal nOrdinal As Long) As Long
    Dim bSub  As Byte                                                           '�ļ�ֵ������ϣ���ҵ�һ���麯�����ķ�������ָ����
    Dim bVal  As Byte
    Dim nAddr As Long                                                           '���麯�����ĵ�ַ
    Dim i     As Long                                                           'ѭ������
    Dim j     As Long                                                           'ѭ������
    
    CopyMemory nAddr, ByVal ObjPtr(oCallback), 4                                '��ȡ�ص������ʵ���ĵ�ַ
    If Not zProbe(nAddr + &H1C, i, bSub) Then                                   'һ�෽����̽��
        If Not zProbe(nAddr + &H6F8, i, bSub) Then                              '����ʽ������̽��
            If Not zProbe(nAddr + &H7A4, i, bSub) Then                          '�����û����Ʒ�����̽��
                Exit Function                                                   '����...
            End If
        End If
    End If
    
    i = i + 4                                                                   '��ײ����һ��
    j = i + 1024                                                                '����һ���������޶ȣ�ɨ��256���麯��������Ŀ
    Do While i < j
        CopyMemory nAddr, ByVal i, 4                                            '��ȡ��ַ�洢�����vtable��
        
        If IsBadCodePtr(nAddr) Then                                             '����һ����Ч�Ĵ����ַ��
            CopyMemory zAddressOf, ByVal i - (nOrdinal * 4), 4                  '����ָ�����麯��������ڵ�ַ
            Exit Do                                                             '����ķ���ǩ�����˳�ѭ��
        End If
        
        CopyMemory bVal, ByVal nAddr, 1                                         '�õ����麯������ָ����ֽ�
        If bVal <> bSub Then                                                    '������ֽڲ�ƥ��Ԥ��ֵ...
            CopyMemory zAddressOf, ByVal i - (nOrdinal * 4), 4                  '����ָ�����麯��������ڵ�ַ
            Exit Do                                                             '����ķ���ǩ�����˳�ѭ��
        End If
        
        i = i + 4                                                               '��һ��vtable��
    Loop
End Function

'��ָ������ʼ��ַ���ڷ���ǩ����̽��
Private Function zProbe(ByVal nStart As Long, ByRef nMethod As Long, ByRef bSub As Byte) As Boolean
    Dim bVal    As Byte
    Dim nAddr   As Long
    Dim nLimit  As Long
    Dim nEntry  As Long
    
    nAddr = nStart                                                              '��ʼ��ַ
    nLimit = nAddr + 2560                                                         '�˸���Ŀ��̽
    Do While nAddr < nLimit                                                     '��Ȼ���ǻ�û�дﵽ���ǵ�̽�����
        CopyMemory nEntry, ByVal nAddr, 4                                       'vtable��
        
        If nEntry <> 0 Then                                                     '���û��ʵ�ֽӿ�
            CopyMemory bVal, ByVal nEntry, 1                                    '�õ���ֵ��ָ���vtable��
            If bVal = &H33 Or bVal = &HE9 Then                                  '��鱾����P��ķ���ǩ��
                nMethod = nAddr                                                 '�洢vtable��
                bSub = bVal                                                     '�洢�ҵ��ķ���ǩ��
                zProbe = True                                                   '��ʾ�ɹ�
                Exit Function                                                   '����
            End If
        End If
        
        nAddr = nAddr + 4                                                       '��һ��vtable��
    Loop
End Function

Private Sub zTerminate()
    Const MEM_RELEASE As Long = &H8000&                                         '�ͷŷ�����ڴ��־
    If Not z_CbMem = 0 Then                                                     '����ڴ����
        VirtualFree z_CbMem, 0, MEM_RELEASE
        z_CbMem = 0                                                             '����;��ʾ�ڴ��ͷ�
    End If
End Sub

Private Function WkeNetResponseCallbackPh(ByVal webView As Long, ByVal param As Long, ByVal url As Long, ByVal job As Long) As Long
    RaiseEvent wkeNetResponseCallback(webView, param, SDLL.PointerToStringA(url), job)
    WkeNetResponseCallbackPh = VarPtr(booltoint(Return_wkeNetResponseCallback))
End Function

Private Function WkeCallUiThreadPh(ByVal webView As Long, ByVal func As Long, ByVal param As Long) As Long
    RaiseEvent wkeCallUiThread(webView, func, param)
End Function

Private Function WkeOnCallUiThreadPh(ByVal webView As Long, ByVal paramOnInThread As Long) As Long
    RaiseEvent wkeOnCallUiThread(webView, paramOnInThread)
End Function

Private Function WkeOnNetGetFaviconPh(ByVal webView As Long, ByVal param As Long, ByVal url As Long, ByVal buf As Long) As Long
    Dim t As wkeMemBuf
    CopyMemory2 VarPtr(t), buf, LenB(t)
    RaiseEvent wkeOnNetGetFavicon(webView, param, SDLL.PointerToStringA(url), t)
End Function

Private Function JsNativeFunctionPh(ByVal es As Long) As Long
    RaiseEvent jsNativeFunction(es)
    JsNativeFunctionPh = VarPtr(Return_jsNativeFunction)
End Function

Private Function WkeJsNativeFunctionPh(ByVal es As Long, ByVal param As Long) As Long
    RaiseEvent wkeJsNativeFunction(es, param)
    WkeJsNativeFunctionPh = VarPtr(Return_wkeJsNativeFunction)
End Function

Private Function WkeTitleChangedCallbackPh(ByVal webView As Long, ByVal param As Long, ByVal title As Long) As Long
    RaiseEvent wkeTitleChangedCallback(webView, param, MiniblinkAPICls.wkeGetStringW(title))
End Function

Private Function WkeURLChangedCallbackPh(ByVal webView As Long, ByVal param As String, ByVal url As Long) As Long
    RaiseEvent wkeURLChangedCallback(webView, param, SDLL.PointerToStringA(url))
End Function

Private Function WkeURLChangedCallback2Ph(ByVal webView As Long, ByVal param As Long, ByVal frameId As Long, ByVal url As Long) As Long
    RaiseEvent wkeURLChangedCallback2(webView, param, frameId, SDLL.PointerToStringA(url))
End Function

Private Function WkePaintUpdatedCallbackPh(ByVal webView As Long, ByVal param As Long, ByVal hdc As Long, ByVal x As Long, ByVal y As Long, ByVal cx As Long, ByVal cy As Long) As Long
    RaiseEvent wkePaintUpdatedCallback(webView, param, hdc, x, y, cx, cy)
End Function

Private Function WkePaintBitUpdatedCallbackPh(ByVal webView As Long, ByVal param As Long, ByVal buffer As Long, ByVal r As Long, ByVal width As Long, ByVal height As Long) As Long
    Dim t As wkeRect
    CopyMemory2 VarPtr(t), r, LenB(t)
    RaiseEvent wkePaintBitUpdatedCallback(webView, param, buffer, t, width, height)
End Function

Private Function WkeAlertBoxCallbackPh(ByVal webView As Long, ByVal param As Long, ByVal msg As Long) As Long
    RaiseEvent wkeAlertBoxCallback(webView, param, MiniblinkAPICls.wkeGetStringW(msg))
End Function

Private Function WkeConfirmBoxCallbackPh(ByVal webView As Long, ByVal param As Long, ByVal msg As Long) As Long
    RaiseEvent wkeConfirmBoxCallback(webView, param, MiniblinkAPICls.wkeGetStringW(msg))
    WkeConfirmBoxCallbackPh = VarPtr(booltoint(Return_wkeConfirmBoxCallback))
End Function

Private Function WkePromptBoxCallbackPh(ByVal webView As Long, ByVal param As Long, ByVal msg As Long, ByVal defaultResult As Long, ByVal result As Long) As Long
    Dim tret As String
    RaiseEvent wkePromptBoxCallback(webView, param, MiniblinkAPICls.wkeGetStringW(msg), MiniblinkAPICls.wkeGetStringW(defaultResult), tret)
    MiniblinkAPICls.wkeSetStringW result, tret, LenB(tret)
    WkePromptBoxCallbackPh = VarPtr(booltoint(Return_wkePromptBoxCallback))
End Function

Private Function WkeNavigationCallbackPh(ByVal webView As Long, ByVal param As Long, ByVal navigationType As Long, ByVal url As Long) As Long
    RaiseEvent wkeNavigationCallback(webView, param, navigationType, SDLL.PointerToStringA(url))
    WkeNavigationCallbackPh = VarPtr(booltoint(Return_wkeNavigationCallback))
End Function

Private Function WkeCreateViewCallbackPh(ByVal webView As Long, ByVal param As Long, ByVal navigationType As Long, ByVal url As Long, ByVal windowFeatures As Long) As Long
    Dim t As wkeWindowFeatures
    CopyMemory2 VarPtr(t), windowFeatures, LenB(t)
    RaiseEvent wkeCreateViewCallback(webView, param, navigationType, SDLL.PointerToStringA(url), t)
    WkeCreateViewCallbackPh = VarPtr(Return_wkeCreateViewCallback)
End Function

Private Function WkeDocumentReadyCallbackPh(ByVal webView As Long, ByVal param As Long) As Long
    RaiseEvent wkeDocumentReadyCallback(webView, param)
End Function

Private Function WkeDocumentReady2CallbackPh(ByVal webView As Long, ByVal param As Long, ByVal frameId As Long) As Long
    RaiseEvent wkeDocumentReady2Callback(webView, param, frameId)
End Function

Private Function WkeDownloadCallbackPh(ByVal webView As Long, ByVal param As Long, ByVal url As Long) As Long
    RaiseEvent wkeDownloadCallback(webView, param, SDLL.PointerToStringA(url))
    WkeDownloadCallbackPh = VarPtr(booltoint(Return_wkeDownloadCallback))
End Function

Private Function WkeConsoleCallbackPh(ByVal webView As Long, ByVal param As Long, ByVal level As Long, ByVal message As Long, ByVal sourceName As Long, ByVal sourceLine As Long, ByVal stackTrace As Long) As Long
    RaiseEvent wkeConsoleCallback(webView, param, level, MiniblinkAPICls.wkeGetStringW(message), MiniblinkAPICls.wkeGetStringW(sourceName), sourceLine, MiniblinkAPICls.wkeGetStringW(stackTrace))
End Function

Private Function WkeLoadUrlBeginCallbackPh(ByVal webView As Long, ByVal param As Long, ByVal url As Long, ByVal job As Long) As Long
    RaiseEvent wkeLoadUrlBeginCallback(webView, param, SDLL.PointerToStringA(url), job)
    WkeLoadUrlBeginCallbackPh = VarPtr(booltoint(Return_wkeLoadUrlBeginCallback))
End Function

Private Function WkeLoadUrlEndCallbackPh(ByVal webView As Long, ByVal param As Long, ByVal url As Long, ByVal job As Long, ByVal buf As Long, ByVal tlen As Long) As Long
    RaiseEvent wkeLoadUrlEndCallback(webView, param, SDLL.PointerToStringA(url), job, buf, tlen)
End Function

Private Function WkeDidCreateScriptContextCallbackPh(ByVal webView As Long, ByVal param As Long, ByVal frameId As Long, ByVal context As Long, ByVal extensionGroup As Long, ByVal worldId As Long) As Long
    RaiseEvent wkeDidCreateScriptContextCallback(webView, param, frameId, context, extensionGroup, worldId)
End Function

Private Function WkeWillReleaseScriptContextCallbackPh(ByVal webView As Long, ByVal param As Long, ByVal frameId As Long, ByVal context As Long, ByVal worldId As Long) As Long
    RaiseEvent wkeWillReleaseScriptContextCallback(webView, param, frameId, context, worldId)
End Function

Private Function WkeWillMediaLoadCallbackPh(ByVal webView As Long, ByVal param As Long, ByVal url As Long, ByVal info As Long) As Long
    Dim t As wkeMediaLoadInfo
    CopyMemory2 VarPtr(t), info, LenB(t)
    RaiseEvent wkeWillMediaLoadCallback(webView, param, SDLL.PointerToStringA(url), t)
End Function

Private Function WkeWindowClosingCallbackPh(ByVal webWindow As Long, ByVal param As Long) As Long
    RaiseEvent wkeWindowClosingCallback(webWindow, param)
    WkeWindowClosingCallbackPh = VarPtr(booltoint(Return_wkeWindowClosingCallback))
End Function

Private Function WkeWindowDestroyCallbackPh(ByVal webWindow As Long, ByVal param As Long) As Long
    RaiseEvent wkeWindowDestroyCallback(webWindow, param)
End Function