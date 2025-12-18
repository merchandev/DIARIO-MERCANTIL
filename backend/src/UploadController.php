<?php
require_once __DIR__.'/Response.php';
require_once __DIR__.'/Database.php';

class UploadController {
  private string $uploadDir;
  private array $allowed;
  private int $maxBytes;

  public function __construct() {
    $this->uploadDir = realpath(__DIR__.'/..').'/storage/uploads';
    if (!is_dir($this->uploadDir)) mkdir($this->uploadDir, 0777, true);
  $allowed = getenv('ALLOWED_TYPES') ?: 'csv,xlsx,json,pdf,zip,jpg,jpeg,png,webp,doc,docx';
    $this->allowed = array_map('trim', explode(',', strtolower($allowed)));
    $maxMb = (int) (getenv('MAX_FILE_MB') ?: 500);
    $this->maxBytes = $maxMb * 1024 * 1024;
  }

  public function create() {
    Response::json(['ok' => true, 'message' => 'Direct upload supported at POST /api/files']);
  }

  public function upload() {
    if (!isset($_FILES['files'])) {
      Response::json(['error' => 'No files field'], 400);
    }
    $pdo = Database::pdo();
    $pdo->beginTransaction();
    $created = [];

    foreach ($_FILES['files']['name'] as $i => $name) {
      $size = (int) $_FILES['files']['size'][$i];
      $tmp  = $_FILES['files']['tmp_name'][$i];
      $type = strtolower(pathinfo($name, PATHINFO_EXTENSION));

      if (!in_array($type, $this->allowed)) {
        $created[] = ['name'=>$name,'status'=>'validation_failed','error'=>'Tipo no permitido'];
        continue;
      }
      if ($size > $this->maxBytes) {
        $created[] = ['name'=>$name,'status'=>'validation_failed','error'=>'Excede tamaño máximo'];
        continue;
      }

      $checksum = hash_file('sha256', $tmp);
      $dest = $this->uploadDir.'/'.uniqid('f_', true).'_'.basename($name);
      if (!move_uploaded_file($tmp, $dest)) {
        $created[] = ['name'=>$name,'status'=>'upload_failed','error'=>'No se pudo guardar'];
        continue;
      }

      $now = gmdate('c');
      $stmt = $pdo->prepare('INSERT INTO files(name,size,type,checksum,status,created_at,updated_at) VALUES(?,?,?,?,?,?,?)');
      $stmt->execute([$name,$size,$type,$checksum,'uploaded',$now,$now]);
      $fileId = (int) $pdo->lastInsertId();

      $ev = $pdo->prepare('INSERT INTO file_events(file_id,ts,type,message) VALUES(?,?,?,?)');
      $ev->execute([$fileId,$now,'uploaded','Archivo cargado y encolado para procesamiento']);

      $this->simulateProcessing($fileId, $dest, $name);

      $created[] = ['fileId'=>$fileId,'name'=>$name,'status'=>'uploaded'];
    }

    $pdo->commit();
    Response::json(['created'=>$created]);
  }

  private function simulateProcessing(int $fileId, string $path, string $name) {
    if (function_exists('fastcgi_finish_request')) fastcgi_finish_request();
    $php = escapeshellarg(PHP_BINARY);
    $script = escapeshellarg(__FILE__);
    $cmd = "$php -r 'require_once $script; UploadController::bgProcess($fileId);' > /dev/null 2>&1 &";
    exec($cmd);
  }

  public static function bgProcess($fileId) {
    require_once __DIR__.'/Database.php';
    $pdo = Database::pdo();
    $sleep = rand(1,3);
    sleep($sleep);
    $now = gmdate('c');

    if (rand(1,10) === 1) {
      $pdo->prepare('UPDATE files SET status=?, updated_at=? WHERE id=?')
          ->execute(['processing_failed',$now,$fileId]);
      $pdo->prepare('INSERT INTO file_events(file_id,ts,type,message) VALUES(?,?,?,?)')
          ->execute([$fileId,$now,'error','Procesamiento fallido']);
      return;
    }

    $resultDir = realpath(__DIR__.'/..').'/storage/results';
    if (!is_dir($resultDir)) mkdir($resultDir, 0777, true);
    file_put_contents($resultDir.'/result_'.$fileId.'.txt', "Resultado OK para file #$fileId\n");

    $pdo->prepare('UPDATE files SET status=?, updated_at=? WHERE id=?')
        ->execute(['completed',$now,$fileId]);
    $pdo->prepare('INSERT INTO file_events(file_id,ts,type,message) VALUES(?,?,?,?)')
        ->execute([$fileId,$now,'processed','Procesamiento completado']);
  }
}
