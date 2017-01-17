function Set-ServicePointManager {
    # https://github.com/Azure/azure-storage-net-data-movement
    [System.Net.ServicePointManager]::DefaultConnectionLimit = $ConcurrentNetTasks
    [System.Net.ServicePointManager]::Expect100Continue = $false

    # https://blogs.msdn.microsoft.com/windowsazurestorage/2010/06/25/nagles-algorithm-is-not-friendly-towards-small-requests/
    [System.Net.ServicePointManager]::UseNagleAlgorithm = $false
}