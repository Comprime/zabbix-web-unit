<?php
function preloadDirTree($path) {
    $directory = new RecursiveDirectoryIterator($path);
    $fullTree = new RecursiveIteratorIterator($directory);
    foreach ($fullTree as $key => $file) {
        if ($file->isReadable() && $file->getExtension() === 'php') {
            opcache_compile_file($file->getPathname());
        }
    }
}
function preloadDir($path) {
    $directory = new DirectoryIterator($path);
    foreach ($directory as $key => $file) {
        if ($file->isReadable() && $file->getExtension() === 'php') {
            opcache_compile_file($file->getPathname());
        }
    }
}

error_log('start preloading');
include_once '/usr/share/zabbix/vendor/autoload.php';
preloadDirTree('/usr/share/zabbix/conf/');
preloadDirTree('/usr/share/zabbix/include/');
preloadDir('/usr/share/zabbix/app/');
error_log('preloading done');
