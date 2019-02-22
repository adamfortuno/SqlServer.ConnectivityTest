$server_instance = '<servername>'
$database = 'tempdb'
$connection_string = `
    "Provider=sqloledb;Data Source=${server_instance};Initial Catalog=${database};Integrated Security=SSPI;Connection Timeout=15"

$db_connection = `
    New-Object System.Data.OleDb.OleDbConnection $connection_string

try {
    $db_connection.Open()
    $sql_statement_text = "SELECT GETDATE();"
    $sql_command = `
        New-Object System.Data.OleDb.OleDbCommand $sql_statement_text, $db_connection
    $sql_command.ExecuteNonQuery() | Out-Null
} catch [System.Data.OleDb.OleDbException] {
    throw $_.Exception
} finally {
    $db_connection.Close()
    $db_connection.Dispose()
}