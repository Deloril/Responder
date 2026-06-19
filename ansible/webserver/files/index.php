<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>The Secrets Group - Internal Portal</title>
    <!-- TODO: Move to external CSS before launch - HS -->
    <!-- Internal dev notes: DB server at 10.0.2.6, admin creds in /admin/ -->
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f4f6f9; color: #333; }
        .header { background: linear-gradient(135deg, #1a237e 0%, #283593 100%); color: white; padding: 20px 40px; display: flex; justify-content: space-between; align-items: center; }
        .header h1 { font-size: 1.5em; }
        .header .tagline { font-size: 0.85em; opacity: 0.8; }
        .nav { background: #283593; padding: 0 40px; }
        .nav a { color: #c5cae9; text-decoration: none; padding: 12px 20px; display: inline-block; font-size: 0.9em; }
        .nav a:hover { color: white; background: rgba(255,255,255,0.1); }
        .container { max-width: 1100px; margin: 30px auto; padding: 0 20px; }
        .welcome-banner { background: white; border-radius: 8px; padding: 30px; margin-bottom: 25px; box-shadow: 0 2px 4px rgba(0,0,0,0.08); border-left: 4px solid #283593; }
        .welcome-banner h2 { color: #1a237e; margin-bottom: 10px; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .card { background: white; border-radius: 8px; padding: 25px; box-shadow: 0 2px 4px rgba(0,0,0,0.08); }
        .card h3 { color: #1a237e; margin-bottom: 12px; border-bottom: 2px solid #e8eaf6; padding-bottom: 8px; }
        .card ul { list-style: none; padding: 0; }
        .card ul li { padding: 8px 0; border-bottom: 1px solid #f0f0f0; }
        .card ul li a { color: #3949ab; text-decoration: none; }
        .card ul li a:hover { text-decoration: underline; }
        .search-box { margin: 20px 0; }
        .search-box form { display: flex; gap: 10px; }
        .search-box input[type="text"] { flex: 1; padding: 10px 15px; border: 1px solid #ddd; border-radius: 4px; font-size: 0.95em; }
        .search-box button { background: #283593; color: white; border: none; padding: 10px 25px; border-radius: 4px; cursor: pointer; }
        .footer { text-align: center; padding: 20px; margin-top: 40px; color: #888; font-size: 0.8em; border-top: 1px solid #ddd; }
    </style>
</head>
<body>
    <div class="header">
        <div>
            <h1>The Secrets Group</h1>
            <div class="tagline">Digital Escrow &amp; Secret Custodianship</div>
        </div>
        <div style="text-align:right; font-size:0.85em;">
            <div>Logged in as: <?php echo isset($_SERVER['REMOTE_USER']) ? htmlspecialchars($_SERVER['REMOTE_USER']) : 'Guest'; ?></div>
            <div><?php echo date('l, F j, Y'); ?></div>
        </div>
    </div>

    <div class="nav">
        <a href="/">Home</a>
        <a href="/search.php">Search</a>
        <a href="/uploads/">Documents</a>
        <a href="/login.php">Employee Login</a>
        <a href="/admin/">Admin</a>
    </div>

    <div class="container">
        <div class="welcome-banner">
            <h2>Welcome to the TSG Internal Portal</h2>
            <p>Access company resources, escrow documentation, and internal tools. For IT support, contact the help desk at ext. 4357 or email <strong>it-support@tsg-internal.lab</strong>. For vault access requests, contact the Chief Custodian Officer.</p>
        </div>

        <div class="search-box">
            <form action="/search.php" method="GET">
                <input type="text" name="q" placeholder="Search the portal...">
                <button type="submit">Search</button>
            </form>
        </div>

        <div class="grid">
            <div class="card">
                <h3>Company News</h3>
                <ul>
                    <li><strong>Mar 2026</strong> - Wellington vault maintenance window confirmed for March 22-23</li>
                    <li><strong>Feb 2026</strong> - New VPN access policy in effect for SSN remote staff - see <a href="/uploads/">Documents</a></li>
                    <li><strong>Jan 2026</strong> - ISO 27001:2022 recertification audit passed &mdash; zero non-conformities</li>
                    <li><strong>Dec 2025</strong> - SOC 2 Type II report finalised &mdash; available to clients under NDA</li>
                </ul>
            </div>

            <div class="card">
                <h3>Quick Links</h3>
                <ul>
                    <li><a href="/uploads/">Shared Documents</a></li>
                    <li><a href="/login.php">Employee Self-Service</a></li>
                    <li><a href="/phpinfo.php">System Information</a></li>
                    <li><a href="/admin/">IT Administration</a></li>
                </ul>
            </div>

            <div class="card">
                <h3>Vault &amp; IT Notices</h3>
                <ul>
                    <li>SSN ingestion window: Mon-Fri 09:00-16:00 NZST (three-person rule applies)</li>
                    <li>Scheduled maintenance window: Sundays 2-4 AM NZST</li>
                    <li>Report suspicious emails to: security@tsg-internal.lab</li>
                </ul>
                <!-- Reminder: default creds for test accounts are in /admin/index.php - remove before production -->
            </div>

            <div class="card">
                <h3>Department Contacts</h3>
                <ul>
                    <li><strong>IT Support:</strong> it-support@tsg-internal.lab</li>
                    <li><strong>Vault Operations:</strong> vault-ops@tsg-internal.lab</li>
                    <li><strong>Client Services:</strong> clients@tsg-internal.lab</li>
                    <li><strong>CEO:</strong> daniel.kemp@tsg-internal.lab</li>
                </ul>
            </div>
        </div>
    </div>

    <div class="footer">
        &copy; <?php echo date('Y'); ?> The Secrets Group. Internal use only. Unauthorized access is prohibited.<br>
        Server: <?php echo gethostname(); ?> | PHP <?php echo phpversion(); ?> | <?php echo $_SERVER['SERVER_SOFTWARE']; ?>
    </div>
</body>
</html>
