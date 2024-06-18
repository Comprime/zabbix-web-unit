<?php
# SPDX-License-Identifier: AGPL-3.0-only
require_once '/usr/share/zabbix/include/classes/core/APP.php';

$app = APP::getInstance();
$app->run(APP::EXEC_MODE_API);
