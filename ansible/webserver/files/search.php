<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Search - The Secrets Group</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f4f6f9; color: #333; }
        .header { background: linear-gradient(135deg, #1a237e 0%, #283593 100%); color: white; padding: 20px 40px; }
        .header h1 { font-size: 1.5em; }
        .nav { background: #283593; padding: 0 40px; }
        .nav a { color: #c5cae9; text-decoration: none; padding: 12px 20px; display: inline-block; font-size: 0.9em; }
        .nav a:hover { color: white; background: rgba(255,255,255,0.1); }
        .container { max-width: 800px; margin: 30px auto; padding: 0 20px; }
        .search-form { background: white; border-radius: 8px; padding: 25px; box-shadow: 0 2px 4px rgba(0,0,0,0.08); margin-bottom: 25px; }
        .search-form h2 { color: #1a237e; margin-bottom: 15px; }
        .search-form form { display: flex; gap: 10px; }
        .search-form input[type="text"] { flex: 1; padding: 10px 15px; border: 1px solid #ddd; border-radius: 4px; font-size: 0.95em; }
        .search-form button { background: #283593; color: white; border: none; padding: 10px 25px; border-radius: 4px; cursor: pointer; }
        .results { background: white; border-radius: 8px; padding: 25px; box-shadow: 0 2px 4px rgba(0,0,0,0.08); }
        .results h3 { color: #1a237e; margin-bottom: 15px; }
        .no-results { color: #666; font-style: italic; }
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
        <div class="search-form">
            <h2>Portal Search</h2>
            <form action="/search.php" method="GET">
                <input type="text" name="q" value="<?php echo isset($_GET['q']) ? $_GET['q'] : ''; ?>" placeholder="Search the portal...">
                <button type="submit">Search</button>
            </form>
        </div>

<?php if (isset($_GET['q']) && !empty($_GET['q'])): ?>
        <div class="results">
            <h3>Search results for: <?php echo $_GET['q']; ?></h3>
            <p class="no-results">No results found for "<?php echo $_GET['q']; ?>". Please try a different search term.</p>
        </div>
<?php endif; ?>
    </div>
</body>
</html>
