function New-AgeKey{
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, mandatory = $true)]
        [string]$KeyName,
        [switch]$UsePassword,
        [switch]$Force
    )

    $pubKeyFile = "${KeyName}.pub"
    $privKeyFile = "${KeyName}.key"
    $privEncKeyFile = "${KeyName}.pem"

    if ((Test-Path $pubKeyfile -PathType Leaf) -and -not $Force)
    {
        throw "An Output File $KeyName.pub exists, aborting"
    }

    if ($UsePassword -and (Test-Path $privEncKeyfile -PathType Leaf) -and -not $Force)
    {
        throw "An Output File $privEncKeyFile exists, aborting"
    }

    if (-not $UsePassword -and (Test-Path $privKeyfile -PathType Leaf) -and -not $Force)
    {
        throw "An Output File $privKeyFile exists, aborting"
    }


    $agekey = (age-keygen 2> $null)

    $comment = "# ${env:USERNAME}@$(hostname) $(Get-Date -Format 'o')"
    $pubkey  = $agekey[1].Replace("# public key: ","")
    $privkey = $agekey[2]

    $pub = @(
        $comment,
        $pubkey
    )

    $priv = @(
        $comment,
        $privkey
    )

    $pub | Out-File $pubKeyFile

    if ($UsePassword) {
        $priv | age --encrypt -p -a -o $privEncKeyFile
    } else {
        $priv | Out-File $privKeyFile
    }

    $pubkey
}

function Protect-Age {
    [CmdletBinding()]
    Param (
        [Parameter(ParameterSetName = "path",
            Mandatory = $true,
            Position = 0)]
        [string] $File,
        [Parameter(ParameterSetName = "pipe",
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true)]
        [string] $pipe,
        [Parameter(Position = 1)]
        [string[]]$RecipientFiles,
        [string[]]$Recipients,
        [switch]$UsePassword,
        [string]$OutputFile = "-",
        [Parameter(ValueFromPipeline = $true)]
        $piped
    )

    Begin {

        if (-not ($Recipients -or $RecipientFiles) -and -not $UsePassword) {
            throw "No encryption target configured. Provide either recipients or enable password encryption!"
        }

        if (($Recipients -or $RecipientFiles) -and $UsePassword) {
            throw "Both Recipient and Passwort encryption requested. Provide only one of Recipients or Passwort!"
        }


        $FileName = [System.IO.Path]::GetFileNameWithoutExtension($File)

        if (-not $OutputFile) {
            $OutputFile = $FileName + ".pem"
        }

        $params = @(
            "--encrypt",
            "--armor",
            "-o", $OutputFile
        )

        if ($UsePassword) {
            $params += "-p"
        }

        if ($RecipientFiles) {
            foreach ($f in $RecipientFiles) {
                $params += "-R", $f
            }
        }

        if ($Recipients) {
            foreach ($r in $Recipients) {
                $params += "-r", $r
            }
        }

        if ($File) {
            $content = Get-Content $File
        }
    }

    Process {
        if ($PSCmdlet.ParameterSetName -eq 'pipe') {
            $content = $()
            foreach ($line in $pipe) {
                $content += $line
            }
        }
    }

    End {
        $content | & age @params
    }
}

function Unprotect-Age {
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, mandatory = $true)]
        [string]$File,
        [Parameter(Position = 1)]
        [string[]]$IdentityFiles,
        [string]$OutputFile = "-"
    )

    if (-not $OutputFile) {
        $inputFilePath = (Get-Item $File)
        $baseOutputFile = Join-Path $inputFilePath.DirectoryName $inputFilePath.Basename
        $OutputFile = $baseOutputFile + ".txt"
    }

    $params = @(
        "--decrypt",
        "-o", $OutputFile
    )

    foreach ($f in $IdentityFiles) {
        $params += "-i", $f
    }

    $params += $File

    & age @params
}