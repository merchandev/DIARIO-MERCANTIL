<?php
class Database {
  private static ?PDO $pdo = null;
  public static function pdo(): PDO {
    if (!self::$pdo) {
      // Prefer environment DB_PATH, fallback to storage persistent location
      $dbPath = getenv('DB_PATH') ?: __DIR__.'/../storage/database.sqlite';
      self::$pdo = new PDO('sqlite:'.$dbPath);
      self::$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
      self::$pdo->exec('PRAGMA foreign_keys = ON');
    }
    return self::$pdo;
  }
}
