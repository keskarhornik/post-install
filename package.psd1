@{
    Root = 'c:\Users\f.vyroubal\Downloads\post-install-main\post-install-main\FvLocalToolPanel.ps1'
    OutputPath = 'c:\Users\f.vyroubal\Downloads\post-install-main\post-install-main\out'
    Package = @{
        Enabled = $true
        Obfuscate = $false
        HideConsoleWindow = $false
        DotNetVersion = 'v4.6.2'
        FileVersion = '1.0.0'
        FileDescription = ''
        ProductName = ''
        ProductVersion = ''
        Copyright = ''
        RequireElevation = $false
        ApplicationIconPath = ''
        PackageType = 'Console'
    }
    Bundle = @{
        Enabled = $true
        Modules = $true
        # IgnoredModules = @()
    }
}
        