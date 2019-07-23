VERSION 5.00
Begin VB.UserControl SBrowser 
   Appearance      =   0  'Flat
   BackColor       =   &H80000005&
   ClientHeight    =   3600
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   4800
   ScaleHeight     =   240
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   320
   ToolboxBitmap   =   "SBrowser.ctx":0000
End
Attribute VB_Name = "SBrowser"
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

Private zchwnd As Long, m_WebWindow As Long

Private c_handleDocumentReady_address As Long, c_handleLoadUrlBegin_address As Long, c_JsCall_address As Long
Private c_showNewView_address As Long, c_handleLoadUrlEnd_address As Long

Public Event DocumentReady(ByVal url As String)
Public Event LoadUrlBegin(ByVal title As String, ByVal url As String)
Public Event jsCall(ByVal index As Long, ByVal info As String)
Public Event ShowNewView(ByVal url As String, ByRef ret As Long)
Public Event LoadUrlEnd(ByVal url As String, ByRef data() As Byte)

Private tmp_load_url As String, tmp_load_html As String, tmp_load_filename As String
Private is_qd As Boolean, tmp_TouchEnabled As Boolean, tmp_MouseEnabled As Boolean
Private tmp_job As Long
Private IsInit As Boolean
Private MiniblinkAPICls As MiniblinkAPI
Private SDLL As cUniversalDLLCalls

Private Sub UserControl_Resize()
    If is_qd = True Then
        MiniblinkAPICls.wkeResize m_WebWindow, UserControl.ScaleWidth, UserControl.ScaleHeight
    End If
End Sub

Public Property Get RunMode() As Boolean
    RunMode = CLng(Ambient.UserMode)
    On Error Resume Next
    RunMode = Extender.parent.RunMode
End Property

Private Sub UserControl_Show()
    If RunMode = True And IsInit = False Then
        Set SDLL = New cUniversalDLLCalls
        
        IsInit = True
        tmp_MouseEnabled = True
        
        c_handleDocumentReady_address = zb_AddressOf(1, 2, 0)
        c_handleLoadUrlBegin_address = zb_AddressOf(2, 4, 1)
        c_JsCall_address = zb_AddressOf(3, 2, 2)
        c_showNewView_address = zb_AddressOf(4, 5, 3)
        c_handleLoadUrlEnd_address = zb_AddressOf(5, 6, 4)
        
        zchwnd = UserControl.hWnd
        
        Set MiniblinkAPICls = New MiniblinkAPI

        MiniblinkAPICls.wkeInitializeEx 0
        
        MiniblinkAPICls.wkeJsBindFunction "jsCall", c_JsCall_address, 0, 2
        
        m_WebWindow = MiniblinkAPICls.wkeCreateWebWindow(2, zchwnd, 0, 0, UserControl.ScaleWidth, UserControl.ScaleHeight)
    
        MiniblinkAPICls.wkeShowWindow m_WebWindow, True
    
        MiniblinkAPICls.wkeOnDocumentReady m_WebWindow, c_handleDocumentReady_address, 0
        MiniblinkAPICls.wkeOnLoadUrlBegin m_WebWindow, c_handleLoadUrlBegin_address, 0
        MiniblinkAPICls.wkeOnCreateView m_WebWindow, c_showNewView_address, 0
        MiniblinkAPICls.wkeOnLoadUrlEnd m_WebWindow, c_handleLoadUrlEnd_address, 0
        
        is_qd = True
        
        If tmp_load_url <> "" Then
            LoadURL tmp_load_url
        ElseIf tmp_load_html <> "" Then
            LoadHtml tmp_load_html
        ElseIf tmp_load_filename <> "" Then
            LoadFile tmp_load_filename
        End If
    End If
End Sub

Public Sub LoadURL(ByVal url As String)
    tmp_load_url = url
    If is_qd = True Then
        MiniblinkAPICls.wkeLoadW m_WebWindow, tmp_load_url
    End If
End Sub

Public Sub LoadHtml(ByVal html As String)
    tmp_load_html = html
    If is_qd = True Then
        MiniblinkAPICls.wkeLoadHTMLW m_WebWindow, tmp_load_html
    End If
End Sub

Public Sub LoadFile(ByVal filename As String)
    tmp_load_filename = filename
    If is_qd = True Then
        MiniblinkAPICls.wkeLoadFileW m_WebWindow, tmp_load_filename
    End If
End Sub

Public Function GetWebWindow() As Long
    GetWebWindow = m_WebWindow
End Function

Public Function RunJs(ByVal js As String) As String
    Dim TJsValue As Currency
    TJsValue = MiniblinkAPICls.wkeRunJSW(m_WebWindow, js)
    RunJs = MiniblinkAPICls.jsToTempStringW(GetEs(), TJsValue)
End Function

Public Function GetEs() As Long
    GetEs = MiniblinkAPICls.wkeGlobalExec(m_WebWindow)
End Function

Public Function IsLoadComplete() As Boolean
    IsLoadComplete = MiniblinkAPICls.wkeIsLoadComplete(m_WebWindow)
End Function

Public Function IsDocumentReady() As Boolean
    IsDocumentReady = MiniblinkAPICls.wkeIsDocumentReady(m_WebWindow)
End Function

Public Function SendMouseEvent(ByVal message As Long, ByVal x As Long, ByVal y As Long, ByVal flags As Long) As Boolean
    SendMouseEvent = MiniblinkAPICls.wkeFireMouseEvent(m_WebWindow, message, x, y, flags)
End Function

Public Function SendMouseWheelEvent(ByVal x As Long, ByVal y As Long, ByVal delta As Long, ByVal flags As Long) As Boolean
    SendMouseWheelEvent = MiniblinkAPICls.wkeFireMouseWheelEvent(m_WebWindow, x, y, delta, flags)
End Function

Public Sub NetHookRequest()
    If tmp_job = 0 Then Exit Sub
    MiniblinkAPICls.wkeNetHookRequest tmp_job
End Sub

Public Property Get userAgent() As String
    If is_qd = True Then
        userAgent = MiniblinkAPICls.wkeGetUserAgent(m_WebWindow)
    End If
End Property

Public Property Let userAgent(ByVal data As String)
    If is_qd = True Then
        MiniblinkAPICls.wkeSetUserAgent m_WebWindow, data
    End If
End Property

Public Property Get TouchEnabled() As Boolean
    If is_qd = True Then
        TouchEnabled = tmp_TouchEnabled
    End If
End Property

Public Property Let TouchEnabled(ByVal data As Boolean)
    If is_qd = True Then
        tmp_TouchEnabled = data
        MiniblinkAPICls.wkeSetTouchEnabled m_WebWindow, data
    End If
End Property

Public Property Get MouseEnabled() As Boolean
    If is_qd = True Then
        MouseEnabled = tmp_MouseEnabled
    End If
End Property

Public Property Let MouseEnabled(ByVal data As Boolean)
    If is_qd = True Then
        tmp_MouseEnabled = data
        MiniblinkAPICls.wkeSetMouseEnabled m_WebWindow, data
    End If
End Property

'------------------------------------------------------------------------------
'       ��ʼ������
'------------------------------------------------------------------------------
Private Sub UserControl_InitProperties()
    '
End Sub


'------------------------------------------------------------------------------
'       ��ȡ����
'------------------------------------------------------------------------------
Private Sub UserControl_ReadProperties(PropBag As PropertyBag)
    '
End Sub


'------------------------------------------------------------------------------
'       д������
'------------------------------------------------------------------------------
Private Sub UserControl_WriteProperties(PropBag As PropertyBag)
    '
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
    Const MAX_FUNKS   As Long = 5                                               'ͬʱ���е�thunk������������ζ��
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
    nLimit = nAddr + 32                                                         '�˸���Ŀ��̽
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

Private Function ChandleLoadUrlEnd(ByVal webWindow As Long, ByVal param As Long, ByVal url As Long, ByVal job As Long, ByVal buf As Long, ByVal tlen As Long) As Long
    Dim zc() As Byte
    zc = pGetByteFromPtr(buf, tlen)
    RaiseEvent LoadUrlEnd(SDLL.PointerToStringA(url), zc)
End Function

Private Function ChandleshowNewView(ByVal webWindow As Long, ByVal param As Long, ByVal navigationType As Long, ByVal url As Long, ByVal windowFeatures As Long) As Long
    Dim ret As Long
    ret = 0
    RaiseEvent ShowNewView(SDLL.PointerToStringA(url), ret)
    If ret = 0 Then ret = webWindow
    ChandleshowNewView = ret
End Function

Private Function ChandleJsCall(ByVal es As Long, ByVal param As Long) As Long
    Dim t_index As Currency, t_info As Currency
    t_index = MiniblinkAPICls.jsArg(es, 0)
    t_info = MiniblinkAPICls.jsArg(es, 1)
    RaiseEvent jsCall(Val(MiniblinkAPICls.jsToTempStringW(es, t_index)), MiniblinkAPICls.jsToTempStringW(es, t_info))
End Function

Private Function ChandleLoadUrlBegin(ByVal webWindow As Long, ByVal param As Long, ByVal url As Long, ByVal job As Long) As Long
    RaiseEvent LoadUrlBegin(MiniblinkAPICls.wkeGetTitleW(webWindow), SDLL.PointerToStringA(url))
End Function

Private Function ChandleDocumentReady(ByVal webWindow As Long, ByVal param As Long) As Long
    RaiseEvent DocumentReady(MiniblinkAPICls.wkeGetURL(webWindow))
End Function