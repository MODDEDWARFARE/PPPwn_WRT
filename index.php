<?php 

$firmwares = array("9.00", "9.03", "9.60", "10.00", "10.01", "10.50", "10.70", "10.71", "11.00");

$cmd = 'cat settings.cfg';
exec($cmd ." 2>&1", $data, $ret);
if ($ret == 0){
foreach ($data as $x) {
   if (str_starts_with($x, 'path')) {
    $path = (explode("=", $x)[1]);
   }
   elseif (str_starts_with($x, 'ps4ip')) {
    $ps4ip = (explode("=", $x)[1]);
   }
}
}else{
   $path = "/root/PPPwn_WRT-main";
   $ps4ip = "192.168.3.11";
}

if (isset($_POST['save'])){

    if ($_POST['pppwnbtn'] != "none"){

        exec('cp ' . $path . '/rc.button /etc/rc.button');
        sleep(1);
        exec('echo "#!/bin/sh

        if [ \"\$ACTION\" = \"released\" ] && [ \"\$BUTTON\" = \""' . escapeshellarg($_POST['pppwnbtn']) . '\"" ]; then
            chmod +x ' . $path . '/run.sh && ' . $path . '/run.sh
        fi

        return 0" > /etc/rc.button/' . escapeshellarg($_POST['pppwnbtn']));       
    }

    $octets = explode('.', $ps4ip);
    $cut_ip = "{$octets[0]}.{$octets[1]}.{$octets[2]}";

    $firewall_rule = "
config rule
        option name 'WANBLOCKER'
        list proto 'all'
        option src 'lan'
        list src_ip '${cut_ip}.0/24'
        option dest 'wan'
        option target 'REJECT'


";

    if (isset($_POST["pppoeconn"])){
        
        $firewall_file = '/etc/config/firewall';
        if (!file_exists($firewall_file)) {
            die("Error: Firewall config file does not exist.");
        }
        $file_content = file_get_contents($firewall_file);
        $file_content = str_replace($firewall_rule, '', $file_content);
        file_put_contents($firewall_file, $file_content);
    }
    else{
        
        file_put_contents('/etc/config/firewall', $firewall_rule, FILE_APPEND); 
    }

    $configFile = '/etc/config/pppoe';
    $gateway = null;

    $configLines = file($configFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);

    foreach ($configLines as $line) {
        if (preg_match('/^\s*option\s+localip\s+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/', $line, $matches)) {
            $gateway = $matches[1];
            break;
        }
    }

    // Path to the DHCP config file
    $dhcpConfig = '/etc/config/dhcp';
    $backupConfig = $dhcpConfig . '.bak';

    $newEntries = <<<EOL
                list address '/playstation.com/127.0.0.1'
                list server '/playstation.com/127.0.0.1'
                list address '/playstation.net/127.0.0.1'
                list server '/playstation.net/127.0.0.1'
                list address '/playstation.org/127.0.0.1'
                list server '/playstation.org/127.0.0.1'
                list address '/akadns.net/127.0.0.1'
                list server '/akadns.net/127.0.0.1'
                list address '/akamai.net/127.0.0.1'
                list server '/akamai.net/127.0.0.1'
                list address '/akamaiedge.net/127.0.0.1'
                list server '/akamaiedge.net/127.0.0.1'
                list address '/edgekey.net/127.0.0.1'
                list server '/edgekey.net/127.0.0.1'
                list address '/edgesuite.net/127.0.0.1'
                list server '/edgesuite.net/127.0.0.1'
                list address '/llnwd.net/127.0.0.1'
                list server '/llnwd.net/127.0.0.1'
                list address '/scea.com/127.0.0.1'
                list server '/scea.com/127.0.0.1'
                list address '/sie-rd.com/127.0.0.1'
                list server '/sie-rd.com/127.0.0.1'
                list address '/llnwi.net/127.0.0.1'
                list server '/llnwi.net/127.0.0.1'
                list address '/sonyentertainmentnetwork.com/127.0.0.1'
                list server '/sonyentertainmentnetwork.com/127.0.0.1'
                list address '/ribob01.net/127.0.0.1'
                list server '/ribob01.net/127.0.0.1'
                list address '/cddbp.net/127.0.0.1'
                list server '/cddbp.net/127.0.0.1'
                list address '/nintendo.net/127.0.0.1'
                list server '/nintendo.net/127.0.0.1'
                list address '/ea.com/127.0.0.1'
                list server '/ea.com/127.0.0.1'
        EOL;

    $shouldAdd = isset($_POST["ddns"]);

    if (!copy($dhcpConfig, $backupConfig)) {
        die("Failed to create a backup of the configuration file.\n");
    }

    $config = file_get_contents($dhcpConfig);
    if ($config === false) {
        die("Failed to read the configuration file.\n");
    }

    if ($shouldAdd != true) {
        if (strpos($config, 'config dnsmasq') === false) {
            $config .= "\nconfig dnsmasq\n$newEntries\n";
        } else {
            $config = preg_replace('/(config dnsmasq)/', "$1\n$newEntries", $config, 1);
        }
    } else {
        $escapedEntries = preg_quote($newEntries, '/');
        $escapedEntries = str_replace('\n', "[ \t]*\\n", $escapedEntries); // Allow flexible spacing
        $config = preg_replace("/$escapedEntries/s", '', $config);
    }

    if (file_put_contents($dhcpConfig, $config) === false) {
        die("Failed to update the configuration file.\n");
    }

    exec('/etc/init.d/dnsmasq restart', $output, $returnVar);

    if (isset($_POST["startup"])){
        
        $pwnpath = str_replace('"', "", $path);
        exec("echo 'sleep 20\nchmod +x $pwnpath/run.sh && $pwnpath/run.sh' > /etc/rc.local");
    }
    else{

        exec("echo '' > /etc/rc.local");
    }

	$config = "#!/bin/sh\n";
	$config .= "dtlan=\\\"".str_replace(" ", "", trim($_POST["interface"]))."\\\"\n";
	$config .= "fw=\\\"".$_POST["firmware"]."\\\"\n";
	$config .= "shutdown=".(isset($_POST["shutdownpi"]) ? "true" : "false")."\n";
	$config .= "pppoe=".(isset($_POST["pppoeconn"]) ? "true" : "false")."\n";
	$config .= "dtl=".(isset($_POST["dtlink"]) ? "true" : "false")."\n";
	$config .= "PPDBG=".(isset($_POST["ppdbg"]) ? "true" : "false")."\n";
    $config .= "timeout=\\\"".str_replace(" ", "", substr(trim($_POST["timeout"]), 0, -1)*60)."\\\"\n";
	$config .= "ghd=".(isset($_POST["restmode"]) ? "true" : "false")."\n";
	$config .= "PYPWN=".(isset($_POST["upypwn"]) ? "true" : "false")."\n";
	$config .= "led=\\\"".$_POST["ledact"]."\\\"\n";
	$config .= "DDNS=".(isset($_POST["ddns"]) ? "true" : "false")."\n";
	$config .= "oipv=".(isset($_POST["oipv"]) ? "true" : "false")."\n";
    $config .= "path=\\\"".$_POST["path"]."\\\"\n";
    $config .= "btn=".$_POST["pppwnbtn"]."\n";
    $config .= "ps4ip=".$_POST["ps4ip"]."\n";
    $config .= "startup=".(isset($_POST["startup"]) ? "true" : "false")."\n";
	exec('echo "'.$config.'" | tee settings.cfg');
	sleep(1);

    exec('/etc/init.d/firewall restart');
}
 
if (isset($_POST['restart'])){

print("<html><head><title>PPPwnWRT</title><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"></head><style>body{user-select: none;-webkit-user-select: none;background-color: #0E0E14;color: white;font-family: Arial;font-size:20px;}a {padding: 5px 5px;font-size:20px; padding:4px; color:6495ED;} a:hover,a:focus {color: #999999;text-decoration: none;cursor: pointer;}</style><body><br><br><br><center>PPPwn is restarting...<br><br><a href=index.php>Reload Page</a></center></body></html>");
exec('/etc/init.d/dtlink stop && /etc/init.d/pppoe-server stop');
sleep(1);
exec('/etc/init.d/pppwn restart');
exit;

}

if (isset($_POST['reboot'])){
	
   print("<html><head><title>PPPwnWRT</title><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"></head><style>body{user-select: none;-webkit-user-select: none;background-color: #0E0E14;color: white;font-family: Arial;font-size:20px;}a {padding: 5px 5px;font-size:20px; padding:4px; color:6495ED;} a:hover,a:focus {color: #999999;text-decoration: none;cursor: pointer;}</style><body><br><br><br><center>The device is rebooting...<br><br><a href=index.php>Reload Page</a></center></body></html>");
   exec('reboot');
   exit;
}

if (isset($_POST['stop'])){
	
    exec('/etc/init.d/pppwn stop && /etc/init.d/dtlink stop');
    sleep(2);
    exec('/etc/init.d/pppoe-server reload');
 }

if (isset($_POST['payloads'])){
   header("Location: payloads.php");
   exit;
}

if (isset($_POST['network'])){
   header("Location: network.php");
   exit;
}

$cmd = 'cat settings.cfg';
exec($cmd ." 2>&1", $data, $ret);
if ($ret == 0){
foreach ($data as $x) {
   if (str_starts_with($x, 'dtlan')) {
      $interface = (explode("=", str_replace("\"", "", $x))[1]);
   }
   elseif (str_starts_with($x, 'fw')) {
      $firmware = (explode("=", str_replace("\"", "", $x))[1]);
   }
   elseif (str_starts_with($x, 'shutdown')) {
      $shutdownpi = (explode("=", $x)[1]);
   }
   elseif (str_starts_with($x, 'pppoe')) {
      $pppoeconn = (explode("=", $x)[1]);
   }
   elseif (str_starts_with($x, 'dtl')) {
      $dtlink = (explode("=", $x)[1]);
   }
   elseif (str_starts_with($x, 'PPDBG')) {
      $ppdbg = (explode("=", $x)[1]);
   }
   elseif (str_starts_with($x, 'timeout')) {
      $timeout = (explode("=", str_replace("\"", "", $x))[1]);
      $timeout = $timeout/60 . 'm';
   }
   elseif (str_starts_with($x, 'ghd')) {
      $restmode = (explode("=", $x)[1]);
   }
   elseif (str_starts_with($x, 'PYPWN')) {
      $upypwn = (explode("=", $x)[1]);
   }
   elseif (str_starts_with($x, 'led')) {
      $ledact = (explode("=", str_replace("\"", "", $x))[1]);
   }
   elseif (str_starts_with($x, 'DDNS')) {
      $ddns = (explode("=", $x)[1]);
   }
   elseif (str_starts_with($x, 'oipv')) {
      $oipv = (explode("=", $x)[1]);
   }
   elseif (str_starts_with($x, 'path')) {
    $path = (explode("=", $x)[1]);
   }
   elseif (str_starts_with($x, 'btn')) {
    $pppwnbtn = (explode("=", $x)[1]);
   }
   elseif (str_starts_with($x, 'ps4ip')) {
    $ps4ip = (explode("=", $x)[1]);
   }
   elseif (str_starts_with($x, 'startup')) {
    $startup = (explode("=", $x)[1]);
   }
}
}else{
   $interface = "eth0";
   $firmware = "11.00";
   $shutdownpi = "true";
   $usbether = "false";
   $pppoeconn = "false";
   $vmusb = "false";
   $dtlink = "false";
   $ppdbg = "false";
   $timeout = "5m";
   $restmode = "false";
   $upypwn = "false";
   $ledact = "none";
   $ddns = "false";
   $oipv = "false";
   $path = "/root/PPPwn_WRT-main";
   $pppwnbtn = "none";
   $ps4ip = "192.168.3.1";
   $startup = "true";
}

if (empty($interface)){ $interface = "eth0";}
if (empty($firmware)){ $firmware = "11.00";}
if (empty($shutdownpi)){ $shutdownpi = "true";}
if (empty($usbether)){ $usbether = "false";}
if (empty($pppoeconn)){ $pppoeconn = "false";}
if (empty($vmusb)){ $vmusb = "false";}
if (empty($dtlink)){ $dtlink = "false";}
if (empty($ppdbg)){ $ppdbg = "false";}
if (empty($timeout)){ $timeout = "5m";}
if (empty($upypwn)){ $upypwn = "false";}
if (empty($ledact)){ $ledact = "none";}
if (empty($ddns)){ $ddns = "false";}
if (empty($oipv)){ $oipv = "false";}
if (empty($pppwnbtn)){ $pppwnbtn = "none";}
if (empty($path)){ $path = "/root/PPPwn_WRT-main";}
if (empty($ps4ip)){ $ps4ip = "192.168.3.1";}
if (empty($startup)){ $startup = "true";}

print("<html> 
<head>
<title>PPPwnWRT</title>
<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
<style>

body {
	user-select: none;
    -webkit-user-select: none;
    background-color: #0E0E14;
    color: white;
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

a:active,a:hover,
a:focus {
    outline: 0;
    border: none;
	color: #999999;
    text-decoration: none;
    cursor: pointer;
}

a {
	font-size:12px; 
	text-decoration: none;
	color:6495ED;
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
	
.logger {
    display: none; 
    position: fixed; 
    z-index: 1; 
    padding-top: 100px; 
    padding-bottom: 100px;
    left: 0;
    top: 0;
    width: 100%; 
    height: 60%; 
    overflow-x:hidden;
    overflow-y:hidden;
    background-color: #00000000;
}


.logger-content {
    position: relative;
    background-color: #0E0E14;
    margin: auto;
    padding: 0;
    border: 1px solid #6495ED;
    width: 80%;
    box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2),0 6px 20px 0 rgba(0,0,0,0.19);
    -webkit-animation-name: animatetop;
    -webkit-animation-duration: 0.4s;
    animation-name: animatetop;
    animation-duration: 0.4s
}


@-webkit-keyframes animatetop {
    from {top:-300px; opacity:0} 
    to {top:0; opacity:1}
}

@keyframes animatetop {
    from {top:-300px; opacity:0}
    to {top:0; opacity:1}
}


.close {
    color: #6495ED;
    float: right;
    font-size: 28px;
    font-weight: bold;
}

.close:hover,
.close:focus {
    color: #999999;
    text-decoration: none;
    cursor: pointer;
}

.logger-header {
    padding: 2px 8px;
    background-color: #0E0E14;
    color: 0E0E14;
}

.logger-body 
{
    padding: 2px 8px;
}

textarea {
    resize: none;
    border: none;
    background-color: #0E0E14;
    color: #FFFFFF;
    box-sizing:border-box;
    height: 100%;
    width: 100%;
    -webkit-box-sizing: border-box;
    -moz-box-sizing: border-box;    
    box-sizing: border-box;         
}

label[id=pwnlog] {
    padding: 5px 5px;
	font-size:12px; 
	padding:4px; 
	color:6495ED;
}

label[id=pwnlog]:hover,
label[id=pwnlog]:focus {
    color: #999999;
    text-decoration: none;
    cursor: pointer;
}

label[id=help] {
    padding: 5px 5px;
	font-size:12px; 
	padding:4px; 
	color:6495ED;
}

label[id=help]:hover,
label[id=help]:focus {
    color: #999999;
    text-decoration: none;
    cursor: pointer;
}

label[id=pconfig] {
    padding: 5px 5px;
	font-size:12px; 
	padding:4px; 
	color:6495ED;
}

label[id=pconfig]:hover,
label[id=pconfig]:focus {
    color: #999999;
    text-decoration: none;
    cursor: pointer;
}

div[id=help]{
    height:100%;
    overflow:auto;
    overflow-x:hidden;
	scrollbar-color: #6495ED #0E0E14;
    scrollbar-width: thin;
}


</style>
<script>
var fid;
if (window.history.replaceState) {
   window.history.replaceState(null, null, window.location.href);
}

function startLog(lf) {
   fid = setInterval(updateLog, 2000, lf);
}

function stopLog() {
  clearInterval(fid);
}

function updateLog(f) {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', '/' + f);
	xhr.setRequestHeader('Cache-Control', 'no-cache');
	xhr.responseType = \"text\";
	xhr.onload = () => {
	if (!xhr.responseURL.includes(f)) {
	xhr.abort();
	return;
	}
	if (xhr.readyState === xhr.DONE) {
    if (xhr.status === 200) {
	document.getElementById(\"text_box\").value = xhr.responseText;
	var textarea = document.getElementById('text_box');
	textarea.scrollTop = textarea.scrollHeight;
	}
  }
};
xhr.send();
}

function setEnd() {
	if (navigator.userAgent.includes('PlayStation 4')) {
		let name = document.getElementById(\"plist\");
		name.focus();
		name.selectionStart = name.value.length;
		name.selectionEnd = name.value.length;	
	}
}
</script>
</head>
<body>
<center>

<div id=\"pwnlogger\" class=\"logger\">
<div class=\"logger-content\">
<div class=\"logger-header\">
<a href=\"javascript:void(0);\" style=\"text-decoration:none;\"><span class=\"close\">&times;</span></a></div>
<div class=\"logger-body\">
</div></div></div>
<br>
<form method=\"post\"><button name=\"payloads\">Load Payloads</button> &nbsp; ");


print("<button name=\"network\">Network Settings</button> &nbsp; <button name=\"restart\">Restart PPPwn</button> &nbsp; <button name=\"stop\">Stop PPPwn</button> &nbsp; <button name=\"reboot\">Reboot</button>
</form>
</center><table align=center><td><form method=\"post\">");

print("<select name=\"interface\">");

$cmd = 'ip link';
exec($cmd . " 2>&1", $idata, $iret);

$current_interface = "";
$matching_interfaces = [];

foreach ($idata as $line) {
    $line = trim($line);

    if (preg_match('/^\d+: ([^:]+):/', $line, $matches)) {
        $current_interface = $matches[1];
    }

    if (strpos($line, 'master ps4') !== false) {
        $matching_interfaces[] = $current_interface;
    }
}

foreach ($matching_interfaces as $x) {
    $x = trim($x);

    $display_name = strpos($x, '@') !== false ? strstr($x, '@', true) : $x;

    if ($display_name !== "" && $display_name !== "lo" && $display_name !== "ppp0" && !str_starts_with($display_name, "wlan")) {
        if ($interface == $display_name) {
            print("<option value=\"" . $display_name . "\" selected>" . $display_name . "</option>");
        } else {
            print("<option value=\"" . $display_name . "\">" . $display_name . "</option>");
        }
    }
}

print("</select><label for=\"interface\">&nbsp; PS4 LAN port</label><br><br>");



print("<select name=\"firmware\">");
foreach ($firmwares as $fw) {
if ($firmware == $fw)
{
	print("<option value=\"".$fw."\" selected>".$fw."</option>");
}else{
	print("<option value=\"".$fw."\">".$fw."</option>");
}
}
print("</select><label for=\"firmware\">&nbsp; Firmware version</label><br><br>");



print("<select name=\"timeout\">");
for($x =1; $x<=5;$x++)
{
   if ($timeout == $x."m")
   {
	   print("<option value=\"".$x."m\" selected>".$x."m</option>");
   }else{
	   print("<option value=\"".$x."m\">".$x."m</option>");
   }
} 
print("</select><label for=\"timeout\">&nbsp; Time to restart PPPwn if it hangs</label><br><br>");


print("<select name=\"ledact\">");
$cmd = 'ls /sys/class/leds';
exec($cmd ." 2>&1", $ldata, $lret);
$ldata[] = "none";
foreach ($ldata as $x) {
$x = trim($x);
if ( $ledact ==  $x)
{
    print("<option value=\"".$x."\" selected>".$x."</option>");
}
else
{
    print("<option value=\"".$x."\">".$x."</option>");
}

}
print("</select><label for=\"ledact\">&nbsp; Activity LED</label><br><br>");

print("<select name=\"pppwnbtn\">");
$cmd = 'ls /etc/rc.button';
exec($cmd ." 2>&1", $btndata, $btnret);
$btndata[] = "none";
foreach ($btndata as $x) {
$x = trim($x);
if ( $pppwnbtn ===  $x)
{
    print("<option value=\"".$x."\" selected>".$x."</option>");
}
else
{
    print("<option value=\"".$x."\">".$x."</option>");
}

}
print("</select><label for=\"pppwnbtn\">&nbsp; Add PPPwn Button</label><br><br>");

$cmd = 'sudo dpkg-query -W --showformat="\${Status}\\n" python3-scapy | grep "install ok installed"';
exec($cmd ." 2>&1", $pypdata, $ret);
if (implode($pypdata) == "install ok installed")
{
$cval = "";
if ($upypwn == "true")
{
$cval = "checked";
}
print("<br><input type=\"checkbox\" name=\"upypwn\" value=\"".$upypwn."\" ".$cval.">
<label for=\"upypwn\">&nbsp;Use Python version</label>");
if ($upypwn == "false")
{
print("&nbsp; <a href=\"pconfig.php\" style=\"text-decoration:none;\"><label id=\"pconfig\">PPPwn C++ Options</label></a>");
}
print("<br>");
}else{
print("<a href=\"pconfig.php\" style=\"text-decoration:none;\"><label id=\"pconfig\">PPPwn C++ Options</label></a><br>");
}

$cval = "";
if ($oipv == "true")
{
$cval = "checked";
}
print("<br><input type=\"checkbox\" name=\"oipv\" value=\"".$oipv."\" ".$cval.">
<label for=\"oipv\">&nbsp;Use original source ipv6<label style=\"font-size:12px; padding:4px;\">(fe80::4141:4141:4141:4141)</label></label>
<br>");


$cval = "";
if ($restmode == "true")
{
$cval = "checked";
}
print("<br><input type=\"checkbox\" name=\"restmode\" value=\"".$restmode."\" ".$cval.">
<label for=\"restmode\">&nbsp;Detect if goldhen is running<label style=\"font-size:12px; padding:4px;\">(useful for rest mode)</label></label>
<br>");


if ($shutdownpi == "false" || $pppoeconn == "true")
{
$cval = "";
if ($dtlink == "true")
{
$cval = "checked";
}
print("<br><input type=\"checkbox\" name=\"dtlink\" value=\"".$dtlink."\" ".$cval.">
<label for=\"dtlink\">&nbsp;Detect console shutdown and restart PPPwn</label>
<br>");
}



if ($ppdbg == "true")
{
print("<br><input type=\"checkbox\" name=\"ppdbg\" value=\"".$ppdbg."\" checked>
<label for=\"ppdbg\">&nbsp;Enable verbose PPPwn</label> &nbsp; <a href=\"javascript:void(0);\" style=\"text-decoration:none;\"><label id=\"pwnlog\">Open Log Viewer</label></a>
<br>");
}
else
{
print("<br><input type=\"checkbox\" name=\"ppdbg\" value=\"".$ppdbg."\">
<label for=\"ppdbg\">&nbsp;Enable verbose PPPwn</label>
<br>");
}


$cval = "";
if ($pppoeconn == "true")
{
$cval = "checked";
}
print("<br><input type=\"checkbox\" name=\"pppoeconn\" value=\"".$pppoeconn."\" ".$cval.">
<label for=\"pppoeconn\">&nbsp;Enable console internet access</label>
<br>");

$cval = "";
if ($startup == "true")
{
$cval = "checked";
}
print("<br><input type=\"checkbox\" name=\"startup\" value=\"".$startup."\" ".$cval.">
<label for=\"startup\">&nbsp;Run PPPwn on Startup</label>
<br>");


$cval = "";
if ($ddns == "true")
{
$cval = "checked";
}
print("<br><input type=\"checkbox\" name=\"ddns\" value=\"".$ddns."\" ".$cval.">
<label for=\"ddns\">&nbsp;Disable DNS blocker</label>");

print("<input type=\"hidden\" name=\"path\" value=".$path.">");
print("<input type=\"hidden\" name=\"ps4ip\" value=".$ps4ip.">");

if ($pppoeconn == "false")
{
$cval = "";
if ($shutdownpi == "true")
{
$cval = "checked";
}
print("<br><br><input type=\"checkbox\" name=\"shutdownpi\" value=\"".$shutdownpi."\" ".$cval.">
<label for=\"shutdownpi\">&nbsp;Shutdown after PWN</label>
<br>");
}

print("</td></tr><td align=center><br><button name=\"save\">Save</button></td></tr>
</form>
</td>
</table>
<script>
var logger = document.getElementById(\"pwnlogger\");
var span = document.getElementsByClassName(\"close\")[0];
");


if ($ppdbg == "true")
{
print("var btn = document.getElementById(\"pwnlog\");
btn.onclick = function() {
  logger.style.display = \"block\";
  var lbody = document.getElementsByClassName(\"logger-body\")[0];
  lbody.innerHTML  = '<textarea disabled id=\"text_box\" rows=\"40\"></textarea>';
  startLog('pwn.log');
}
");
}


print("var btn1 = document.getElementById(\"help\");
btn1.onclick = function() {
  logger.style.display = \"block\";
  var lbody = document.getElementsByClassName(\"logger-body\")[0];
  lbody.innerHTML  = \"<br><div id=help style='text-align: left; font-size: 14px;'> <font color='#F28C28'>Interface</font> - this is the lan interface on the pi that is connected to the console.<br><br><font color='#F28C28'>Firmware version</font> - version of firmware running on the console.<br><br><font color='#F28C28'>Time to restart PPPwn if it hangs</font> - a timeout in minutes to restart pppwn if the exploit hangs mid process.<br><br><font color='#F28C28'>Led activity</font> - on selected pi models this will have the leds flash based on the exploit progress.<br><br><font color='#F28C28'>Use Python version</font> - enabling this will force the use of the original python pppwn released by <a href='https://github.com/TheOfficialFloW/PPPwn' target='_blank'>TheOfficialFloW</a> <br><br><font color='#F28C28'>Use GoldHen if available for selected firmware</font> - if this is not enabled or your firmware has no goldhen available vtx-hen will be used.<br><br><font color='#F28C28'>Use original source ipv6</font> - this will force pppwn to use the original ipv6 address that was used in pppwn as on some consoles it increases the speed of pwn.<br><br><font color='#F28C28'>Use usb ethernet adapter for console connection</font> - only enable this if you are using a usb to ethernet adapter to connect to the console.<br><br><font color='#F28C28'>Detect if goldhen is running</font> - this will make pi-pwn check if goldhen is loaded on the console and skip running pppwn if it is running.<br><br><font color='#F28C28'>Detect console shutdown and restart PPPwn</font> - with this enabled if the link is lost between the pi and the console pppwn will be restarted.<br><br><font color='#F28C28'>Enable verbose PPPwn</font> - enables debug output from pppwn so you can see the exploit progress.<br><br><font color='#F28C28'>Enable console internet access</font> - enabling this will make pi-pwn setup a connection to the console allowing internet access after pppwn succeeds.<br><br><font color='#F28C28'>Disable DNS blocker</font> - enabling this will turn off the dns blocker that blocks certain servers that are used for updates and telemetry. <br><br><font color='#F28C28'>Shutdown PI after PWN</font> - if enabled this will make the pi shutdown after pppwn succeeds.<br><br><font color='#F28C28'>Enable usb drive to console</font> - on selected pi models this will allow a usb drive in the pi to be passed through to the console.<br><br><font color='#F28C28'>Ports</font> - this is a list of ports that are forwarded from the pi to the console, single ports or port ranges can be used.<br><br><br><br><center><font color='#50C878'>Credits</font> - all credit goes to <a href='https://github.com/TheOfficialFloW' target='_blank'>TheOfficialFloW</a>, <a href='https://github.com/xfangfang' target='_blank'>xfangfang</a>, <a href='https://github.com/SiSTR0' target='_blank'>SiSTR0</a>, <a href='https://github.com/xvortex' target='_blank'>Vortex</a>, <a href='https://github.com/EchoStretch' target='_blank'>EchoStretch</a> and many other people who have made this project possible.</center>\";
}

span.onclick = function() {
  logger.style.display = \"none\";
  stopLog();
  var text1 = document.getElementById(\"text_box\");
  text1.value = '';
}

window.onclick = function(event) {
  if (event.target == logger) {
    logger.style.display = \"none\";
	stopLog();
	var text1 = document.getElementById(\"text_box\");
	text1.value = '';
  }
}
");

if (isset($_POST['update'])){
	exec('sudo bash /boot/firmware/PPPwn/update.sh >> /dev/null &');
    print("logger.style.display = \"block\";
    var lbody = document.getElementsByClassName(\"logger-body\")[0];
    lbody.innerHTML  = '<textarea disabled id=\"text_box\" rows=\"40\"></textarea>';
    startLog('upd.log');");
}
print("</script></form></td></table><center style=\"color: #555555;\">Pi-Pwn web panel by: Stooged</form></center>");
print("
</body>
</html>");

?>