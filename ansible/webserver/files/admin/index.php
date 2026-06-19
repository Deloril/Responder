<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Panel - The Secrets Group</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f4f6f9; color: #333; }
        .header { background: #b71c1c; color: white; padding: 15px 40px; }
        .header h1 { font-size: 1.3em; }
        .container { max-width: 900px; margin: 30px auto; padding: 0 20px; }
        .panel { background: white; border-radius: 8px; padding: 25px; box-shadow: 0 2px 4px rgba(0,0,0,0.08); margin-bottom: 20px; }
        .panel h2 { color: #b71c1c; margin-bottom: 15px; border-bottom: 2px solid #ffcdd2; padding-bottom: 8px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th { background: #f5f5f5; text-align: left; padding: 10px; border-bottom: 2px solid #ddd; font-size: 0.9em; }
        td { padding: 10px; border-bottom: 1px solid #eee; font-size: 0.9em; }
        .info-grid { display: grid; grid-template-columns: 200px 1fr; gap: 8px; }
        .info-grid dt { font-weight: 600; color: #555; }
        .info-grid dd { color: #333; }
        .warning { background: #fff3e0; border-left: 4px solid #e65100; padding: 15px; margin-bottom: 20px; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>TSG IT Administration Panel</h1>
    </div>

    <div class="container">
        <div class="warning">
            <strong>Restricted Access.</strong> This panel is for authorized IT administrators only. All actions are logged.
        </div>

        <div class="panel">
            <h2>Server Information</h2>
            <dl class="info-grid">
                <dt>Hostname</dt>
                <dd><?php echo gethostname(); ?></dd>
                <dt>Server IP</dt>
                <dd><?php echo $_SERVER['SERVER_ADDR']; ?></dd>
                <dt>Server Software</dt>
                <dd><?php echo $_SERVER['SERVER_SOFTWARE']; ?></dd>
                <dt>PHP Version</dt>
                <dd><?php echo phpversion(); ?></dd>
                <dt>OS</dt>
                <dd><?php echo php_uname(); ?></dd>
                <dt>Document Root</dt>
                <dd><?php echo $_SERVER['DOCUMENT_ROOT']; ?></dd>
                <dt>Domain Controller</dt>
                <dd>10.0.1.6 (dc.tsg-internal.lab)</dd>
                <dt>Mail Server</dt>
                <dd>10.0.0.7 (mail.tsg-internal.lab)</dd>
                <dt>SQL Server</dt>
                <dd>10.0.2.6 (sql.tsg-internal.lab)</dd>
                <dt>File Server</dt>
                <dd>10.0.2.7 (file.tsg-internal.lab)</dd>
            </dl>
        </div>

        <div class="panel">
            <h2>User Accounts</h2>
            <table>
                <thead>
                    <tr><th>ID</th><th>Username</th><th>Role</th></tr>
                </thead>
                <tbody>
<?php
$db = new SQLite3('/var/www/tsg/users.db');
$results = $db->query('SELECT id, username, role FROM users');
while ($row = $results->fetchArray(SQLITE3_ASSOC)) {
    echo "<tr><td>{$row['id']}</td><td>{$row['username']}</td><td>{$row['role']}</td></tr>\n";
}
?>
                </tbody>
            </table>
        </div>

        <div class="panel">
            <h2>Network Services</h2>
            <table>
                <thead>
                    <tr><th>Service</th><th>Host</th><th>Port</th><th>Status</th></tr>
                </thead>
                <tbody>
<?php
$services = [
    ['SMTP (Postfix)', '10.0.0.7', 25],
    ['POP3 (Dovecot)', '10.0.0.7', 110],
    ['DNS (AD)', '10.0.1.6', 53],
    ['LDAP (AD)', '10.0.1.6', 389],
    ['SMB (File)', '10.0.2.7', 445],
    ['MSSQL', '10.0.2.6', 1433],
];
foreach ($services as $svc) {
    $conn = @fsockopen($svc[1], $svc[2], $errno, $errstr, 2);
    $status = $conn ? '<span style="color:green">Online</span>' : '<span style="color:red">Offline</span>';
    if ($conn) fclose($conn);
    echo "<tr><td>{$svc[0]}</td><td>{$svc[1]}</td><td>{$svc[2]}</td><td>$status</td></tr>\n";
}
?>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
