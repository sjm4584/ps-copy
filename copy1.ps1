#when nothing works. Let's hope it doesn't come to that
# c:\Windows\system32>powershell -command "&{ set-executionpolicy unrestricted}" < NUL

#each machine sends the files to two other machines. This way the share times are fast.

#!!
#The current logic is flawed. The 3rd stage of boxes won't know where to send their
#files to. We need to distribute the two IP addresses for each IP before we start sending
#files out. 
#
#
#!!

param (
	[string]$IPList,
	[string]$Share,
	[string]$script
)

if($IPList -eq "" or $Share -eq "" or $script -eq ""){
	write-host "Missing cmdline args. -iplist -share -script"
	exit
}
	write-host "iplist: " $IPList
	write-host "share: " $Share
	write-host "script: " $script
	write-host "-------------------------------------------";

#We need to distribute the IPs that each machine is going to share to before we
#can start sending files. This look works however we need a way to store the values
#but powershell doesn't have a 1:3 data linking object so time for some magic...

#######
#We need to send each sharing machine their two IP addresses to share to.
#ip_src -> {ip_dst1, ipdst2}
#######
function load_ip{
	write-host "printing associations" 
	$ip = get-content $iplist
	$i=0
	$j=1
	$target_ip = @{} #hash of IPs we are sharing to
	foreach ($line in $ip){
		#echo $target_ip[10.140.1.1][0] equals 10.140.1.2
		$target_ip[$ip[$i]] = ($ip[$j], $ip[$j+1])
		$i=$i+1
		$j=$j+2
	}
	$i=0
	#I'm sure there's a cleaner way but it's early so this is how it's being done.
	#loop through all IPs. If our hash has at least one value then we display them.
	foreach ($line in $ip){
		if($target_ip[$line][0]){
			write-host "$line -> { " $target_ip[$line][0] " " $target_ip[$line][1] " }"
			#add IPs to the file
			Add-Content c:\Users\sean\Desktop\$target_ip[$line] $target_ip[$line][0]
			Add-Content c:\Users\sean\Desktop\$target_ip[$line] $target_ip[$line][1]
			
			#send the IPs for the target to send to
			copy-item -Path c:\Users\sean\Desktop\$target_ip[$line] -Destination \\$target_ip[$line]\c$\Users\Student\Desktop -recurse -ErrorAction "Stop"
			
			$i=$i+1
		} else{ #not all IPs will have to send files
			write-host "IPs have been given"
			break
		}
	}
}

#send files!
#this probably needs debugging, like a lot
function send{
	$send_ip = get-content c:\Users\sean\Desktop\$target_ip[$line]
	foreach ($line in $send_ip){
		if($target_ip[$line][0]){
			write-host "[+] Copying shares to: " $target_ip[$line][0] " " $target_ip[$line][1]
			
			#copy shares
			copy-item -Path $share -Destination \\$target_ip[$line][0]\c$\Users\Student\Desktop -recurse -ErrorAction "Stop"
			copy-item -Path $share -Destination \\$target_ip[$line][1]\c$\Users\Student\Desktop -recurse -ErrorAction "Stop"
			
			write-host "[+] Copying script to: " $target_ip[$line][0] " " $target_ip[$line][1]
			
			#copy cli_script
			copy-item -Path $script -Destination \\$target_ip[$line][0]\c$\Users\Student\Desktop -recurse -ErrorAction "Stop"
			copy-item -Path $script -Destination \\$target_ip[$line][1]\c$\Users\Student\Desktop -recurse -ErrorAction "Stop"
			
			write-host "[+] psexec is being launched against PC1..."
			
			#psexec run <client_script.ps1 -path_to_IPs -file_to_share -client_script>
			& C:\pstools\psexec.exe \\$target_ip[$line][0] "C:\Users\Student\Desktop\$script $ip_pc1_path $share $script"
			
			write-host "[+] psexec is being launched against PC2..."
			
			& C:\pstools\psexec.exe \\$target_ip[$line][1] "C:\Users\Student\Desktop\$script $ip_pc2_path $share $script"
			
			(Get-Content $IPlist | Select-String $target_ip[$line][0] -NotMatch) | Set-Content $IPList
			write-host $target_ip[$line][0] " has been sent their data and now deleted..."
			(Get-Content $IPlist | Select-String $target_ip[$line][1] -NotMatch) | Set-Content $IPlist
			write-host $target_ip[$line][1] " has been sent their data and now deleted..."
		}
		else{ #not all IPs will have to send files
			write-host "Files have been sent"
			break
		}
	}
}
load_ip
send