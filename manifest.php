<?php
header('Content-Type: application/json');

function create_manifest($folder) {
  $dir = new RecursiveDirectoryIterator($folder);
	// Iterate through all the files/folders in the current directory
  $manifest = [];
	foreach (new RecursiveIteratorIterator($dir) as $file) {
		$info = pathinfo($file);
		// ignore dot files
		if ($file -> IsFile() && substr($file -> getFilename(), 0, 1) != ".") {
			$file = str_replace(' ', '%20', $file);
			$hash = md5_file($file);
			$file = str_replace($folder, '', $file);
			$manifest[] = ['file' => $file, 'hash' => $hash];
		}
	}
	return $manifest;
}

$folder = '../whereever/your/dir/is'; // use post / get vars to make it more dynamic ;)
$manifest = create_manifest($folder);
echo json_encode($manifest, JSON_UNESCAPED_SLASHES);
