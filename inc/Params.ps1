# Set Current Working Directory
$script_path = Split-Path -parent $MyInvocation.MyCommand.Definition
$script_path = $(Split-Path $script_path -parent)
Set-Location $script_path

# VHD file for capturing images
$vhd_file = "${script_path}\images\${os}\vm\${os}.${edition}.vhd"
$vbox_file = "${script_path}\images\${os}\vm\${os}.vbox"

$mount_disk = $c_drive_mount	

if ($boot) {
	$wim_type = 'boot'
} else {
	$wim_type = 'install'
}

if ($imagex -eq $null) {
    $imagex = "${script_path}\tools\boot.root\wimaging\utils\imagex\imagex.exe"
}

if ($windows_adk_path -eq $null) {
	$windows_adk_path="c:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit"
}

# Mount Directory
if ($mount_dir -eq $null) {
	$mount_dir = "${script_path}\images\${os}\mount"
}

if(!(Test-Path -Path ($mount_dir))) {
	md $mount_dir
}

if ($drivers_dir -eq $null) {
	$drivers_dir = "${script_path}\install\drivers"
}

if ($dism -eq $null) {
	$dism = 'dism.exe'
}

if ($sources_root -ne $nul) {
	$sources = "${sources_root}\${os}"
} else {
	$sources = "${script_path}\sources\${os}"		
}

$pe_features_root="${sources}\WinPE_FPs"


$save_dir = "${script_path}\images\${os}\save"


		
# Checking if we are working on boot.wim or install.wim


if ($boot -ne $true) {
	# install.wim
	
	$tools_dir = "${script_path}\tools\install.root"
	
	# Wim file that scripts process (AddTools, AddFeature, etc)
	$wim_file = "${script_path}\images\${os}\work\install.wim"
	# Location of install.wim within windows installation "dvd" root. That's the file that the installer takes. Supposed to be exposed via a network share
	if ($install_root -ne $nul) {
		$wim_file_install = "${install_root}\${os}\sources\install.wim"
		$install = "${install_root}\${os}"
	} else {	
		$wim_file_install = "${script_path}\install\${os}\sources\install.wim"
		$install = "${script_path}\install\${os}"
	}
	
	$sources_wim_file = "${sources}\sources\install.wim"
	
	# Filename for captured (from vhd) wim file
	if ($captured_wims_dir -ne $null) {
		$captured_wim = "${captured_wims_dir}\${os}.${edition}.install.$(Get-Date -format yyyMMdd).wim"
	} else {
		$captured_wim = "${script_path}\images\${os}\captured\${os}.${edition}.install.$(Get-Date -format yyyMMdd).wim"
	}
	
	

	if ($os -eq "server-2008r2") {
        # Directory where the updates are located
		$updates_dir = $wsus_offline_dir+"\w61-x64\glb"
		if ($edition -eq "enterprise") {
			# Index of the actual image in the original install.wim
            $wim_index = 3
            
            # Image name in the original install.wim
			$wim_image_name = "Windows Server 2008 R2 SERVERENTERPRISE"				
		} elseif ($edition -eq "standard") {
			$wim_index = 1
			$wim_image_name = "Windows Server 2008 R2 SERVERSTANDARD"
		}		
	} else {
		if ($os -like "*-pe-*") {
			$updates_dir = $pe_features_root			
		}
	}


} else {
	# boot.wim file

	$tools_dir = "${script_path}\tools\boot.root"
	# Location of install.wim within windows installation "dvd" root. That's the file that the installer takes. 
	# Supposed to be exposed via a network share and http
	if ($install_root -ne $nul) {
		$wim_file_install = "${install_root}\${os}\sources\boot.wim"
		$install = "${install_root}\${os}"
	} else {	
		$wim_file_install = "${script_path}\install\${os}\sources\boot.wim"
		$installer = "${script_path}\install\${os}"
	}
	
	if ($os -like "*-pe*") {
		$sources_wim_file = "${sources}\winpe.wim"
	} else {
		$sources_wim_file = "${sources}\sources\boot.wim"
	}
	
	
	# Wim file that scripts processes (AddTools, AddFeature, etc)
	$wim_file = "${script_path}\images\${os}\work\boot.wim"
	
	# Filename for captured (from vhd) wim file
	if ($captured_wims_dir -ne $null) {
		$captured_wim = "${captured_wims_dir}\${os}.${edition}.boot.$(Get-Date -format yyyMMdd).wim"
	} else {
		$captured_wim = "${script_path}\images\${os}\captured\${os}.${edition}.boot.$(Get-Date -format yyyMMdd).wim"
	}
	if ($os -eq "server-2008r2") {
		$wim_image_name_pe = "Microsoft Windows PE (x64)"
		
		
		$wim_image_name_setup = "Microsoft Windows Setup (x64)"
		#$wim_image_name_setup = "Microsoft Windows Longhorn Setup (x64)"
		$wim_image_name = $wim_image_name_setup
				
	} elseif ($os -eq "windows-pe-x86")	{
		
        # Wim file that scripts process (AddTools, AddFeature, etc)
		$wim_file = $script_path + "\images\" + $os + "\work\boot.wim"
		$wim_image_name = "Microsoft Windows PE (x86)"
				
	} elseif ($os -eq "windows-pe-x64")	{	
		$wim_image_name = "Microsoft Windows PE (x64)"				
	}
}

if (-not(Test-Path -PathType Container $save_dir)) {
	New-Item -ItemType Directory -Path $save_dir
}



