function WriteBlocks([System.Collections.ArrayList]$Blocks) {
    if ([string]::IsNullOrWhiteSpace($Block.BackgroundColor)) {
        $Block.BackgroundColor = $Host.UI.RawUI.BackgroundColor
    }

    if ([string]::IsNullOrWhiteSpace($Block.ForegroundColor)) {
        $Block.ForegroundColor = $Host.UI.RawUI.ForegroundColor
    }

    foreach ($block in $Blocks | Where-Object { $_.AlignRight -eq $false } ) {
        

        $Host.UI.RawUI.BackgroundColor = $Block.BackgroundColor
        $Host.UI.RawUI.ForegroundColor = $Block.ForegroundColor
        $Host.UI.Write($Block.Text)
    }

    $b = ($Blocks | Where-Object { $_.AlignRight -eq $true } | Select-Object -Property Text)
    $text = $b.Text -join ""
    $totalLength = $text.Length

    $startPosX = $Host.UI.RawUI.WindowSize.Width - $totalLength
    $startPosY = $Host.UI.RawUI.CursorPosition.Y

    foreach ($block in $Blocks | Where-Object { $_.AlignRight -eq $true } ) {
        
        $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $startPosX, $startPosY
        
        $Host.UI.RawUI.BackgroundColor = $Block.BackgroundColor
        $Host.UI.RawUI.ForegroundColor = $Block.ForegroundColor
        $Host.UI.Write($Block.Text)

        $startPosX += $Block.Text.Length
        $startPosY = $Host.UI.RawUI.CursorPosition.Y
    }
}

function Get-CurrentPath() {
    $array = New-Object System.Collections.ArrayList

    # Current Path
    $CurrentPath = "$($ExecutionContext.SessionState.Path.CurrentLocation)".Replace($HOME, "~")
    $null = $array.Add([Block]::new("$($script:glyphs.Separator)", "DarkBlue", "DarkBlue"))
    $null = $array.Add([Block]::new("$($script:glyphs.Folder)", "DarkBlue", ''))
    $null = $array.Add([Block]::new("$($script:glyphs.Separator)", "DarkBlue", "DarkBlue"))
    $null = $array.Add([Block]::new($CurrentPath, "DarkBlue", "White"))
    $null = $array.Add([Block]::new("$($script:glyphs.Separator)", "DarkBlue", "DarkBlue"))
    $null = $array.Add([Block]::new("$($script:glyphs.LeftHardDivider)", $CurrentBackgroundColor, "DarkBlue"))

    Return $array
}

class Block {
    [string] $Text
    [System.ConsoleColor] $BackgroundColor
    [System.ConsoleColor] $ForegroundColor
    [bool] $AlignRight

    Block($Text) {        
        $this.Init($Text, $null, $null, $false)
    }

    Block([string]$Text, [System.ConsoleColor]$BackgroundColor, [System.ConsoleColor]$ForegroundColor) {
        $this.Init($Text, $BackgroundColor, $ForegroundColor, $false)
    }

    Block([string]$Text, [System.ConsoleColor]$BackgroundColor, [System.ConsoleColor]$ForegroundColor, [bool]$AlignRight) {
        $this.Init($Text, $BackgroundColor, $ForegroundColor, $AlignRight)
    }

    Hidden Init([string]$Text, [System.ConsoleColor]$BackgroundColor, [System.ConsoleColor]$ForegroundColor, [bool]$AlignRight) {
        $this.Text = $Text
        $this.BackgroundColor = $BackgroundColor
        $this.ForegroundColor = $ForegroundColor
        $this.AlignRight = $AlignRight
    }
}

$script:glyphs = @{
    Windows          = "`u{e62a}";
    Git              = "`u{e702}";
    Gitlab           = "`u{f296}";
    GitBranch        = "`u{f418}";
    TimeClock        = "`u{f017}";
    TimeSand         = "`u{fb82}";
    Check            = "`u{f42e}";
    LeftHardDivider  = "`u{e0b0}";
    RightHardDivider = "`u{e0b2}";
    ChevronRight     = "`u{f460}";
    Folder           = "`u{f07c}";
    Dollar           = "`u{f155}"
    Separator        = "█"; #"`u{007c}"
}

function global:Prompt() {
    $ErrorOccured = !$?
    $CurrentBackgroundColor = $Host.UI.RawUI.BackgroundColor
    $CurrentForegroundColor = $Host.UI.RawUI.ForegroundColor
    $Blocks = New-Object System.Collections.ArrayList

    # User/Windows
    if ($env:SSH_CONNECTION) {
        $CurrentUser = ($env:USERNAME ?? $env:USER)
        $CurrentHostName = ($env:COMPUTERNAME ?? (HOSTNAME.EXE))
        $null = $Blocks.Add([Block]::new("$($script:glyphs.RightHardDivider)", "", "White"))
        $null = $Blocks.Add([Block]::new("$($script:glyphs.Separator)", "White", "White"))
        $null = $Blocks.Add([Block]::new($CurrentUser, "White", "Black"))
        $null = $Blocks.Add([Block]::new("@", "White", "Red"))
        $null = $Blocks.Add([Block]::new($CurrentHostName, "White", "Black"))
        $null = $Blocks.Add([Block]::new("$($script:glyphs.LeftHardDivider)", "DarkBlue", "White"))
    }
    else {
        $null = $Blocks.Add([Block]::new("$($script:glyphs.RightHardDivider)", "", "White"))
        $null = $Blocks.Add([Block]::new("$($script:glyphs.Separator)", "White", "White"))
        $null = $Blocks.Add([Block]::new("$($script:glyphs.Windows)", "White", "Black"))
        $null = $Blocks.Add([Block]::new("$($script:glyphs.Separator)", "White", "White"))        
        $null = $Blocks.Add([Block]::new("$($script:glyphs.LeftHardDivider)", "DarkBlue", "White"))
    }

    # Current Path

    $Blocks.AddRange((Get-CurrentPath))
    

    # Git // TODO

    # Command // TODO
    $LastCommand = Get-History -Count 1
    Write-Host "Command Duration: $($LastCommand.Duration.TotalMilliseconds)"
    if ($LastCommand.Duration.TotalMilliseconds -gt 500 -and $LastCommand.Duration.TotalMilliseconds -lt 1000) {
        $null = $Blocks.Add([Block]::new("$($script:glyphs.RightHardDivider)", $CurrentBackgroundColor, "Yellow", $true))
        $null = $Blocks.Add([Block]::new("$($script:glyphs.Separator)", "Yellow", "Yellow", $true))
        $null = $Blocks.Add([Block]::new("$($LastCommand.Duration.ToString('fff')) ms", "Yellow", "Black", $true))
    }
    elseif ($LastCommand.Duration.TotalMilliseconds -gt 1000 -and $LastCommand.Duration.TotalMilliseconds -lt 60000) {
        $null = $Blocks.Add([Block]::new("$($script:glyphs.RightHardDivider)", $CurrentBackgroundColor, "Yellow", $true))
        $null = $Blocks.Add([Block]::new("$($script:glyphs.Separator)", "Yellow", "Yellow", $true))
        $null = $Blocks.Add([Block]::new("$([System.Math]::Round($LastCommand.Duration.TotalSeconds, 2)) sec", "Yellow", "Black", $true))
    }
    elseif ($LastCommand.Duration.TotalMilliseconds -gt 60000) {
        $null = $Blocks.Add([Block]::new("$($script:glyphs.RightHardDivider)", $CurrentBackgroundColor, "Yellow", $true))
        $null = $Blocks.Add([Block]::new("$($script:glyphs.Separator)", "Yellow", "Yellow", $true))
        $null = $Blocks.Add([Block]::new("$([System.Math]::Round($LastCommand.Duration.TotalMinutes, 2)) min", "Yellow", "Black", $true))
    }
    
    # LastExiCode
    if ($ErrorOccured) {
        $null = $Blocks.Add([Block]::new("$($script:glyphs.RightHardDivider)", "Black", "Red", $true))
        $null = $Blocks.Add([Block]::new("$($script:glyphs.Separator)", "Red", "Red", $true))
        $null = $Blocks.Add([Block]::new("ERROR", "Red", "Black", $true))
        $null = $Blocks.Add([Block]::new("$($script:glyphs.Separator)", "Red", "Red", $true))
        $null = $Blocks.Add([Block]::new("$($script:glyphs.RightHardDivider)", "Red", "White", $true))
    }
    else {
        $null = $Blocks.Add([Block]::new("$($script:glyphs.RightHardDivider)", $CurrentBackgroundColor, "Green", $true))
        $null = $Blocks.Add([Block]::new("$($script:glyphs.Separator)", "Green", "Green", $true))
        $null = $Blocks.Add([Block]::new("$($script:glyphs.Check)", "Green", "White", $true))
        $null = $Blocks.Add([Block]::new("$($script:glyphs.Separator)", "Green", "Green", $true))
        $null = $Blocks.Add([Block]::new("$($script:glyphs.RightHardDivider)", "Green", "White", $true))
    }

    $null = $Blocks.Add([Block]::new("$($script:glyphs.Separator)", "White", "White", $true))
    $null = $Blocks.Add([Block]::new("$(Get-Date -Format "HH:mm:ss")", "White", "Black", $true))
    $null = $Blocks.Add([Block]::new("$($script:glyphs.Separator)", "White", "White", $true))
    $null = $Blocks.Add([Block]::new("$($script:glyphs.TimeClock)", "White", "Black", $true))
    $null = $Blocks.Add([Block]::new("$($script:glyphs.Separator)", "White", "White", $true))
    $null = $Blocks.Add([Block]::new("$($script:glyphs.LeftHardDivider)", $CurrentBackgroundColor, "White", $true))

    WriteBlocks($Blocks)

    $IsElavated = $true

    $Host.UI.WriteLine()
    if ($IsElavated) {
        $Host.UI.RawUI.ForegroundColor = [System.ConsoleColor]::Green
        $Host.UI.Write("$($script:glyphs.Dollar)")
    }
    else {        
        $Host.UI.RawUI.ForegroundColor = [System.ConsoleColor]::Green
        $Host.UI.Write("$($script:glyphs.ChevronRight)")
    }
    

    $Host.UI.RawUI.BackgroundColor = $CurrentBackgroundColor
    $Host.UI.RawUI.ForegroundColor = $CurrentForegroundColor

    Return " "
} 


