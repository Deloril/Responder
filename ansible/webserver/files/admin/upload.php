<?php
$upload_dir = '/var/www/tsg/uploads/';
$message = '';
$msg_type = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['document'])) {
    $file = $_FILES['document'];
    $target = $upload_dir . basename($file['name']);

    if (move_uploaded_file($file['tmp_name'], $target)) {
        chmod($target, 0644);
        $message = "Document uploaded successfully: <a href='/uploads/" . htmlspecialchars(basename($file['name'])) . "'>" . htmlspecialchars(basename($file['name'])) . "</a>";
        $msg_type = 'success';
    } else {
        $message = "Upload failed. Error code: " . $file['error'];
        $msg_type = 'error';
    }
}

$files = array_diff(scandir($upload_dir), ['.', '..']);
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document Management - TSG Admin</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f4f6f9; color: #333; }
        .header { background: #b71c1c; color: white; padding: 15px 40px; display: flex; justify-content: space-between; align-items: center; }
        .header h1 { font-size: 1.3em; }
        .header a { color: #ffcdd2; text-decoration: none; font-size: 0.9em; }
        .container { max-width: 900px; margin: 30px auto; padding: 0 20px; }
        .panel { background: white; border-radius: 8px; padding: 25px; box-shadow: 0 2px 4px rgba(0,0,0,0.08); margin-bottom: 20px; }
        .panel h2 { color: #b71c1c; margin-bottom: 15px; border-bottom: 2px solid #ffcdd2; padding-bottom: 8px; }
        .upload-form { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
        .upload-form input[type="file"] { flex: 1; min-width: 200px; }
        .upload-form button { background: #b71c1c; color: white; border: none; padding: 10px 25px; border-radius: 4px; cursor: pointer; }
        .upload-form button:hover { background: #880e0e; }
        .success { background: #e8f5e9; color: #2e7d32; padding: 12px 15px; border-radius: 4px; margin-bottom: 15px; }
        .success a { color: #1b5e20; }
        .error { background: #ffebee; color: #c62828; padding: 12px 15px; border-radius: 4px; margin-bottom: 15px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th { background: #f5f5f5; text-align: left; padding: 10px; border-bottom: 2px solid #ddd; font-size: 0.9em; }
        td { padding: 10px; border-bottom: 1px solid #eee; font-size: 0.9em; }
        td a { color: #1565c0; text-decoration: none; }
        td a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Document Management</h1>
        <a href="/admin/">&larr; Back to Admin Panel</a>
    </div>

    <div class="container">
        <div class="panel">
            <h2>Upload Document</h2>
            <?php if ($message): ?>
                <div class="<?php echo $msg_type; ?>"><?php echo $message; ?></div>
            <?php endif; ?>
            <form method="POST" enctype="multipart/form-data" class="upload-form">
                <input type="file" name="document" required>
                <button type="submit">Upload</button>
            </form>
            <p style="margin-top:10px; font-size:0.85em; color:#888;">Upload documents to the shared portal. All file types accepted.</p>
        </div>

        <div class="panel">
            <h2>Current Documents (<?php echo count($files); ?>)</h2>
            <table>
                <thead>
                    <tr><th>Filename</th><th>Size</th><th>Modified</th></tr>
                </thead>
                <tbody>
<?php foreach ($files as $f):
    $path = $upload_dir . $f;
    $size = filesize($path);
    $mod = date('Y-m-d H:i', filemtime($path));
    $human_size = $size < 1024 ? $size . ' B' : ($size < 1048576 ? round($size/1024, 1) . ' KB' : round($size/1048576, 1) . ' MB');
?>
                    <tr>
                        <td><a href="/uploads/<?php echo htmlspecialchars($f); ?>"><?php echo htmlspecialchars($f); ?></a></td>
                        <td><?php echo $human_size; ?></td>
                        <td><?php echo $mod; ?></td>
                    </tr>
<?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
