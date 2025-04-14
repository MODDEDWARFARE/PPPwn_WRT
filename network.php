<?php

$cmd = 'cat settings.cfg';
$path = null;
exec($cmd ." 2>&1", $data, $ret);
if ($ret == 0){
foreach ($data as $x) {
   if (str_starts_with($x, 'path')) {
    $path = (explode("=", $x)[1]);
   }
   if (str_starts_with($x, 'ps4ip')) {
    $oldipinc = (explode("=", $x)[1]);
   }
}
}

if (isset($_POST['back'])){
	header("Location: index.php");
	exit;
}

if (isset($_POST['saveppp'])){

    $configFile = '/etc/config/pppoe';
    $oldip = null;

    $configLines = file($configFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);

    if ($configLines === false) {
        die("Unable to read the configuration file.");
    }

    foreach ($configLines as $line) {
        if (preg_match('/^\s*option\s+localip\s+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/', $line, $matches)) {
            $oldip = $matches[1];
            break;
        }
    } 

    $ps4ip = $_POST['ps4ip'];

    function isValidIp($ip) {
        return preg_match('/^(\d{1,3}\.){3}\d{1,3}$/', $ip) && array_reduce(explode('.', $ip), function($carry, $part) {
            return $carry && $part >= 0 && $part <= 255;
        }, true);
    }

    if (!isValidIp($ps4ip)) {
        die("Invalid IP address");
    }

    $configLines = file($configFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);

    if ($configLines === false) {
        die("Unable to read the configuration file.");
    }

    $updatedLines = [];
    foreach ($configLines as $line) {
        if (preg_match('/^\s*option\s+localip\s+/', $line)) {
            $updatedLines[] = "        option localip $ps4ip";
        } elseif (preg_match('/^\s*option\s+firstremoteip\s+/', $line)) {
            $ipParts = explode('.', $ps4ip);
            $ipParts[3] = (int)$ipParts[3] + 1;
            $incrementedIp = implode('.', $ipParts);
            $updatedLines[] = "        option firstremoteip $incrementedIp";
        } else {
            $updatedLines[] = $line;
        }
    }

    if (file_put_contents($configFile, implode(PHP_EOL, $updatedLines)) === false) {
        die("Failed to write to the configuration file.");
    }

    //reduce ip octet
    $ipParts = explode('.', $ps4ip);
    $ipParts[3] = (int)$ipParts[3] + 1;
    $ps4ipinc = implode('.', $ipParts);
    $ipParts[3] = (int)$ipParts[3] + 1;
    $guestip = implode('.', $ipParts);

	exec('echo -e "' . $_POST["pppu"] . '  *  ' . $_POST["pppw"] . '  ' . $ps4ipinc . '\n' . $_POST["guestusr"] . '  *  ' . $_POST["guestw"] . '  ' . $guestip . '" > /etc/ppp/chap-secrets');
	sleep(1);
    exec("echo '# PPP options for the PPPoE server
# LIC: GPL
require-chap
login
lcp-echo-interval 10
lcp-echo-failure 2
mru 1492
mtu 1492

ms-dns '$ps4ip'' | tee /etc/ppp/pppoe-server-options");

//dnsmasq
$configFile = '/etc/config/dhcp';
$path = str_replace('"', '', $path);
$settingsFile = $path . "/settings.cfg";

if (!file_exists($configFile)) {
    die("Configuration file not found: $configFile");
}

$configContents = file_get_contents($configFile);
if ($configContents === false) {
    die("Failed to read the configuration file.");
}

$configContents = preg_replace('/\b' . preg_quote($oldipinc, '/') . '\b/', $ps4ipinc, $configContents);
$configContents = preg_replace('/\b' . preg_quote($oldip, '/') . '\b/', $ps4ip, $configContents);


$tempFile = tempnam(sys_get_temp_dir(), 'config');
if (file_put_contents($tempFile, $configContents) === false) {
    die("Failed to write the temporary configuration file.");
}

exec("mv $tempFile $configFile", $output, $returnVar);
if ($returnVar !== 0) {
    die("Failed to update the configuration file: " . implode("\n", $output));
}

if (file_exists($settingsFile)) {
    exec("sed -i 's/" . escapeshellarg($oldipinc) . "/" . escapeshellarg($ps4ipinc) . "/g' " . escapeshellarg($settingsFile));
    exec("sed -i 's/" . escapeshellarg($oldip) . "/" . escapeshellarg($ps4ip) . "/g' " . escapeshellarg($settingsFile));

} else {
    die("Settings file not found: $settingsFile");
}



// Notify user
echo "<script type='text/javascript'>alert('Changes will be applied on reboot');</script>";

}

$cmd = 'cat /etc/ppp/chap-secrets';
exec($cmd . " 2>&1", $data, $ret);

foreach ($data as $index => $x) {
    if (!empty($x)) {
        if (preg_match('/(\S+)\s+\*\s+(\S+)\s+(\S+)/', $x, $matches)) {
            if ($index === 0) {
                $pppusr = $matches[1];  
                $ppppw = $matches[2];
            } elseif ($index === 1) {

                $guestusr = $matches[1];
                $guestw = $matches[2];
            }
        }
    }
}

$configFile = '/etc/config/pppoe';
$ps4ip = null;

$configLines = file($configFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);

if ($configLines === false) {
    die("Unable to read the configuration file.");
}

foreach ($configLines as $line) {
    if (preg_match('/^\s*option\s+localip\s+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/', $line, $matches)) {
        $ps4ip = $matches[1];
        break;
    }
}

if ($ps4ip === null) {
    die("localip not found in the configuration file.");
}

if (empty($pppusr)){ $pppusr = "ppp";}
if (empty($ppppw)){ $ppppw = "ppp";}
if (empty($guestusr)){ $guestusr = "guest";}
if (empty($guestw)){ $guestw = "ppp";}
if (empty($ps4ip)){ $ps4ip = "192.168.3.1";}
if (empty($ps4ipinc)){ $ps4ipinc = "192.168.3.2";}
if (empty($guestip)){ $guestip = "192.168.3.3";}

print("<html> 
<head>
<title>PPPwnWRT</title>
<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
<style>

body {
	user-select: none;
    -webkit-user-select: none;
    background-color: #0E0E14;
    color: FFFFFF;
    font-family: Arial;
}

select {
    background: #454545;
	color: #FFFFFF;
	padding: 3px 5px;
    border-radius: 3px;
	border: 1px solid #6495ED;
}


input[type=text] {
    background: #454545;
	color: #FFFFFF;
	padding: 5px 5px;
    border-radius: 3px;
	border: 1px solid #6495ED;
}

input[type=password] {
    background: #454545;
	color: #FFFFFF;
	padding: 5px 5px;
    border-radius: 3px;
	border: 1px solid #6495ED;
}

a:active,
a:focus {
    outline: 0;
    border: none;
}

button {
    border: 1px solid #6495ED;
    color: #FFFFFF;
    background: #454545;
    padding: 10px 20px;
    margin-bottom:12px;
    border-radius: 3px;
}

button:hover {
    background: #999999;
}

input:focus {
    outline:none;
}

label {
    padding: 5px 5px;
}

input[type=checkbox] {
    position: relative;
    cursor: pointer;
}

input[type=checkbox]:before {
    content: \"\";
    display: block;
    position: absolute;
    width: 17px;
    height: 17px;
    top: 0;
    left: 0;
    background-color:#e9e9e9;
}

input[type=checkbox]:checked:before {
    content: \"\";
    display: block;
    position: absolute;
    width: 17px;
    height: 17px;
    top: 0;
    left: 0;
    background-color:#1E80EF;
}

input[type=checkbox]:checked:after {
    content: \"\";
    display: block;
    width: 3px;
    height: 8px;
    border: solid white;
    border-width: 0 2px 2px 0;
    -webkit-transform: rotate(45deg);
    -ms-transform: rotate(45deg);
    transform: rotate(45deg);
    position: absolute;
    top: 2px;
    left: 6px;
}

input[type=submit] {
    padding:4px;
    color: #6495ED;
    margin-top: 10px;
    background-color: #0E0E14;
    border: none;
}

input[type=submit]:hover {
    text-decoration: underline;
}
</style>
<script>
if (window.history.replaceState) {
   window.history.replaceState(null, null, window.location.href);
}
</script>
</head>
<body>
<script>
function showpw() {
  var x = document.getElementById('wifip');
  if (x.type === 'password') {
    x.type = 'text';
  } else {
    x.type = 'password';
  }
}
</script>

");


print("<center><br>
<br>
<br><table align=center><td><form method=\"post\">
<input type=\"text\" name=\"pppu\" id=\"pppu\" value=\"".$pppusr."\" onclick=\"setEnd()\">
<label for=\"pppu\">PS4 PPP Username</label>
<br><br>
<input type=\"text\" name=\"pppw\" id=\"pppw\" value=\"".$ppppw."\" onclick=\"setEnd()\">
<label for=\"pppw\">PS4 PPP Password</label>
<br><br><br>
<input type=\"text\" name=\"guestusr\" id=\"guestusr\" value=\"".$guestusr."\" onclick=\"setEnd()\">
<label for=\"guestusr\">Guest PPP Username</label>
<br><br>
<input type=\"text\" name=\"guestw\" id=\"guestw\" value=\"".$guestw."\" onclick=\"setEnd()\">
<label for=\"guestw\">Guest PPP Password</label>
<br><br><br>
<input type=\"text\" name=\"ps4ip\" id=\"ps4ip\" value=\"".$ps4ip."\" onclick=\"setEnd()\">
<label for=\"ps4ip\">Gateway address</label>
<br><br><br>
<center><button name=\"saveppp\" value=\"saveppp\">Save PPP</button>
</table>
</center>");


print("<br><br><center>
<form method=\"post\"><input type=\"hidden\" value=\"back\"><input type=\"submit\" name=\"back\" value=\"Back to config page\"/></form></center>");
print("</body></html>");

?>