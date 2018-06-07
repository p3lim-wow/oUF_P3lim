Set-Location -Path "$PSScriptRoot\.."

If(-Not (Test-Path -Path "embeds")){
	New-Item -ItemType Directory -Path embeds
}

If(-Not (Test-Path -Path "embeds\oUF")){
	New-Item -ItemType SymbolicLink -Path "embeds" -Name oUF -Value ..\oUF
} ElseIf(-Not (((Get-Item -Path "embeds\oUF").Attributes.ToString()) -Match "ReparsePoint")){
	Remove-Item -Path "embeds\oUF"
	New-Item -ItemType SymbolicLink -Path "embeds" -Name oUF -Value ..\oUF
}

If(-Not (Test-Path -Path "embeds\oUF_MovableFrames")){
	New-Item -ItemType SymbolicLink -Path "embeds" -Name oUF_MovableFrames -Value ..\oUF_MovableFrames
} ElseIf(-Not (((Get-Item -Path "embeds\oUF_MovableFrames").Attributes.ToString()) -Match "ReparsePoint")){
	Remove-Item -Path "embeds\oUF_MovableFrames"
	New-Item -ItemType SymbolicLink -Path "embeds" -Name oUF_MovableFrames -Value ..\oUF_MovableFrames
}

If(-Not (Test-Path -Path "embeds\oUF_Experience")){
	New-Item -ItemType SymbolicLink -Path "embeds" -Name oUF_Experience -Value ..\oUF_Experience
} ElseIf(-Not (((Get-Item -Path "embeds\oUF_Experience").Attributes.ToString()) -Match "ReparsePoint")){
	Remove-Item -Path "embeds\oUF_Experience"
	New-Item -ItemType SymbolicLink -Path "embeds" -Name oUF_Experience -Value ..\oUF_Experience
}
