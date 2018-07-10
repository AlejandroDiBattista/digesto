Attribute VB_Name = "Normalizar"
Option Compare Text
'Const Raiz = "C:\Users\usuario\Dropbox\limpiar\"
'Const Raiz = "G:\CYB\ordenanzas\"
'Const Raiz = "C:\Users\usuario\Dropbox\limpiar\revisar\nueva\"
'Const Raiz = "C:\Users\usuario\Desktop\limpiar\"
'Const Raiz = "C:\Users\usuario\Dropbox\limpiar\revisar\"
'Const Raiz = "F:\revisar\"
'Const Raiz = "F:\limpiar\"

Const Transcribir = "C:\Users\usuario\Dropbox\transcribir\"
Const Raiz = "C:\Users\Desktop\Documents\GitHub\digesto\"

'Const DestinoPDF = "C:\Users\usuario\Dropbox\pdf\"
'Const DestinoHTM = "C:\Users\usuario\Dropbox\htm\"

Const OrigenDOC = Raiz + "limpias\"
Const DestinoPDF = Raiz + "pdf\"
Const DestinoHTM = Raiz + "html\"

Const Centesimos As String = "|centésimo|duocentésimo|tricentésimo|cuadricentésimo"
Const Decimos    As String = "|décimo|vigésimo|trigésimo|cuadragésimo|quincuagésimo|sexagésimo|septuagésimo|octogésimo|nonagésimo"
Const Unidades   As String = "|primero|segundo|tercero|cuarto|quinto|sexto|séptimo|octavo|noveno"

'[/SANCIONA.*ORDENANZA.?\s*$/i
'[/^(ART.CULO|Art\.).+:\s*(COMUN.QUES|PUBL.QUES).*/i

Function ContarDOCX() As Integer
    origen = Dir(OrigenDOC + "*.docx")
    Do While origen <> ""
      i = i + 1
      DoEvents
      origen = Dir
    Loop
    ContarDOCX = i
End Function

Function Ordenar(datos As Variant)
  Dim i As Long, j As Long
  Dim Temp As String
  For i = LBound(datos) To UBound(datos) - 1
    For j = i + 1 To UBound(datos)
      If UCase(datos(i)) > UCase(datos(j)) Then
        Temp = datos(j)
        datos(j) = datos(i)
        datos(i) = Temp
      End If
    Next j
  Next i
  
  Ordenar = datos
End Function

Function ListarDOCX() As String()
  Dim salida() As String
  Dim n As Integer, i As Integer, origen As String
  
  n = ContarDOCX()
  ReDim salida(1 To n)
  origen = Dir(OrigenDOC + "*.docx")
  Do While origen <> ""
      'Debug.Print origen
      i = i + 1
      salida(i) = origen
      origen = Dir
  Loop
  ListarDOCX = Ordenar(salida)
End Function

Sub x()
    inicio = Time()
    Debug.Print inicio
    For i = 1 To 10000000
    Next
    Debug.Print estimar(inicio, 0.4)
End Sub

Function estimar(ByVal inicio As Date, ByVal porcentaje As Double) As Date
    estimar = inicio + Round(86400# * (Time() - inicio) / porcentaje)
End Function


Sub Limpiar(Optional ByVal desde As Integer = 1, Optional ByVal cantidad As Integer = 2000, Optional ByVal PaginaInicial As Integer = 1, Optional ByVal maximo As Integer = 10)
    Dim n As Integer, i As Integer, inicio As Variant, ultimo As Integer
    inicio = Time(): i = 0: n = 0
    hasta = desde + cantidad
    
    Debug.Print "PROCESANDO... { Desde"; desde; "A"; hasta; "(Max:"; maximo; ") Inicio:"; Time(); "}"
    origen = Dir(Raiz + "*.docx")
    ultimo = hasta
    Do While origen <> ""
        i = i + 1
        If i >= desde And i < hasta And maximo > 0 Then
            n = n + 1
            Abrir origen
            paginas = ActiveDocument.ActiveWindow.Panes(1).Pages.Count
            Debug.Print i; origen; "(" + Str(paginas) + ") -> "
            PaginaInicial = PaginaInicial + paginas
'            If NormalizarNumeros() Then
'              maximo = maximo - 1
              Formato.MetrosCuadrados
              NormalizarDosPuntos
'            Else
'              Cerrar
'            End If
            
            NormalizarSubrayado
            NormalizarAbreviaturas
            NormalizarArticulos
            LimpiarOrtografia
            LimpiarSubrayado
            Formato.Margenes
            LimpiarEspacios
            NormalizarArticulos
            NormalizarSanciona
            NormalizarAnexos
            LimpiarDocumento True
            'Debug.Print
            Cerrar
            DoEvents
            ultimo = i
        End If
        origen = Dir
    Loop
    duracion = Round(86400# * (Time() - inicio), 1)
    escala = 1463# / IIf(n = 0, 1, n)
    Debug.Print "Todo Limpio"; duracion; "s", Round(duracion * escala / 60, 1); "m"
    Debug.Print "Limpiar"; ultimo + 1; ","; cantidad
End Sub

Sub a()
    AnalizarTodo
End Sub

Private Function CompararPatron(ByVal Texto As String, ByVal patron As String) As Boolean
  Dim regEx As New RegExp
  With regEx
    .Global = True
    .MultiLine = True
    .IgnoreCase = True
    .Pattern = patron
    CompararPatron = .Test(Texto)
  End With
End Function

Function AnalizarCierre() As Boolean
    Dim linea As String, origen As String, destino As String, i As Integer
    AnalizarCierre = False
    IrComienzo
    While AvanzarParrafo(False)
      i = i + 1
      
      linea = ParrafoActual()
      'origen = linea
      'destino = origen
      
      '[/^(ART.CULO|Art\.).+:\s*(COMUN.QUES|PUBL.QUES).*/i

      If CompararPatron(linea, "^(ART.CULO|Art\.).+:\s*(COMUN.QUES|PUBL.QUES).*") Then
        Debug.Print i, linea
        AnalizarCierre = True
      End If
    Wend
End Function

Sub AnalizarTodo()
    Dim inicio As Variant, PaginaInicial As Integer, i As Integer, cantidad As Integer
    inicio = Time()
    
    Dim datos As Variant
    datos = ListarDOCX()
    
    cantidad = UBound(datos)
    PaginaInicial = 1
    Debug.Print "ANALIZANDO... { Inicio > "; Time(); "} ("; cantidad; ")"
    
    For i = 1 To cantidad
      origen = datos(i)
      Abrir origen
      paginas = ActiveDocument.ActiveWindow.Panes(1).Pages.Count
      DoEvents
      'Debug.Print , i; origen; Format(i / cantidad, "#0.0%"); " (Hay "; paginas; "paginas) De"; PaginaInicial; "a"; PaginaInicial + paginas - 1
            
      If Not AnalizarCierre() Then
        Debug.Print "ANALIZAR: "; origen
      End If
      Cerrar
      PaginaInicial = PaginaInicial + paginas
      DoEvents
    Next
    duracion = Round(86400# * (Time() - inicio), 1)
    Debug.Print "Todo Exportado. {demora: "; duracion; ", documentos: "; i; ", paginas: "; PaginaInicial; "}"
End Sub

Sub ExportarTodo(Optional ByVal PDF As Boolean = True)
    Dim inicio As Variant, PaginaInicial As Integer, i As Integer, cantidad As Integer
    inicio = Time()
    
    Dim datos As Variant
    datos = ListarDOCX()
    
    cantidad = UBound(datos)
    PaginaInicial = 1
    Debug.Print "EXPORTANDO... { Inicio > "; Time(); "} ("; cantidad; ")"
    
    For i = 1 To cantidad
      origen = datos(i)
      Abrir origen
      paginas = ActiveDocument.ActiveWindow.Panes(1).Pages.Count
      Debug.Print , i; origen; Format(i / cantidad, "#0.0%"); " (Hay "; paginas; "paginas) De"; PaginaInicial; "a"; PaginaInicial + paginas - 1
      If PDF Then
        PonerPiePagina PaginaInicial, "CYB"
        ExportarPDF origen
        SacarPiePagina
      Else
        SacarPiePagina
        ExportarHTM origen
      End If
      Cerrar
      
      PaginaInicial = PaginaInicial + paginas
      DoEvents
    Next
    duracion = Round(86400# * (Time() - inicio), 1)
    Debug.Print "Todo Exportado. {demora: "; duracion; ", documentos: "; i; ", paginas: "; PaginaInicial; "}"
End Sub

Sub Abrir(ByVal origen As String)
    Documents.Open FileName:=OrigenDOC + origen
    ActiveWindow.ActivePane.View.Zoom.Percentage = 100
End Sub

Sub Cerrar()
    ActiveDocument.Save
    ActiveDocument.Close
End Sub

Sub LimpiarDocumento(Optional dejarAbierto As Boolean)
    If True Then
        Formato.Margenes
        AcomodarParrafos
    End If
    
    If True Then
        Formato.Margenes
        AcomodarParrafos
        LimpiarEspacios
        LimpiarParrafosVacios
        LimpiarPuntuacion
        LimpiarOrtografia
        
        LimpiarFechaOrdenanza
        LimpiarVistoConsiderando
        NormalizarSanciona
    End If
    
    If True Then
        Formato.Margenes
        NormalizarArticulos
    End If
    
    If Not dejarAbierto Then
      Cerrar
    End If
End Sub

Sub AcomodarParrafos()
    Selection.WholeStory
    Formato.Normal
End Sub

Sub LimpiarFechaOrdenanza()
    If Verificar(1, "yerba buena") And Verificar(2, "ordenanza") Then
        Dim Fecha As String
        Fecha = NormalizarFecha(linea(1)) + vbCr
        Seleccionar 1
        Selection.Text = Fecha
        Formato.Fecha
        
        Dim Ordenanza As String
        Ordenanza = NormalizarOrdenanza(linea(2)) + vbCr
        Seleccionar 2
        Selection.Text = Ordenanza
        Formato.Ordenanza
        
        Debug.Print "FO ";
    End If
End Sub

Sub ReemplazarPalabra(ByVal origen As String, ByVal destino As String)
    With Selection.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Text = origen
        .Replacement.Text = destino
        .Forward = True
        '.Wrap = wdFindContinue
        .Wrap = wdFindStop
        .Format = False
        .MatchCase = True
        .MatchWholeWord = True
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
        .Execute Replace:=wdReplaceAll
    End With
End Sub

Sub Abreviatura(ByVal origen As String)
  Dim destino As String
  destino = Replace(origen, ". ", ".") + " "
  destino = Replace(destino, ".y ", ". y ")
  Reemplazar nombre, destino
End Sub

Sub NormalizarAbreviaturas()
    Abreviatura "D. N. I."
    Abreviatura "D. E. M."
    Abreviatura "D. I. P. O. S."
    Abreviatura "DI. P. O. S."
    Abreviatura "I. V. A."
    Abreviatura "C. I. S. I."
    Abreviatura "S. R. L."
    Abreviatura "A. A. y B. E."
    Abreviatura "C. O. N. E. T."
    Abreviatura "U. C. R, P. J y M. C. C"
    Abreviatura "H. C. D."
    Abreviatura "S. O. S. P."
    Abreviatura "PRO. CRE. AR."
    Abreviatura "C. O. U."
    Abreviatura "E. D. E. T."
    Abreviatura "D. I. A. T. N."
    Abreviatura "U. E."
    Abreviatura "C. O. U."
    Reemplazar "  ", " "
End Sub

Sub LimpiarOrtografia()
    Reemplazar "O R D E N A N Z A", "ORDENANZA", ""
    Reemplazar "A N E X O", "ANEXO ", ""
    Reemplazar "C O N V E N I O", "CONVENIO", ""
    Reemplazar "D. N. I. ", "D.N.I.", ""
    Reemplazar "D. E. M. ", "D.E.M.", ""
    Reemplazar "D. I. P. O. S.", "D.I.P.O.S."
    Reemplazar "I. V. A. ", "I.V.A.", ""
    Reemplazar "C. I. S. I.", "C.I.S.I."
    Reemplazar "S. R. L.", "S.R.L."
    Reemplazar "preVISTO", "previsto", ""
    Reemplazar " VISTO ", " visto ", ""
    Reemplazar " CONSIDERANDO ", " considerando ", ""
    Reemplazar "CONSIDERANDOlo", "considerandolo", ""
    
    ReemplazarPalabra "MUNICIOAL", "MUNICIPAL"
    ReemplazarPalabra "COMINIQUESE", "COMUNIQUESE"
    ReemplazarPalabra "Articulo", "Artículo"
    ReemplazarPalabra "ARTICULO", "ARTÍCULO"
    ReemplazarPalabra "CON?EJO", "CONCEJO"
End Sub

Sub LimpiarEspacios()
    Reemplazar "    ", " ", "A"
    Reemplazar "  ", " ", "B"
    Reemplazar "^p^t", "^p", "B1"
    Reemplazar "^p ", "^p", "B2"
    Reemplazar "----", "-", "C"
    Reemplazar "--", "-", "D"
    Reemplazar "-^p", "^p", "E"
    Reemplazar "- ^p", "^p", "F"
    Reemplazar " -^p", "^p", "G"
    Reemplazar " ^p", "^p", "H"
    Reemplazar "..^p", ".^p", "I"
    Reemplazar ".-^p", ".^p", "I"
    Reemplazar "^t^p", "^p", "J"
End Sub

Sub LimpiarSeccion(ByVal seccion As String)
    seccion = UCase(Trim(seccion))
    Reemplazar seccion + " :", seccion + ":", "V0"
    seccion = seccion + ":"
    
    Reemplazar "^t" + seccion, seccion, "V1"
    Reemplazar seccion + " ", seccion, "V2"
    Reemplazar seccion + "^t", seccion, "V3"
    Reemplazar seccion + " ", seccion, "V4"
    Reemplazar seccion + vbCr, seccion, "V5"
    Reemplazar seccion, seccion + " ", "V6", , 1
    
    If Buscar(seccion) Then
        If Not EsLinea(seccion) Then
            Reemplazar seccion, seccion + "^p", "V1", , 1
        End If
        If Buscar(seccion) Then
            FormatoSeccion
        End If
    End If

End Sub

Sub EspaciarSigno(ByVal signo As String)
    Reemplazar " " + signo, signo, signo
    Reemplazar signo + " ", signo, signo
    Reemplazar signo, signo + " ", signo, , 1
End Sub

Sub LimpiarPuntuacion()
    EspaciarSigno ";"
    EspaciarSigno ":"
    EspaciarSigno ","
    EspaciarSigno "."
    EspaciarSigno "º"
    
    Reemplazar "( ", "(", "("
    Reemplazar "(", " (", "(", , 1
    
    Reemplazar " )", ") ", ")"
    Reemplazar ")", ") ", ")", , 1
End Sub

Function LimpiarArticulo(ByVal Articulo As String, Optional ByVal pre As String, Optional ByVal pos As String) As Boolean
    pre = IIf(pre = "", "ARTÍCULO", pre)
    Articulo = UCase(Articulo)
    origen = pre + " " + Articulo + IIf(pos = "", "", pos + " ") + ": "
    origen = Replace(origen, "Á", "?")
    origen = Replace(origen, "É", "?")
    origen = Replace(origen, "Í", "?")
    origen = Replace(origen, "Ó", "?")
    origen = Replace(origen, "Ú", "?")
    
    destino = "ARTÍCULO " + Articulo + ":"
   
    Reemplazar "^t" + origen, destino, "V1", True
    Reemplazar origen + " ", destino, "V2", True
    Reemplazar origen + "^t", destino, "V3", True
    Reemplazar origen + vbCr, destino, "V5", True
    LimpiarArticulo = Buscar(destino)
End Function

Sub LimpiarArticulos(Articulos, Optional ByVal pre As String, Optional ByVal pos As String)
    Articulos = Split(Articulos, ",")
    Dim a As Integer
    For a = 0 To UBound(Articulos)
        If LimpiarArticulo(Articulos(a), pre, pos) Then
            Formato.Articulo
        Else
            Exit For
        End If
    Next
End Sub

Sub LimpiarVistoConsiderando()
    LimpiarSeccion "VISTO"
    LimpiarSeccion "CONSIDERANDO"
    
    LimpiarArticulos "primero,segundo,tercero,cuarto,quinto,sexto,septimo,octavo,noveno,décimo,décimo primero,décimo segundo,décimo tercero,décimo cuarto,décimo quinto,décimo séxto,décimo séptimo,décimo octavo,décimo noveno"
    LimpiarArticulos "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20", , "º"
    LimpiarArticulos "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20", "Art.", "º"
    LimpiarArticulos "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20", "Art."
    
    LimpiarSubrayado
End Sub

Sub LimpiarSubtitulo()
    If Verificar(1, "yerba buena") And Verificar(2, "ordenanza") And Verificar(3, "yerba buena") And Verificar(4, "visto") Then
        Borrar 3
        Debug.Print "ST";
    End If
End Sub

Function Generalizar(ByVal Texto As String) As String
    Texto = UCase(Texto)
    Texto = Replace(Texto, "*", "?{1,50}")
    Texto = Replace(Texto, " ", "?")
    Generalizar = Texto
End Function

Sub Reemplazar(ByVal origen As String, ByVal destino As String, Optional ByVal id As String, Optional ByVal comodin As Boolean, Optional ByVal intentos As Integer)
    For i = 1 To IIf(intentos <= 0, 20, intentos)
        Selection.HomeKey Unit:=wdStory
        With Selection.Find
            .Text = origen
            .Replacement.Text = destino
            
            .ClearFormatting
            .Forward = True
            .Wrap = wdFindContinue
            
            .Format = False
            .MatchCase = False
            .MatchWholeWord = False
            .MatchAllWordForms = False
            .MatchSoundsLike = False
            .MatchWildcards = comodin
            
            .Execute Replace:=wdReplaceAll
            If .Found Then
                Debug.Print id;
            Else
                'Debug.Print ":(";
                Exit For
            End If
        End With
    Next
End Sub

Function PrimerParrafoVacio() As Boolean
    PrimerParrafoVacio = Left(linea(1), 1) = vbCr
End Function

Function UltimoParrafoVacio() As Boolean
    Selection.EndKey Unit:=wdStory
    Selection.MoveLeft Unit:=wdCharacter, Count:=1
    Selection.MoveRight Unit:=wdCharacter, Count:=2, Extend:=wdExtend
    Texto = Selection.Text
    UltimoParrafoVacio = Mid(Texto, 1, 1) = vbCr And Mid(Texto, 2, 1) = vbCr
End Function

Sub BorrarPrimerParrafo()
    Selection.HomeKey Unit:=wdStory
    Selection.MoveRight Unit:=wdCharacter, Count:=1, Extend:=wdExtend
    Selection.Delete Unit:=wdCharacter, Count:=1
End Sub

Sub BorrarUltimoParrafo()
    Selection.EndKey Unit:=wdStory
    Selection.MoveLeft Unit:=wdCharacter, Count:=1
    Selection.MoveRight Unit:=wdCharacter, Count:=2, Extend:=wdExtend
    Selection.Delete Unit:=wdCharacter, Count:=1
End Sub

Sub LimpiarParrafosVacios()
    While PrimerParrafoVacio()
        BorrarPrimerParrafo
    Wend
    While UltimoParrafoVacio()
        BorrarUltimoParrafo
    Wend
    Reemplazar "^p^p", vbCr, "L"
    Reemplazar Chr(13) + Chr(13), vbCr, "X"
End Sub

Function Simplificar(ByVal Texto As String, ByVal padron As String) As String
    Dim C As String, salida As String
    For i = 1 To Len(Texto)
        C = Mid(Texto, i, 1)
        If C Like padron Then
           salida = salida + C
        End If
    Next
    Simplificar = salida
End Function

Function Extraer(ByVal Texto As String, ByVal padron As String) As String
    Dim C As String, salida As String
    Texto = AllTrim(Texto)
    For i = 1 To Len(Texto)
        C = Mid(Texto, i, 1)
        If C Like padron Then
           salida = salida + C
        Else
          Exit For
        End If
    Next
    Extraer = salida
End Function

Function SimplificarFecha(ByVal Texto As String) As String
    Dim C As String
    Texto = UCase(Texto)
    Texto = Replace(Texto, "YERBA BUENA", "")
    Texto = Replace(Texto, " DE ", " ")
    Texto = Replace(Texto, " DEL ", " ")
    Texto = Replace(Texto, " SET", " SEPT")
    numero = Texto Like "#*"
    salida = ""
    For i = 1 To Len(Texto)
        C = Mid(Texto, i, 1)
        If C Like "[0-9a-zA-Z]" Then
            If numero = (C Like "#") Then
                salida = salida + C
            Else
                salida = salida + " " + C
                numero = Not numero
            End If
        End If
    Next
    SimplificarFecha = Trim(salida)
End Function

Function NormalizarFecha(ByVal Texto As String) As String
    meses = Split("Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre", ",")
    lista = Split(SimplificarFecha(Texto), " ")
    If UBound(lista) = 2 Then
        dia = lista(0)
        mes = Left(lista(1), 3)
        anio = lista(2)
        For m = LBound(meses) To UBound(meses)
            aux = UCase(Left(meses(m), 3))
            If mes = aux Then
                mes = meses(m)
            End If
        Next
        If Len(anio) = 1 Then
            anio = "200" + anio
        End If
        If Len(anio) = 2 Then
            If anio Like "[01]" Then
                anio = "20" + anio
            Else
                anio = "19" + anio
            End If
        End If
        If Len(dia) = 1 Then
            dia = "0" + dia
        End If
        NormalizarFecha = "Yerba Buena, " + dia + " de " + mes + " de " + anio
    Else
        NormalizarFecha = "ERROR | " + Texto
    End If
End Function

Function NormalizarOrdenanza(ByVal Texto As String) As String
    Dim C As String
    salida = ""
    For i = 1 To Len(Texto)
        C = Mid(Texto, i, 1)
        If C = "/" Then
            Exit For
        End If
        If ((salida = "") And (C Like "[1-9]")) Or ((salida <> "") And (C Like "[0-9]")) Then
           salida = salida + C
        End If
    Next
    NormalizarOrdenanza = "ORDENANZA Nº " + salida
End Function

Function Buscar(ByVal Texto As String, Optional ByVal comodin As Boolean) As Boolean
    Selection.HomeKey Unit:=wdStory
    With Selection.Find
        .Text = Texto
        .MatchWildcards = comodin
        
        .Forward = True
        .Wrap = wdFindContinue
        .Format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
        .Execute
        Buscar = .Found
    End With
End Function

Function NormalizarSanciona() As Boolean
    NormalizarSanciona = True
    
'   Reemplazar "^ppor ello^p", "^p", "", 1
    Reemplazar "CONSEJO DELIBERANTE SANCIONA", "CONCEJO DELIBERANTE SANCIONA", "S0", False, 1
    
    CDFO0 = "EL CONCEJO DELIBERANTE SANCIONA CON FUERZA DE ORDENANZA"
    CDFO1 = "POR EL CONCEJO DELIBERANTE SANCIONA CON FUERZA DE ORDENANZA"
    CDFO2 = "POR ELLO: EL CONCEJO DELIBERANTE SANCIONA CON FUERZA DE ORDENANZA"
    CDFO3 = "EL HONORABLE CONCEJO DELIBERANTE SANCIONA CON FUERZA DE ORDENANZA"
    
    Reemplazar Generalizar(CDFO0), CDFO0, "S1", True, 1
    Reemplazar Generalizar(CDFO1), CDFO0, "S2", True, 1
    Reemplazar Generalizar(CDFO2), CDFO0, "S3", True, 1
    Reemplazar Generalizar(CDFO3), CDFO0, "S4", True, 1
    
    If Buscar(CDFO0) Then
        Formato.Sanciona
        Exit Function
    End If

    IMSFO = "EL INTENDENTE MUNICIPAL SANCIONA Y PROMULGA CON FUERZA DE ORDENANZA"
    Reemplazar Generalizar(IMSFO), IMSFO, "IMS0", True, 1
    If Buscar(IMSFO) Then
        Formato.Sanciona
        Exit Function
    End If
    
    EISFO0 = "EL INTERVENTOR MUNICIPAL SANCIONA CON FUERZA DE ORDENANZA"
    EISFO1 = "EL INTERVENTOR MUNICIPAL SANCIONA Y PROMULGA CON FUERZA DE ORDENANZA"
    EISFO2 = "EL INTERVENTOR MUNICIPAL SANCIONA Y PROMULGASE CON FUERZA DE ORDENANZA"
    EISFO3 = "EL COMISIONADO INTERVENTOR DE LA MUNICIPALIDAD DE YERBA BUENA SANCIONA Y PROMULGA CON FUERZA DE ORDENANZA"
    
    Reemplazar Generalizar(EISFO0), EISFO0, "IS0", True, 1
    Reemplazar Generalizar(EISFO1), EISFO0, "IS1", True, 1
    Reemplazar Generalizar(EISFO2), EISFO0, "IS2", True, 1
    Reemplazar Generalizar(EISFO3), EISFO0, "IS3", True, 1
    If Buscar(EISFO0) Then
        Formato.Sanciona
        Exit Function
    End If
    
    NormalizarSanciona = False
End Function

Sub Seleccionar(ByVal linea As Integer)
    Selection.GoTo What:=wdGoToLine, Which:=wdGoToFirst, Count:=linea
    Selection.EndKey Unit:=wdLine, Extend:=wdExtend
End Sub

Function linea(ByVal n As Integer) As String
    Seleccionar n
    linea = Selection.Text
End Function

Sub Borrar(linea As Integer)
    Seleccionar linea
    Selection.Delete
End Sub

Function Verificar(ByVal linea As Integer, patron As String) As Boolean
    Seleccionar linea
    Texto = UCase(Selection.Text)
    Verificar = Texto Like "*" + Replace(UCase(patron), " ", "*") + "*"
End Function

Sub LimpiarSubrayado()
    With Selection.Find
        .ClearFormatting
        .Font.Underline = wdUnderlineSingle
        .Replacement.ClearFormatting
        .Replacement.Font.Underline = wdUnderlineNone
        .Text = ": "
        .Replacement.Text = ": "
        .Forward = True
        .Wrap = wdFindContinue
        .Format = True
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
        .Execute Replace:=wdReplaceAll
    End With
End Sub

Function Parrafo(Optional ByVal cantidad As Integer) As String
    Selection.EscapeKey
    Selection.MoveUp Unit:=wdParagraph, Count:=1
    Selection.MoveDown Unit:=wdParagraph, Count:=IIf(cantidad > 0, cantidad, 1), Extend:=wdExtend
    Parrafo = Selection.Text
End Function

Sub SeleccionarParrafo()
    Selection.EndKey Unit:=wdLine
    Selection.MoveUp Unit:=wdParagraph, Count:=1
    Selection.MoveDown Unit:=wdParagraph, Count:=1, Extend:=wdExtend
End Sub

Function EsOrdenanzaEstandar() As Boolean
    EsOrdenanzaEstandar = False
    If Buscar("visto: ") Then
        If Buscar("considerando: ") Then
            If Buscar("EL CONCEJO DELIBERANTE SANCIONA CON FUERZA DE ORDENANZA") Then
                EsOrdenanzaEstandar = True
            End If
        End If
    End If
End Function

Function EsLinea(ByVal Texto As String) As Boolean
    Dim linea As String
    SeleccionarParrafo
    linea = Selection.Text
    linea = Simplificar(UCase(linea), "[A-Z0-9ÁÉÍÓÚ:]")
    Texto = Simplificar(UCase(Texto), "[A-Z0-9ÁÉÍÓÚ:]")
    EsLinea = linea = Texto
End Function

''
Private Sub IrComienzo()
    Selection.EscapeKey
    Selection.HomeKey Unit:=wdStory
    Selection.HomeKey Unit:=wdLine
    Selection.EndKey Unit:=wdLine, Extend:=wdExtend
End Sub

Private Function EsEOF() As Boolean
    EsEOF = Selection.Bookmarks.Exists("\EndOfDoc")
End Function

Function AvanzarParrafo(Optional ByVal sinArticulo As Boolean = False) As Boolean
    Selection.MoveRight Unit:=wdCharacter, Count:=1
    'Selection.MoveDown Unit:=wdParagraph, Count:=1, Extend:=wdExtend
    Selection.EndOf Unit:=wdParagraph, Extend:=wdExtend
    
    Dim linea As String
    linea = ParrafoActual()
    If sinArticulo Then ExcluirArticulo
'    AvanzarParrafo = (Len(linea) > 0) And Not ((linea Like "ANEXO*") Or (linea Like "LIBRO *"))
    AvanzarParrafo = Not (Len(linea) = 0 And EsEOF())
End Function

Private Function ParrafoActual() As String
    Dim linea As String
    linea = Selection.Text
    linea = Replace(linea, Chr(13), "")
    ParrafoActual = Trim(linea)
End Function

Private Sub ReemplazarParrafoActual(ByVal nuevo As String)
  Selection.MoveLeft Unit:=wdCharacter, Count:=1, Extend:=wdExtend
  Selection.Text = nuevo
  Selection.MoveRight Unit:=wdCharacter, Count:=1, Extend:=wdExtend
End Sub

Function ExtraerArticulo(ByVal linea As String) As String
  linea = AllTrim(UCase(linea))
  If linea Like "ART?CULO?*" Then
    linea = Mid(linea, 10, 100)
    If linea Like "#*" Then
      linea = Extraer(linea, "[0-9]")
    Else
      If linea Like "*:*" Then
        linea = Split(linea, ":")(0)
      Else
        linea = ""
      End If
    End If
  Else
    linea = ""
  End If
  ExtraerArticulo = linea
End Function

Sub C()
  Abrir "2099.docx"
  
End Sub

Sub MostrarArticulos(ByRef Articulos As Scripting.Dictionary)
  Dim i As Integer, k As String
  Debug.Print "LISTADO DE ARTICULOS ("; Articulos.Count; ")"
  For i = 0 To Articulos.Count - 1
    k = Articulos.Keys(i)
    Debug.Print "  "; i + 1, k, Articulos.Item(k)
  Next
End Sub

Function ExtraerArticulos(ByRef Articulos As Scripting.Dictionary) As Integer
    Dim Articulo As String
    
    ExtraerArticulos = False
    IrComienzo
    While AvanzarParrafo()
        Articulo = ExtraerArticulo(ParrafoActual())
        If Len(Articulo) > 0 And Not Articulo Like "[0-9]*" Then
          If Articulos.Exists(Articulo) Then
            Articulos.Item(Articulo) = Articulos.Item(Articulo) + 1
          Else
            ExtraerArticulos = True
            Debug.Print " -> "; Articulo
            Articulos.Add Articulo, 1
          End If
        End If
    Wend
End Function

Function HayArticulosConError() As Boolean
    Dim linea As String
    Dim palabras As Variant
    Dim Articulo As String
    
    HayArticulosConError = False
    IrComienzo
    While AvanzarParrafo()
        linea = ParrafoActual()
        linea = Replace(linea, Chr(160), " ")
        If linea Like "ART?CULO *" Then
            If linea Like "ART?CULO *:*" Or linea Like "ART?CULO #*" Then
              'articulo = "|" + Split(linea, ":")(0)
              'articulo = Replace(articulo, "|Articulo ", "")
              'articulo = Replace(articulo, "|Artículo ", "")
              'Debug.Print articulo
            Else
              HayArticulosConError = True
              'Debug.Print ">>>"; Left(linea, 30), Left(NormalizarArticulo(linea), 30)
              ' ERROR
            End If
        End If
    Wend
End Function

Function ContarArticulos() As Integer
    Dim n As Integer
    IrComienzo
    While AvanzarParrafo()
        If ParrafoActual() Like "ART?CULO?*" Then
            n = n + 1
        End If
    Wend
    ContarArticulos = n
End Function

Function ReemplazarArticulo(ByVal origen As String, ByVal destino As String) As Boolean
    
    With Selection.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Text = origen
        .Replacement.Text = destino
        .Forward = True
        .Wrap = wdFindContinue
        .Format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchAllWordForms = False
        .MatchSoundsLike = False
        .MatchWildcards = True
        '.Execute
        
        .Execute
        If .Found Then
          Formato.Normal
          .Execute Replace:=wdReplaceAll
          .Text = Replace(destino, ": ", "")
          .Execute
          Formato.Articulo
        End If
        ReemplazarArticulo = .Found
    End With
End Function

Function ConvertirArticulo(ByVal n As Integer) As Boolean
    Dim origen As String, destino As String
    
    origen = "ARTÍCULO " + UCase(ConvertirLetra(n)) + ":"
    destino = Replace(origen, " ", Chr(160))
    
    origen = Replace(origen, "Á", "?")
    origen = Replace(origen, "É", "?")
    origen = Replace(origen, "Í", "?")
    origen = Replace(origen, "Ó", "?")
    origen = Replace(origen, "Ú", "?")
    origen = Replace(origen, " ", "?")
    
    If Not ReemplazarArticulo(origen, destino) Then
      origen = "ART?CULO?" + Trim(Str(n)) + ":"
      ReemplazarArticulo origen, destino
    End If
    
    If Buscar(destino) Then
      Formato.Articulo
    End If
End Function

Function ConvertirLetra(ByVal n As Integer) As String
    Dim C As Integer, d As Integer, u As Integer
    C = n \ 100 Mod 10: d = n \ 10 Mod 10: u = n \ 1 Mod 10
    
    cc = Split(Centesimos, "|")
    dd = Split(Decimos, "|")
    uu = Split(Unidades, "|")
    
    ConvertirLetra = AllTrim(Replace(cc(C) + " " + dd(d) + " " + uu(u), "  ", " "))
    'Debug.Print c, d, u, "=>", "{" + ConvertirLetra + "}"
End Function

Function LeftPad(ByVal Texto As String, ByVal cantidad As Integer) As String
    LeftPad = Right(String(cantidad, " ") + Texto, cantidad)
End Function

Function RightPad(ByVal Texto As String, ByVal cantidad As Integer) As String
    RightPad = Left(Texto + String(cantidad, " "), cantidad)
End Function

Sub NormalizarArticulos()
    Dim linea As String, origen As String, destino As String
    Dim i As Integer
    'IrComienzo
    
    i = 0
    While AvanzarParrafo()
      linea = ParrafoActual()
      If linea Like "ART?CULO?*" Then
        NormalizarArticulo linea, origen, destino
        ReemplazarArticulo origen, destino
        i = i + 1
        Debug.Print , i, LeftPad(Trim(origen), 40) + " > " + RightPad(destino, 40)
      End If
    Wend
    Debug.Print "NormalizarArticulos"
End Sub

Function NormalizarAnexos() As Boolean
    Dim linea As String, palabras As Variant
    
    NormalizarAnexos = False
    IrComienzo
    While AvanzarParrafo()
        linea = Simplificar(UCase(Left(ParrafoActual(), 20)), "[a-z0-9 ]")
        If linea Like "ANEXO *" Then
            Formato.Anexo
            NormalizarAnexos = True
            'Debug.Print Left(linea, 30), Left(NormalizarArticulo(linea), 30)
        End If
    Wend
End Function

Private Function AllTrim(ByVal Texto As String) As String
  Texto = Trim(Texto)
  Texto = Replace(Texto, Chr(160), " ")
  While Texto Like "*  *"
    Texto = Replace(Texto, "  ", " ")
  Wend
  AllTrim = Texto
End Function

Private Sub separar(ByVal Texto As String, ByVal separador As String, ByRef antes As String, ByRef despues As String)
  Dim separado As Boolean, separando As Boolean, actual As String, i As Integer
  
  antes = "": despues = ""
  
  For i = 1 To Len(Texto)
    actual = Mid(Texto, i, 1)
    If (separando And actual = " ") Or Not separado And (actual Like separador) Then
      separando = True
      separado = True
    Else
      separando = False
      If separado Then
        despues = despues + actual
      Else
        antes = antes + actual
      End If
    End If
  Next
End Sub

Private Sub NormalizarArticulo(ByVal Texto As String, ByRef origen As String, ByRef destino As String)
  Dim cabeza As String, cola As String, Articulo As String
  
  separar Texto, "[:ºª;).]", cabeza, cola
    
  Articulo = UCase(AllTrim(cabeza)) + " "
  Articulo = Replace(Articulo, "ARTICULO", "ARTÍCULO")
  Articulo = Replace(Articulo, "DECIMO", "DÉCIMO")
  Articulo = Replace(Articulo, "ESIMO ", "ÉSIMO ")
  Articulo = Replace(Articulo, "OCTAGÉSIMO", "OCTOGÉSIMO")
  Articulo = Replace(Articulo, " SEPTI", " SÉPTI")
  
  If Articulo Like "ARTÍCULO?#*" Then
    Articulo = "ARTÍCULO " + Extraer(Mid(Articulo, 9), "[0-9]")
  End If
  
  origen = Mid(Texto, 1, Len(Texto) - Len(cola))
  
  Articulo = Replace(AllTrim(Articulo), " ", Chr(160))
  destino = Articulo + ": "
End Sub


' Terminar de normalizar los articulos
'  Reemplazar los articulos que esten antes de los anexos y que comienzen el renglon.
'  Si es numerico debe pasar a "ARTÍCULO 3: "
'  Si es en letras debe pasar a "ARTÍCULO DÉCIMO TERCERO: "

Private Function ConvertirDiccionario(ByVal Texto As String) As Scripting.Dictionary
  Dim d As New Scripting.Dictionary
  d.CompareMode = DatabaseCompare
  Texto = UCase(AllTrim(Texto))
  Texto = Replace(Texto, "Á", "A")
  Texto = Replace(Texto, "É", "E")
  Texto = Replace(Texto, "Í", "I")
  Texto = Replace(Texto, "Ó", "O")
  Texto = Replace(Texto, "Ú", "U")
  Dim l As String
  For i = 1 To Len(Texto)
    l = Mid(Texto, i, 1)
    If Not d.Exists(l) Then d.Add l, True
  Next
'  For i = 1 To Len(texto) - 1
'    l = Mid(texto, i, 2)
'    If Not d.Exists(l) Then d.Add l, True
'  Next
  Set ConvertirDiccionario = d
End Function

Private Function CompararDiccionarios(ByVal a As Scripting.Dictionary, ByVal b As Scripting.Dictionary) As Double
  Dim cuenta As Integer
  For Each k In a.Keys
    If b.Exists(k) Then cuenta = cuenta + 1
  Next
  For Each k In b.Keys
    If a.Exists(k) Then cuenta = cuenta + 1
  Next
  CompararDiccionarios = cuenta / (a.Count + b.Count)
End Function

Function Comparar(ByVal a As String, ByVal b As String) As Double
  Dim da As Scripting.Dictionary
  Dim db As Scripting.Dictionary
  Set da = ConvertirDiccionario(a)
  Set db = ConvertirDiccionario(b)
  Comparar = CompararDiccionarios(da, db)
End Function

Sub b(a, b)
  Debug.Print a + " <=> " + b, Comparar(a, b)
End Sub

Sub Ubicar(ByVal Texto As String)
  Dim palabras As Variant
  palabras = Split(Texto, " ")
  Dim p As Variant
  Debug.Print
  For Each p In Split(Centesimos, "|")
    b palabras(0), p
  Next
  Debug.Print
  For Each p In Split(Decimos, "|")
    b palabras(0), p
  Next
  Debug.Print
  For Each p In Split(Unidades, "|")
    b palabras(0), p
  Next
End Sub

Sub Continuar()
  Limpiar 870, 2000
End Sub
Function NormalizarDinero(ByVal origen As String, ByRef destino As String) As Boolean
  destino = origen
  
  'Normalizar Signo
  destino = Sustituir(destino, "\$a\.?\s*(\d+)", "$$A$1")
  destino = Sustituir(destino, "\$\s*(\d+)", "$$$1")
  
  'Normalizar centavos
  destino = Sustituir(destino, "(\$a?)([0-9.]+),(\d{0,})", "$1$2,$300")
  destino = Sustituir(destino, "(\$a?)([0-9.]+),(\d{2})(\d{0,})", "$1$2,$3")
  
  'Normalizar Separadores Miles
  destino = Sustituir(destino, "(\$a?)(\d{1,3})\.?(\d{3})\.?(\d{3})(\D)", "$1$2.$3.$4$5")
  destino = Sustituir(destino, "(\$a?)(\d{1,3})\.?(\d{3})(\D)", "$1$2.$3$4")
  
  NormalizarDinero = Not origen = destino
End Function

Function NormalizarMetros(ByVal origen As String, ByRef destino As String) As Boolean
    destino = origen
    
    'Normaliza a 2 decimales
    destino = Sustituir(destino, "(\D?)\s*(\d{1,3})\.?\s?(\d{3}|)\.?\s?(\d{3}|)(\d{1,7}|),?\s?(\d*)\s?(metros2|metros cuadrados|metros|m2$|m2\.?|mts2\.?|mts\.?|mt|m\.|m$|m[^a-z]\.?)\s*(\D|;|,|:)", "$1 $2$3$4$5,$600$7 $8")
    destino = Sustituir(destino, "(\D?)\s*(\d{1,}),(\d{2})(\d*)(m2$|m2\.?|mts2\.?|metros2|metros cuadrados|metros|mts\.?|mt|m\.|m$|m[^a-z]\.?)\s*(\D|;|,|:)", "$1 $2,$3$5 $6")
    
    'Normalizar a mts|mts2
    destino = Sustituir(destino, "(\d{1,}),(\d{2})(m2$|m2\.?|mts2\.?|metros2|metros cuadrados|$) ", "$1,$2mts2 ")
    destino = Sustituir(destino, "(\d{1,}),(\d{2})(m$|metros|mts\.?|mt|m\.|m[^a-z]\.?|$) ", "$1,$2mts ")
      
    'Normalizar separadores de mil
    destino = Sustituir(destino, "(\d{1,3})(\d{3}),(\d{2})mts", "$1.$2,$3mts")
    destino = Sustituir(destino, "(\d{1,3})(\d{3})(\d{3}),(\d{2})mts", "$1.$2.$3,$4mts")
    destino = Sustituir(destino, "\s+", " ")
    destino = Sustituir(destino, "\s+([.;,:])", "$1")
    destino = Sustituir(destino, "\(\s*", "(")
    destino = Sustituir(destino, "\s*\)", ")")
    NormalizarMetros = Not origen = destino
End Function

Function Sustituir(ByVal Texto As String, ByVal patron As String, ByVal nuevo As String) As String
  Dim regEx As New RegExp
 
  With regEx
    .Global = True
    .MultiLine = True
    .IgnoreCase = True
    .Pattern = patron
    Sustituir = .Replace(Texto, nuevo)
'    Debug.Print Sustituir
  End With
End Function

Private Function RR(ByVal patron As String, ByVal nuevo As String, ByVal origen As String, ByRef destino As String) As Boolean
  Dim regEx As New RegExp
 
  With regEx
    .Global = True
    .MultiLine = True
    .IgnoreCase = True
    .Pattern = patron
  
    If .Test(origen) Then
      destino = .Replace(origen, nuevo)
      RR = True
    End If
  End With
End Function

Function NormalizarNroLey(ByVal origen As String, ByRef destino As String) As Boolean
    Const salida As String = "Ley Nº $1$2$3"
    NormalizarNroLey = True
    If RR("Ley Nº?\s*(\d{0,3})\.?\s*(\d{3})(\D)", salida, origen, destino) Then Exit Function
    If RR("Ley N.mero\s*(\d{0,3})\.?\s*(\d{3})(\D)", salida, origen, destino) Then Exit Function
    If RR("Ley\s*(\d{0,3})\.?\s*(\d{3})(\D)", salida, origen, destino) Then Exit Function
    If RR("Ley Pcial\.?\s*(\d{0,3})\.?\s*(\d{3})(\D)", salida, origen, destino) Then Exit Function
    If RR("Ley Pcial\.? Nº?\s*(\d{0,3})\.?\s*(\d{3})(\D)", salida, origen, destino) Then Exit Function
    If RR("Ley provincial\.?\s*(\d{0,3})\.?\s*(\d{3})(\D)", salida, origen, destino) Then Exit Function
    If RR("Ley provincial Nº?\s*(\d{0,3})\.?\s*(\d{3})(\D)", salida, origen, destino) Then Exit Function
    NormalizarNroLey = False
End Function

Function pp(ByVal salida As Boolean) As Boolean
  Debug.Print "Ok"
  pp = salida
End Function

Function NormalizarPuntos(ByVal origen As String, ByRef destino As String) As Boolean
  destino = Sustituir(destino, "(\d\.)\s+(\d)", "$1$2")
  destino = Sustituir(destino, "(\d)\s+%", "$1%")
  NormalizarPuntos = Not origen = destino
End Function

Sub NormalizarSubrayado()
    IrComienzo
    While AvanzarParrafo(True)
      Selection.Font.Underline = False
    Wend
    If UltimoParrafoVacio() Then BorrarUltimoParrafo
    IrComienzo
End Sub

Function NormalizarNumeros() As Boolean
    Dim linea As String, origen As String, destino As String, i As Integer
    NormalizarNumeros = False
    IrComienzo
    While AvanzarParrafo(True)
      i = i + 1
      linea = ParrafoActual()
      origen = linea
      destino = origen
      If (NormalizarDinero(destino, destino) Or NormalizarMetros(destino, destino) Or NormalizarPuntos(destino, destino)) And Not origen = destino Then
        Debug.Print i
        Debug.Print , RightPad(origen, 160)
        Debug.Print , RightPad(destino, 160)
        ReemplazarParrafoActual destino
        NormalizarNumeros = True
      End If
    Wend
End Function

Sub CerrarTodo(Optional ByVal guardar As Boolean)
  For Each d In Documents
    If guardar Then d.Save
    d.Close
  Next
End Sub

Sub SacarPiePagina()
  WordBasic.RemoveFooter
End Sub

Sub PonerPiePagina(Optional ByVal PaginaInicial As Integer = 1, Optional ByVal Texto As String = "CYB")
  SacarPiePagina
  
  WordBasic.ViewFooterOnly
  Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, Text:="PAGE   ", PreserveFormatting:=True
  With Selection.HeaderFooter.PageNumbers
    .NumberStyle = wdPageNumberStyleArabic
    .HeadingLevelForChapter = 0
    .IncludeChapterNumber = False
    .ChapterPageSeparator = wdSeparatorHyphen
    .RestartNumberingAtSection = True
    .StartingNumber = PaginaInicial
  End With
  
  Selection.EndKey Unit:=wdLine
  Selection.TypeText Text:=vbTab & vbTab & Texto
  Selection.HomeKey Unit:=wdLine, Extend:=wdExtend
  FormatoPiePagina
  ActiveWindow.ActivePane.View.SeekView = wdSeekMainDocument
End Sub

Sub GenerarTodo()
  Generar 2072, 8, "25 de agosto de 2016"
  Generar 2073, 2, "22 de septiembre de 2016"
  Generar 2074, 2, "29 de septiembre de 2016"
  Generar 2075, 8, "22 de marzo de 2017"
  Generar 2076, 14, "12 de abril de 2017"
  Generar 2077, 3, "12 de abril de 2017"
  Generar 2078, 4, "12 de abril de 2017"
  Generar 2079, 4, "12 de abril de 2017"
  Generar 2080, 3, "12 de abril de 2017"
  Generar 2081, 2, "12 de abril de 2017"
  Generar 2082, 3, "12 de abril de 2017"
  Generar 2083, 3, "12 de abril de 2017"
  Generar 2084, 3, "12 de abril de 2017"
  Generar 2085, 2, "15 de junio de 2017"
  Generar 2086, 2, "15 de junio de 2017"
  Generar 2087, 7, "15 de junio de 2017"
  Generar 2088, 3, "15 de junio de 2017"
  Generar 2089, 4, "15 de junio de 2017"
  Generar 2090, 9, "15 de junio de 2017"
  Generar 2091, 4, "22 de junio de 2017"
  Generar 2092, 5, "22 de junio de 2017"
  Generar 2093, 3, "22 de junio de 2017"
  Generar 2094, 15, "22 de junio de 2017"
  Generar 2095, 2, "22 de junio de 2017"
  Generar 2096, 10, "22 de junio de 2017"
  Generar 2097, 3, "22 de junio de 2017"
  Generar 2098, 4, "22 de junio de 2017"
  Generar 2099, 8, "22 de junio de 2017"
End Sub

Sub Generar(ByVal Ordenanza As Integer, ByVal Articulo As Integer, ByVal Fecha As String)
  Documents.Open FileName:=Raiz + "plantilla.docx"
  With Selection.Find
    .ClearFormatting
    .Replacement.ClearFormatting
    .Text = "{fecha}"
    .Replacement.Text = Fecha
    .Forward = True
    .Wrap = wdFindContinue
    .Format = False
    .MatchCase = False
    .MatchWholeWord = False
    .MatchWildcards = False
    .MatchSoundsLike = False
    .MatchAllWordForms = False
    .Execute Replace:=wdReplaceAll
  End With
  
  With Selection.Find
    .ClearFormatting
    .Replacement.ClearFormatting
    .Text = "{ordenanza}"
    .Replacement.Text = Ordenanza
    .Forward = True
    .Wrap = wdFindContinue
    .Format = False
    .MatchCase = False
    .MatchWholeWord = False
    .MatchWildcards = False
    .MatchSoundsLike = False
    .MatchAllWordForms = False
    .Execute Replace:=wdReplaceAll
  End With
  
  Selection.EndKey Unit:=wdStory
  Selection.HomeKey Unit:=wdLine, Extend:=wdExtend
  Selection.MoveUp Unit:=wdLine, Count:=15 - Articulo, Extend:=wdExtend
  Selection.EndKey Unit:=wdLine, Extend:=wdExtend
  Formato.Normal
  Selection.TypeText Text:="COMUNÍQUESE, REGÍSTRESE Y ARCHIVESE."
  ActiveDocument.SaveAs FileName:=Transcribir + Format(Ordenanza, "000#\.docx"), FileFormat:=wdFormatXMLDocument
   
  ActiveDocument.Close wdDoNotSaveChanges
End Sub

'-[NewMacros]--------------------------------------------------------
Sub ReemplazarEnSeleccion()
  Selection.Find.ClearFormatting
  Selection.Find.Replacement.ClearFormatting
  With Selection.Find
    .Text = "ARTÍCULO "
    .Replacement.Text = "Artículo "
    .Forward = True
    .Wrap = wdFindAsk
    .Format = False
    .MatchCase = False
    .MatchWholeWord = False
    .MatchWildcards = False
    .MatchSoundsLike = False
    .MatchAllWordForms = False
  End With
  Selection.Find.Execute Replace:=wdReplaceAll
End Sub

Sub ExportarPDF(ByVal destino As String)
  destino = DestinoPDF + Replace(destino, ".docx", ".pdf")
  ActiveDocument.ExportAsFixedFormat OutputFileName:=destino, ExportFormat:=wdExportFormatPDF, _
    OpenAfterExport:=False, OptimizeFor:=wdExportOptimizeForOnScreen, Range:=wdExportAllDocument, From:=1, To:=1, _
    Item:=wdExportDocumentContent, IncludeDocProps:=True, KeepIRM:=True, _
    CreateBookmarks:=wdExportCreateNoBookmarks, DocStructureTags:=True, _
    BitmapMissingFonts:=True, UseISO19005_1:=False
End Sub

Sub ExcluirArticulo()
  Dim Texto As String, i As Integer
  Texto = Selection.Text
  If Texto Like "ARTÍCULO*:*" Then
    i = InStr(Texto, ":")
    Selection.MoveLeft Unit:=wdWord, Count:=1
    Selection.MoveRight Unit:=wdCharacter, Count:=i
    Selection.MoveDown Unit:=wdParagraph, Count:=1, Extend:=wdExtend
  End If
End Sub

Sub FormatoDoblePunto()
  Selection.Find.ClearFormatting
  Selection.Find.Replacement.ClearFormatting
  Selection.Find.Replacement.Font.Underline = False
  
  With Selection.Find
    .Text = ":"
    .Replacement.Text = ": "
    .Execute Replace:=wdReplaceAll
    
    .Text = "  "
    .Replacement.Text = " "
    .Execute Replace:=wdReplaceAll
  End With
End Sub

Sub NormalizarDosPuntos()
  Selection.Find.ClearFormatting
  Selection.Find.Replacement.ClearFormatting
  Selection.Find.Replacement.Font.Underline = wdUnderlineNone
  With Selection.Find
    .Text = ":"
    .Replacement.Text = ": "
    .Forward = True
    .Wrap = wdFindContinue
    .Format = True
    .MatchCase = False
    .MatchWholeWord = False
    .MatchWildcards = False
    .MatchSoundsLike = False
    .MatchAllWordForms = False
  End With
  Selection.Find.Execute Replace:=wdReplaceAll
  With Selection.Find
    .Text = ":  "
    .Replacement.Text = ": "
    .Forward = True
    .Wrap = wdFindContinue
    .Format = True
    .MatchCase = False
    .MatchWholeWord = False
    .MatchWildcards = False
    .MatchSoundsLike = False
    .MatchAllWordForms = False
  End With
  Selection.Find.Execute Replace:=wdReplaceAll
End Sub

Sub Acomodar_Presupueso()
  Selection.Find.ClearFormatting
  Selection.Find.Replacement.ClearFormatting
  Selection.Find.Replacement.Font.Underline = wdUnderlineNone
  With Selection.Find
    .Text = ", "
    .Replacement.Text = ","
    .Forward = True
    .Wrap = wdFindAsk
    .Format = True
    .MatchCase = False
    .MatchWholeWord = False
    .MatchWildcards = False
    .MatchSoundsLike = False
    .MatchAllWordForms = False
  End With
  Selection.Find.Execute Replace:=wdReplaceAll
  With Selection.Find
    .Text = ". "
    .Replacement.Text = "."
    .Forward = True
    .Wrap = wdFindAsk
    .Format = True
    .MatchCase = False
    .MatchWholeWord = False
    .MatchWildcards = False
    .MatchSoundsLike = False
    .MatchAllWordForms = False
  End With
  Selection.Find.Execute Replace:=wdReplaceAll
  Selection.Find.ClearFormatting
  Selection.Find.Replacement.ClearFormatting
  Selection.Find.Replacement.Font.Underline = wdUnderlineNone
  With Selection.Find
    .Text = ". "
    .Replacement.Text = "."
    .Forward = True
    .Wrap = wdFindAsk
    .Format = True
    .MatchCase = False
    .MatchWholeWord = False
    .MatchWildcards = False
    .MatchSoundsLike = False
    .MatchAllWordForms = False
  End With
End Sub

Sub SacarMarcaAgua()
  ActiveDocument.Sections(1).Range.Select
  ActiveWindow.ActivePane.View.SeekView = wdSeekCurrentPageHeader
  Selection.HeaderFooter.Shapes("WordPictureWatermark154365563").Select
  Selection.Delete
  ActiveWindow.ActivePane.View.SeekView = wdSeekMainDocument
  WordBasic.RemoveWatermark
End Sub

Sub PonerMarcaAgua()
  ActiveDocument.Sections(1).Range.Select
  ActiveWindow.ActivePane.View.SeekView = wdSeekCurrentPageHeader
  Selection.HeaderFooter.Shapes.AddPicture(FileName:="C:\Users\usuario\Dropbox\limpiar\marca.png", LinkToFile:=False, SaveWithDocument:=True).Select
  With Selection.ShapeRange
    .Name = "WordPictureWatermark154721729"
    .PictureFormat.Brightness = 0.5
    .PictureFormat.Contrast = 0.5
    .LockAspectRatio = True
    .Height = CentimetersToPoints(5.42)
    .Width = CentimetersToPoints(15.99)
    .WrapFormat.AllowOverlap = True
    .WrapFormat.Side = wdWrapNone
    .WrapFormat.Type = 3
    .RelativeHorizontalPosition = wdRelativeVerticalPositionMargin
    .RelativeVerticalPosition = wdRelativeVerticalPositionMargin
    .Left = wdShapeCenter
    .Top = wdShapeCenter
  End With
  ActiveWindow.ActivePane.View.SeekView = wdSeekMainDocument
End Sub

Sub AgregarNroPagina(Optional ByVal PaginaInicial As Integer = 1)
  WordBasic.RemovePageNumbers
  With Selection.Sections(1).Headers(1).PageNumbers
    .NumberStyle = wdPageNumberStyleArabic
    .HeadingLevelForChapter = 0
    .IncludeChapterNumber = False
    .ChapterPageSeparator = wdSeparatorHyphen
    .RestartNumberingAtSection = True
    .StartingNumber = PaginaInicial
  End With
  WordBasic.ViewFooterOnly
  ActiveDocument.AttachedTemplate.BuildingBlockEntries(" En blanco (tres columnas)").Insert Where:=Selection.Range, RichText:=True
  Selection.TypeText Text:="CYB" & vbTab
  Selection.Delete Unit:=wdCharacter, Count:=1
  Selection.TypeBackspace
  Selection.MoveLeft Unit:=wdCharacter, Count:=15
  Selection.MoveRight Unit:=wdCharacter, Count:=1
  Selection.MoveRight Unit:=wdCharacter, Count:=1, Extend:=wdExtend
  Selection.Delete Unit:=wdCharacter, Count:=1
  Selection.TypeText Text:="Digesto"
  ActiveWindow.ActivePane.View.SeekView = wdSeekMainDocument
End Sub

Sub aaa()
  WordBasic.ViewFooterOnly
  Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, Text:="PAGE   ", PreserveFormatting:=True
  With Selection.HeaderFooter.PageNumbers
    .NumberStyle = wdPageNumberStyleArabic
    .HeadingLevelForChapter = 0
    .IncludeChapterNumber = False
    .ChapterPageSeparator = wdSeparatorHyphen
    .RestartNumberingAtSection = True
    .StartingNumber = 5
  End With
  Selection.EndKey Unit:=wdLine
  Selection.TypeText Text:=vbTab & vbTab & "CYB"
  Selection.HomeKey Unit:=wdLine, Extend:=wdExtend
  Selection.Font.Shrink
  ActiveWindow.ActivePane.View.SeekView = wdSeekMainDocument
End Sub

Sub ExportarHTM(ByVal destino As String)
  ChangeFileOpenDirectory "C:\Users\usuario\Dropbox\htm\"
  ActiveDocument.SaveAs FileName:="2020.htm", FileFormat:=wdFormatFilteredHTML
  ActiveWindow.View.Type = wdWebView
  If ActiveWindow.View.SplitSpecial = wdPaneNone Then
    ActiveWindow.ActivePane.View.Type = wdPrintView
  Else
    ActiveWindow.View.Type = wdPrintView
  End If
End Sub

