function Start-FileDownload {
    param (
        $url, 
        $targetPath = "$env:userprofile\download",
        $bufferSize = 10KB,
        [switch]$Overwrite
    )

    $Filename = [System.IO.Path]::GetFileName($url)
    $SoftwareFullPath = "$($targetPath)\$Filename"
    If (!(Test-Path $targetPath)) {mkdir $targetPath | Out-Null}
    
    # Add test to check if fileexists at the target path
    If (Test-Path $SoftwareFullPath) {
        "$SoftwareFullPath already exists.  Do you want to overwrite?"
    }
   
    $uri = New-Object "System.Uri" "$url"
    $request = [System.Net.HttpWebRequest]::Create($uri)
    $request.set_Timeout(15000) #15 second timeout
    $response = $request.GetResponse()
    $ContentLength = $response.ContentLength

    # Get the unit to present
    switch ($ContentLength.ToString().length) {
        {$_ -le 15} { $Unit = 'TB' }
        {$_ -le 12} { $Unit = 'GB' }
        {$_ -le 9} { $Unit = 'MB' }
        {$_ -le 6} { $Unit = 'KB' }
        {$_ -le 3} { $Unit = $null }
        Default {"This file is too powerful"}
    }

    $Divide = $ContentLength/"1$unit"
    $Round = [math]::round($Divide,3)
    
    $responseStream = $response.GetResponseStream()
    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $SoftwareFullPath, Create
    $buffer = new-object byte[] $bufferSize
    $count = $responseStream.Read($buffer,0,$buffer.length)
    $downloadedBytes = $count
    while ($count -gt 0) {
        $targetStream.Write($buffer, 0, $count)
        $count = $responseStream.Read($buffer,0,$buffer.length)
        $downloadedBytes = $downloadedBytes + $count
        
        $WriteProgressParams = @{
            activity =  "Downloading file: $Filename [$Round $Unit]" 
            status =  "Downloaded ( $downloadedBytes of $($ContentLength) Bytes ): " 
            PercentComplete =  ( ($downloadedBytes / $ContentLength)  * 100 )
        }
        Write-Progress @WriteProgressParams -ErrorAction SilentlyContinue
   }
    $targetStream.Flush()
    $targetStream.Close()
    $targetStream.Dispose()
    $responseStream.Dispose()

    return $SoftwareFullPath
}
