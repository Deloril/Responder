<?php
$db = new SQLite3('/var/www/tsg/users.db');
$error = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';

    $query = "SELECT * FROM users WHERE username = '$username' AND password = '$password'";
    $result = $db->querySingle($query, true);

    if ($result) {
        $success = "Welcome back, " . $result['username'] . "! Role: " . $result['role'];
    } else {
        $error = "Invalid credentials. Please try again.";
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Employee Login - The Secrets Group</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f4f6f9; color: #333; }
        .header { background: linear-gradient(135deg, #1a237e 0%, #283593 100%); color: white; padding: 20px 40px; }
        .header h1 { font-size: 1.5em; }
        .nav { background: #283593; padding: 0 40px; }
        .nav a { color: #c5cae9; text-decoration: none; padding: 12px 20px; display: inline-block; font-size: 0.9em; }
        .nav a:hover { color: white; background: rgba(255,255,255,0.1); }
        .container { max-width: 450px; margin: 60px auto; padding: 0 20px; }
        .login-card { background: white; border-radius: 8px; padding: 35px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .login-card h2 { color: #1a237e; margin-bottom: 5px; }
        .login-card .subtitle { color: #888; font-size: 0.9em; margin-bottom: 25px; }
        .form-group { margin-bottom: 18px; }
        .form-group label { display: block; margin-bottom: 5px; font-weight: 600; font-size: 0.9em; color: #555; }
        .form-group input { width: 100%; padding: 10px 12px; border: 1px solid #ddd; border-radius: 4px; font-size: 0.95em; }
        .form-group input:focus { outline: none; border-color: #3949ab; }
        .btn { width: 100%; background: #283593; color: white; border: none; padding: 12px; border-radius: 4px; font-size: 1em; cursor: pointer; }
        .btn:hover { background: #1a237e; }
        .error { background: #ffebee; color: #c62828; padding: 10px 15px; border-radius: 4px; margin-bottom: 15px; font-size: 0.9em; }
        .success { background: #e8f5e9; color: #2e7d32; padding: 10px 15px; border-radius: 4px; margin-bottom: 15px; font-size: 0.9em; }
        .footer-note { text-align: center; margin-top: 15px; font-size: 0.8em; color: #999; }
    </style>
</head>
<body>
    <div class="header">
        <h1>The Secrets Group</h1>
    </div>
    <div class="nav">
        <a href="/">Home</a>
        <a href="/search.php">Search</a>
        <a href="/uploads/">Documents</a>
        <a href="/login.php">Employee Login</a>
        <a href="/admin/">Admin</a>
    </div>

    <div class="container">
        <div class="login-card">
            <h2>Employee Login</h2>
            <p class="subtitle">Access the TSG self-service portal</p>

            <?php if ($error): ?>
                <div class="error"><?php echo $error; ?></div>
            <?php endif; ?>
            <?php if ($success): ?>
                <div class="success"><?php echo $success; ?></div>
            <?php endif; ?>

            <form method="POST" action="/login.php">
                <div class="form-group">
                    <label for="username">Username</label>
                    <input type="text" id="username" name="username" placeholder="Enter your username" required>
                </div>
                <div class="form-group">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" placeholder="Enter your password" required>
                </div>
                <button type="submit" class="btn">Sign In</button>
            </form>
            <p class="footer-note">Forgot password? Contact IT at ext. 4357</p>
            <!-- debug: query = SELECT * FROM users WHERE username = '$username' AND password = '$password' -->
        </div>
    </div>
</body>
</html>
