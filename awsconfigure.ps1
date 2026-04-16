Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$awsDir   = "$env:USERPROFILE\.aws"
$credPath = "$awsDir\credentials"

if (!(Test-Path $awsDir))   { New-Item -ItemType Directory -Path $awsDir | Out-Null }
if (!(Test-Path $credPath)) { New-Item -ItemType File      -Path $credPath | Out-Null }

# -------------------------------------------------------
# LEER PERFILES
# -------------------------------------------------------
function Get-AwsProfiles {
    $lines    = Get-Content $credPath -ErrorAction SilentlyContinue
    $profiles = [System.Collections.Generic.List[string]]::new()
    if ($lines) {
        foreach ($line in $lines) {
            if ($line.Trim() -match '^\[([^\]]+)\]$') {
                $name = $matches[1]
                if (-not $profiles.Contains($name)) { $profiles.Add($name) }
            }
        }
    }
    return , $profiles.ToArray()
}

# -------------------------------------------------------
# LEER DATOS DE PERFIL
# -------------------------------------------------------
function Get-ProfileData([string]$profile) {
    $lines  = Get-Content $credPath -ErrorAction SilentlyContinue
    $data   = @{}
    $inside = $false
    if ($lines) {
        foreach ($line in $lines) {
            $t = $line.Trim()
            if ($t -match '^\[([^\]]+)\]$') {
                if ($inside) { break }
                $inside = ($matches[1] -eq $profile)
                continue
            }
            if ($inside -and $t -match '^([^=]+?)\s*=\s*(.*)$') {
                $data[$matches[1].Trim()] = $matches[2].Trim()
            }
        }
    }
    return $data
}

# -------------------------------------------------------
# GUARDAR DATOS DE PERFIL
# -------------------------------------------------------
function Save-ProfileData([string]$profile, [string]$ak, [string]$sk, [string]$token) {
    $lines        = Get-Content $credPath -ErrorAction SilentlyContinue
    $result       = [System.Collections.Generic.List[string]]::new()
    $insideTarget = $false
    $foundProfile = $false
    $keysHandled  = @{ ak = $false; sk = $false; token = $false }
    $addToken     = ($token -and $token.Trim() -ne "")

    if ($lines) {
        foreach ($line in $lines) {
            $t = $line.Trim()
            if ($t -match '^\[([^\]]+)\]$') {
                $cur = $matches[1]
                if ($insideTarget) {
                    if (-not $keysHandled.ak)                   { $result.Add("aws_access_key_id = $ak") }
                    if (-not $keysHandled.sk)                   { $result.Add("aws_secret_access_key = $sk") }
                    if (-not $keysHandled.token -and $addToken) { $result.Add("aws_session_token = $token") }
                    $insideTarget = $false
                }
                if ($cur -eq $profile) {
                    $insideTarget = $true
                    $foundProfile = $true
                    $result.Add($t)
                    continue
                }
            }
            if ($insideTarget) {
                if ($t -match '^aws_access_key_id\s*=')     { $result.Add("aws_access_key_id = $ak");     $keysHandled.ak    = $true; continue }
                if ($t -match '^aws_secret_access_key\s*=') { $result.Add("aws_secret_access_key = $sk"); $keysHandled.sk    = $true; continue }
                if ($t -match '^aws_session_token\s*=') {
                    if ($addToken) { $result.Add("aws_session_token = $token") }
                    $keysHandled.token = $true; continue
                }
                $result.Add($line)
            } else {
                $result.Add($line)
            }
        }
    }

    if ($insideTarget) {
        if (-not $keysHandled.ak)                   { $result.Add("aws_access_key_id = $ak") }
        if (-not $keysHandled.sk)                   { $result.Add("aws_secret_access_key = $sk") }
        if (-not $keysHandled.token -and $addToken) { $result.Add("aws_session_token = $token") }
    }

    if (-not $foundProfile) {
        if ($result.Count -gt 0 -and $result[$result.Count - 1].Trim() -ne "") { $result.Add("") }
        $result.Add("[$profile]")
        $result.Add("aws_access_key_id = $ak")
        $result.Add("aws_secret_access_key = $sk")
        if ($addToken) { $result.Add("aws_session_token = $token") }
    }

    $enc = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllLines($credPath, $result, $enc)
}

# -------------------------------------------------------
# ELIMINAR PERFIL
# -------------------------------------------------------
function Remove-ProfileData([string]$profile) {
    if (!(Test-Path $credPath)) { return }
    $lines        = Get-Content $credPath -ErrorAction SilentlyContinue
    $result       = [System.Collections.Generic.List[string]]::new()
    $insideTarget = $false

    if ($lines) {
        foreach ($line in $lines) {
            $t = $line.Trim()
            if ($t -match '^\[([^\]]+)\]$') {
                $cur = $matches[1]
                $insideTarget = ($cur -eq $profile)
                if ($insideTarget) { continue }
            }
            if ($insideTarget) { continue }
            $result.Add($line)
        }
    }

    # Limpiar líneas vacías duplicadas al final que pudieron quedar
    while ($result.Count -gt 1 -and $result[$result.Count - 1].Trim() -eq "" -and $result[$result.Count - 2].Trim() -eq "") {
        $result.RemoveAt($result.Count - 1)
    }

    $enc = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllLines($credPath, $result, $enc)
}

# -------------------------------------------------------
# VALIDAR CREDENCIALES CON AWS CLI
# -------------------------------------------------------
function Test-AwsCredentials([string]$profile, [System.Windows.Forms.Form]$parentForm) {
    $parentForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    try {
        if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
            [System.Windows.Forms.MessageBox]::Show(
                "El comando 'aws' no se encontro en el PATH.`nInstala AWS CLI y asegurate de que este en el PATH.",
                "AWS CLI no encontrado",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
        $output = & aws sts get-caller-identity --profile $profile 2>&1
        if ($LASTEXITCODE -eq 0) {
            try {
                $j   = $output | ConvertFrom-Json
                $msg = "CREDENCIALES VALIDAS`n`nAccount : $($j.Account)`nUserId  : $($j.UserId)`nArn     : $($j.Arn)"
            } catch { $msg = "CREDENCIALES VALIDAS`n`n$output" }
            [System.Windows.Forms.MessageBox]::Show($msg, "Validacion correcta",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information)
        } else {
            $err = ($output | Out-String).Trim()
            [System.Windows.Forms.MessageBox]::Show(
                "CREDENCIALES INVALIDAS o EXPIRADAS.`n`n$err",
                "Error de validacion",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Error inesperado al ejecutar AWS CLI.`n`n$($_.Exception.Message)",
            "Error critico",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error)
    } finally {
        $parentForm.Cursor = [System.Windows.Forms.Cursors]::Default
    }
}

# -------------------------------------------------------
# HELPERS
# -------------------------------------------------------
function Refresh-ComboProfiles {
    param([System.Windows.Forms.ComboBox]$combo, [string]$selectProfile = "")
    $profiles = Get-AwsProfiles
    $combo.Items.Clear()
    if ($profiles -and $profiles.Count -gt 0) { $combo.Items.AddRange($profiles) }
    if ($selectProfile -and $combo.Items.Contains($selectProfile)) { $combo.SelectedItem = $selectProfile }
}

function Invoke-SaveProfile {
    param([string]$profile, [string]$ak, [string]$sk, [string]$token, [System.Windows.Forms.ComboBox]$combo)
    Save-ProfileData $profile $ak $sk $token
    Refresh-ComboProfiles -combo $combo -selectProfile $profile
    [System.Windows.Forms.MessageBox]::Show(
        "Perfil '$profile' guardado correctamente.`n`nArchivo: $credPath",
        "Guardado",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information)
}

function Invoke-DeleteProfile {
    param([string]$profile, [System.Windows.Forms.ComboBox]$combo, [System.Windows.Forms.Form]$parentForm)
    
    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "¿Estás seguro de que deseas eliminar permanentemente el perfil '$profile'?",
        "Confirmar eliminación",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning,
        [System.Windows.Forms.MessageBoxDefaultButton]::Button2)

    if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
        Remove-ProfileData $profile
        Refresh-ComboProfiles -combo $combo
        
        # Limpiar campos después de borrar
        $parentForm.Controls.Find("textNewProfile", $true)[0].Text = ""
        $parentForm.Controls.Find("textAK", $true)[0].Text = ""
        $parentForm.Controls.Find("textSK", $true)[0].Text = ""
        $parentForm.Controls.Find("textToken", $true)[0].Text = ""

        [System.Windows.Forms.MessageBox]::Show(
            "Perfil '$profile' eliminado correctamente.",
            "Eliminado",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information)
    }
}

# =======================================================
# CONSTANTES DE LAYOUT
# Usamos layout APILADO: label encima, campo debajo.
# Esto evita cualquier solapamiento independientemente
# del DPI o escala de pantalla del sistema.
# =======================================================
$FW   = 660    # Ancho del area cliente del formulario
$ML   = 25     # Margen izquierdo
$MR   = 25     # Margen derecho
$CW   = $FW - $ML - $MR   # Ancho de columna disponible (610)
$LH   = 28    # Alto de la etiqueta (margen generoso para evitar corte por DPI)
$TH   = 30    # Alto de un TextBox de una linea
$GAP  = 6     # Gap entre label y textbox
$RGAP = 18    # Gap entre un campo y el siguiente label

# =======================================================
# FORMULARIO
# =======================================================
$form = New-Object System.Windows.Forms.Form
$form.Text            = "AWS Credentials Manager"
$form.ClientSize      = New-Object System.Drawing.Size($FW, 640)
$form.StartPosition   = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox     = $false
$form.MinimizeBox     = $true

$fLabel  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$fNormal = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$fSmall  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$fBtn    = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$fMono   = New-Object System.Drawing.Font("Courier New", 9,  [System.Drawing.FontStyle]::Regular)
$form.Font = $fNormal

$cBlue  = [System.Drawing.Color]::FromArgb(22,  89, 167)
$cGreen = [System.Drawing.Color]::FromArgb(36, 125,  55)
$cGray  = [System.Drawing.Color]::FromArgb(110, 110, 110)
$cWhite = [System.Drawing.Color]::White

# Franja superior azul
$topBar           = New-Object System.Windows.Forms.Panel
$topBar.Dock      = "Top"
$topBar.Height    = 10
$topBar.BackColor = $cBlue
$form.Controls.Add($topBar)

# -------------------------------------------------------
# HELPER: crear label de campo (stacked)
# -------------------------------------------------------
function New-FieldLabel([string]$text, [int]$x, [int]$y) {
    $lbl          = New-Object System.Windows.Forms.Label
    $lbl.Text     = $text
    $lbl.Location = New-Object System.Drawing.Point($x, $y)
    $lbl.MaximumSize = New-Object System.Drawing.Size($CW, 0)  # limita ancho, alto libre
    $lbl.AutoSize = $true
    $lbl.Font     = $fLabel
    return $lbl
}

# =======================================================
# SECCION 1: Perfil existente (lado a lado — label corta)
# =======================================================
$y = 22

$lCombo          = New-Object System.Windows.Forms.Label
$lCombo.Text     = "Perfil existente:"
$lCombo.Location = New-Object System.Drawing.Point($ML, ($y + 5))
$lCombo.AutoSize = $true
$lCombo.Font     = $fLabel
$form.Controls.Add($lCombo)

$comboProfile               = New-Object System.Windows.Forms.ComboBox
$comboProfile.Location      = New-Object System.Drawing.Point(190, $y)
$comboProfile.Width         = ($FW - 190 - $MR)
$comboProfile.Height        = $TH
$comboProfile.DropDownStyle = "DropDownList"
$comboProfile.Font          = $fNormal
$form.Controls.Add($comboProfile)

# =======================================================
# SEPARADOR 1
# =======================================================
$y += $TH + 14
$sep1            = New-Object System.Windows.Forms.Label
$sep1.BorderStyle = "Fixed3D"
$sep1.Location   = New-Object System.Drawing.Point($ML, $y)
$sep1.Size       = New-Object System.Drawing.Size($CW, 2)
$form.Controls.Add($sep1)
$y += 14

# =======================================================
# CAMPO: Nombre del perfil  (label encima + textbox + boton)
# =======================================================
$lNombre = New-FieldLabel "Nombre del perfil:" $ML $y
$form.Controls.Add($lNombre)
$y += $LH + $GAP

$btnNuevoW = 85
$btnDelW   = 85
$textNewProfile          = New-Object System.Windows.Forms.TextBox
$textNewProfile.Name     = "textNewProfile"   # Asignar nombre para búsqueda dinámica
$textNewProfile.Location = New-Object System.Drawing.Point($ML, $y)
$textNewProfile.Width    = ($CW - $btnNuevoW - $btnDelW - 16)
$textNewProfile.Height   = $TH
$textNewProfile.Font     = $fNormal
$form.Controls.Add($textNewProfile)

$btnNuevo          = New-Object System.Windows.Forms.Button
$btnNuevo.Text     = "Nuevo"
$btnNuevo.Location = New-Object System.Drawing.Point(($ML + $CW - $btnNuevoW - $btnDelW - 8), ($y - 1))
$btnNuevo.Width    = $btnNuevoW
$btnNuevo.Height   = ($TH + 2)
$btnNuevo.Font     = $fSmall
$btnNuevo.Add_Click({
    $comboProfile.SelectedIndex = -1
    $textNewProfile.Text        = ""
    $textAK.Text                = ""
    $textSK.Text                = ""
    $textToken.Text             = ""
    $textSK.PasswordChar        = [char]0x2022
    $btnVerSK.Text              = "Ver"
    $statusLabel.Text           = "Formulario limpio. Introduce los datos del nuevo perfil."
    $textNewProfile.Focus()
})
$form.Controls.Add($btnNuevo)

$btnEliminar          = New-Object System.Windows.Forms.Button
$btnEliminar.Text     = "Eliminar"
$btnEliminar.Location = New-Object System.Drawing.Point(($ML + $CW - $btnDelW), ($y - 1))
$btnEliminar.Width    = $btnDelW
$btnEliminar.Height   = ($TH + 2)
$btnEliminar.Font     = $fSmall
$btnEliminar.Add_Click({
    $profile = $textNewProfile.Text.Trim()
    if (-not $profile) {
        [System.Windows.Forms.MessageBox]::Show("Selecciona un perfil para eliminar.", "Aviso",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    Invoke-DeleteProfile -profile $profile -combo $comboProfile -parentForm $form
})
$form.Controls.Add($btnEliminar)
$y += $TH + $RGAP

# =======================================================
# SEPARADOR 2
# =======================================================
$sep2            = New-Object System.Windows.Forms.Label
$sep2.BorderStyle = "Fixed3D"
$sep2.Location   = New-Object System.Drawing.Point($ML, $y)
$sep2.Size       = New-Object System.Drawing.Size($CW, 2)
$form.Controls.Add($sep2)
$y += 14

# =======================================================
# CAMPO: Access Key ID
# =======================================================
$lAK = New-FieldLabel "Access Key ID:" $ML $y
$form.Controls.Add($lAK)
$y += $LH + $GAP

$textAK                 = New-Object System.Windows.Forms.TextBox
$textAK.Name            = "textAK"
$textAK.Location        = New-Object System.Drawing.Point($ML, $y)
$textAK.Width           = $CW
$textAK.Height          = $TH
$textAK.CharacterCasing = "Upper"
$textAK.Font            = $fNormal
$form.Controls.Add($textAK)
$y += $TH + $RGAP

# =======================================================
# CAMPO: Secret Access Key  (textbox + boton Ver/Ocultar)
# =======================================================
$lSK = New-FieldLabel "Secret Access Key:" $ML $y
$form.Controls.Add($lSK)
$y += $LH + $GAP

$btnVerW = 90
$textSK              = New-Object System.Windows.Forms.TextBox
$textSK.Name            = "textSK"
$textSK.Location     = New-Object System.Drawing.Point($ML, $y)
$textSK.Width        = ($CW - $btnVerW - 8)
$textSK.Height       = $TH
$textSK.PasswordChar = [char]0x2022
$textSK.Font         = $fNormal
$form.Controls.Add($textSK)

$btnVerSK          = New-Object System.Windows.Forms.Button
$btnVerSK.Text     = "Ver"
$btnVerSK.Location = New-Object System.Drawing.Point(($ML + $CW - $btnVerW), ($y - 1))
$btnVerSK.Width    = $btnVerW
$btnVerSK.Height   = ($TH + 2)
$btnVerSK.Font     = $fSmall
$btnVerSK.Add_Click({
    if ($textSK.PasswordChar -ne [char]0) {
        $textSK.PasswordChar = [char]0
        $btnVerSK.Text       = "Ocultar"
    } else {
        $textSK.PasswordChar = [char]0x2022
        $btnVerSK.Text       = "Ver"
    }
})
$form.Controls.Add($btnVerSK)
$y += $TH + $RGAP

# =======================================================
# CAMPO: Session Token
# =======================================================
$lToken = New-FieldLabel "Session Token:" $ML $y
$form.Controls.Add($lToken)

# Hint en la misma fila, a continuacion del label
$lHint           = New-Object System.Windows.Forms.Label
$lHint.Text      = "(opcional - solo credenciales temporales STS/SSO)"
$lHint.Location  = New-Object System.Drawing.Point($ML, ($y + $LH + 2))  # debajo del label Session Token
$lHint.MaximumSize = New-Object System.Drawing.Size($CW, 0)
$lHint.AutoSize  = $true
$lHint.ForeColor = $cGray
$lHint.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
$form.Controls.Add($lHint)
$y += $LH + 20 + $GAP   # espacio para label + hint

$tokenH = 95
$textToken            = New-Object System.Windows.Forms.TextBox
$textToken.Name       = "textToken"
$textToken.Location   = New-Object System.Drawing.Point($ML, $y)
$textToken.Width      = $CW
$textToken.Height     = $tokenH
$textToken.Multiline  = $true
$textToken.ScrollBars = "Vertical"
$textToken.Font       = $fMono
$form.Controls.Add($textToken)
$y += $tokenH + $RGAP

# =======================================================
# SEPARADOR 3
# =======================================================
$sep3            = New-Object System.Windows.Forms.Label
$sep3.BorderStyle = "Fixed3D"
$sep3.Location   = New-Object System.Drawing.Point($ML, $y)
$sep3.Size       = New-Object System.Drawing.Size($CW, 2)
$form.Controls.Add($sep3)
$y += 14

# =======================================================
# BOTONES PRINCIPALES
# =======================================================
$BH   = 50
$BW   = [int](($CW - 12) / 2)   # Mitad del ancho disponible con pequeño gap

$btnSave           = New-Object System.Windows.Forms.Button
$btnSave.Text      = "Guardar / Crear Perfil"
$btnSave.Location  = New-Object System.Drawing.Point($ML, $y)
$btnSave.Width     = $BW
$btnSave.Height    = $BH
$btnSave.Font      = $fBtn
$btnSave.BackColor = $cBlue
$btnSave.ForeColor = $cWhite
$btnSave.FlatStyle = "Flat"
$btnSave.FlatAppearance.BorderSize = 0

$btnSave.Add_Click({
    $profile = $textNewProfile.Text.Trim()
    if (-not $profile) {
        [System.Windows.Forms.MessageBox]::Show("Introduce un nombre de perfil antes de guardar.", "Aviso",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        $textNewProfile.Focus(); return
    }
    if ($profile -match '\s') {
        [System.Windows.Forms.MessageBox]::Show("El nombre del perfil no puede contener espacios.", "Aviso",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        $textNewProfile.Focus(); return
    }
    $ak = $textAK.Text.Trim()
    $sk = $textSK.Text.Trim()
    if (-not $ak -or -not $sk) {
        [System.Windows.Forms.MessageBox]::Show("El Access Key ID y el Secret Access Key son obligatorios.", "Aviso",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    Invoke-SaveProfile -profile $profile -ak $ak -sk $sk -token $textToken.Text.Trim() -combo $comboProfile
    $statusLabel.Text = "Perfil '$profile' guardado.  Archivo: $credPath"
})
$form.Controls.Add($btnSave)

$btnTest           = New-Object System.Windows.Forms.Button
$btnTest.Text      = "Validar Credenciales"
$btnTest.Location  = New-Object System.Drawing.Point(($ML + $BW + 12), $y)
$btnTest.Width     = $BW
$btnTest.Height    = $BH
$btnTest.Font      = $fBtn
$btnTest.BackColor = $cGreen
$btnTest.ForeColor = $cWhite
$btnTest.FlatStyle = "Flat"
$btnTest.FlatAppearance.BorderSize = 0

$btnTest.Add_Click({
    $profile = $textNewProfile.Text.Trim()
    if (-not $profile) {
        [System.Windows.Forms.MessageBox]::Show("Selecciona o escribe un nombre de perfil antes de validar.", "Aviso",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    $saved      = Get-ProfileData $profile
    $savedAK    = if ($saved["aws_access_key_id"])     { $saved["aws_access_key_id"] }     else { "" }
    $savedSK    = if ($saved["aws_secret_access_key"]) { $saved["aws_secret_access_key"] } else { "" }
    $savedToken = if ($saved["aws_session_token"])     { $saved["aws_session_token"] }     else { "" }

    $dirty = ($textAK.Text.Trim() -ne $savedAK) -or ($textSK.Text.Trim() -ne $savedSK) -or ($textToken.Text.Trim() -ne $savedToken)

    if ($dirty) {
        $resp = [System.Windows.Forms.MessageBox]::Show(
            "Hay cambios sin guardar en el perfil '$profile'.`n`nDeseas guardarlos antes de validar?",
            "Cambios pendientes",
            [System.Windows.Forms.MessageBoxButtons]::YesNoCancel,
            [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($resp -eq [System.Windows.Forms.DialogResult]::Cancel) { return }
        if ($resp -eq [System.Windows.Forms.DialogResult]::Yes) {
            $ak = $textAK.Text.Trim()
            $sk = $textSK.Text.Trim()
            if (-not $ak -or -not $sk) {
                [System.Windows.Forms.MessageBox]::Show("Access Key ID y Secret Access Key son obligatorios.", "Aviso",
                    [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                return
            }
            Invoke-SaveProfile -profile $profile -ak $ak -sk $sk -token $textToken.Text.Trim() -combo $comboProfile
        }
    }

    $statusLabel.Text = "Validando perfil '$profile'..."
    Test-AwsCredentials -profile $profile -parentForm $form
    $statusLabel.Text = "Listo.  Archivo: $credPath"
})
$form.Controls.Add($btnTest)

# =======================================================
# BARRA DE ESTADO
# =======================================================
$statusBar             = New-Object System.Windows.Forms.StatusStrip
$statusLabel           = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text      = "Listo  |  $credPath"
$statusLabel.Spring    = $true
$statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$statusBar.Items.Add($statusLabel) | Out-Null
$form.Controls.Add($statusBar)

# =======================================================
# EVENTO: seleccionar perfil del combo
# =======================================================
$comboProfile.Add_SelectedIndexChanged({
    $p = $comboProfile.SelectedItem
    if (-not $p) { return }
    $data = Get-ProfileData $p
    $textNewProfile.Text = $p
    $textAK.Text         = if ($data["aws_access_key_id"])     { $data["aws_access_key_id"] }     else { "" }
    $textSK.Text         = if ($data["aws_secret_access_key"]) { $data["aws_secret_access_key"] } else { "" }
    $textToken.Text      = if ($data["aws_session_token"])     { $data["aws_session_token"] }     else { "" }
    $textSK.PasswordChar = [char]0x2022
    $btnVerSK.Text       = "Ver"
    $statusLabel.Text    = "Perfil cargado: '$p'  |  $credPath"
})

# =======================================================
# INICIO
# =======================================================
Refresh-ComboProfiles -combo $comboProfile
$form.ActiveControl = $textNewProfile
[void]$form.ShowDialog()