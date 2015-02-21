#when nothing works. Let's hope it doesn't come to that
# c:\Windows\system32>powershell -command "&{ set-executionpolicy unrestricted}" < NUL

#each machine sends the files to two other machines. This way the share times are fast.

param (
	[string]$IPList,
	[string]$Share,
	[string]$script
)

	write-host "iplist: " $IPList
	write-host "share: " $Share
	write-host "script: " $script
	write-host "-------------------------------------------";
#######
#each client is sent the shared files, client script, and the 2 IP's its going to
#send to
###
#for IP in list:
#	remove ip's from list
#	copy-item shared_files
#	copy-item cli_script
#	copy-item two_ip

#	psexec run cli_script -ip2 <ip addr1, ip addr2>
#######
function load_ip{
	$ip = get-content $iplist
	foreach ($line in $ip){
		write-host "ip: " $line
	}
	$ip_pc1 = $ip[2], $ip[3]
	$ip_pc2 = $ip[4], $ip[5]
	$ip_pc1_path = "C:\Users\sean\Desktop\ip_pc1.txt"
	$ip_pc2_path = "C:\Users\sean\Desktop\ip_pc2.txt"
	echo $ip_pc1 | out-file $ip_pc1_path
	echo $ip_pc2 | out-file $ip_pc2_path

	write-host "[+] Copying shares to: " $ip[0] " " $ip[1]
	
	#copy shares
	copy-item -Path $share -Destination \\$ip[0]\c$\Users\Student\Desktop -recurse -ErrorAction "Stop"
	copy-item -Path $share -Destination \\$ip[1]\c$\Users\Student\Desktop -recurse -ErrorAction "Stop"
	
	write-host "[+] Copying script to: " $ip[0] " " $ip[1]
	
	#copy cli_script
	copy-item -Path $script -Destination \\$ip[0]\c$\Users\Student\Desktop -recurse -ErrorAction "Stop"
	copy-item -Path $script -Destination \\$ip[1]\c$\Users\Student\Desktop -recurse -ErrorAction "Stop"
	
	write-host "[+] Copying IPs to: " $ip[0] " " $ip[1]
	
	#copy the file with two IPs for them to send to
	copy-item -Path $ip_pc1_path -Destination \\$ip[0]\c$\Users\Student\Desktop -recurse -ErrorAction "Stop"
	copy-item -Path $ip_pc2_path -Destination \\$ip[0]\c$\Users\Student\Desktop -recurse -ErrorAction "Stop"

	
	write-host "[+] psexec is being launched against PC1..."
	
	#psexec run <client_script.ps1 -path_to_IPs -file_to_share -client_script>
	& C:\pstools\psexec.exe \\$ip[0] "C:\Users\Student\Desktop\$script $ip_pc1_path $share $script"
	
	write-host "[+] psexec is being launched against PC2..."
	
	& C:\pstools\psexec.exe \\$ip[1] "C:\Users\Student\Desktop\$script $ip_pc2_path $share $script"
	
	(Get-Content $IPlist | Select-String $ip[0] -NotMatch) | Set-Content $IPList
	write-host $ip[0] " has been sent their data and now deleted..."
	(Get-Content $file | Select-String $ip[1] -NotMatch) | Set-Content $file
	write-host $ip[1] " has been sent their data and now deleted..."
}


load_ip
write-host "done"