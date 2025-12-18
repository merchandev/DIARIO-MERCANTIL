<?php
require_once __DIR__.'/Response.php';
require_once __DIR__.'/Database.php';

class SettingsController {
  public function get(){
    $pdo = Database::pdo();
    $rows = $pdo->query('SELECT key, value FROM settings')->fetchAll(PDO::FETCH_KEY_PAIR);
    // Cast numeric values where applicable
    $out = [];
    foreach ($rows as $k=>$v) {
      if (is_numeric($v)) {
        if (str_contains($v,'.')) $out[$k] = (float)$v; else $out[$k] = (int)$v;
      } else {
        $out[$k] = $v;
      }
    }
    Response::json(['settings'=>$out]);
  }

  public function save(){
    $pdo = Database::pdo();
    $in = json_decode(file_get_contents('php://input'), true) ?: [];
    $now = gmdate('c');
    $stmt = $pdo->prepare('INSERT INTO settings(key,value,updated_at) VALUES(?,?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value, updated_at=excluded.updated_at');
    foreach ($in as $k=>$v) {
      $stmt->execute([$k, (string)$v, $now]);
    }
    Response::json(['ok'=>true]);
  }
}
