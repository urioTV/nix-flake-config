{ config, lib, pkgs, ...}:

let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
		export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
		export __GLX_VENDOR_LIBRARY_NAME=nvidia
		export __VK_LAYER_NV_optimus=NVIDIA_only
		exec "$@"
  '';
in {

	environment.systemPackages = [ nvidia-offload ];

	hardware.opengl = {
	    enable = true;
	    driSupport = true;
	    driSupport32Bit = true;
	  };

	services.xserver.videoDrivers = ["nvidia"];

	hardware.nvidia = {
	
	    # Modesetting is required.
	    modesetting.enable = true;
	
	    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
	    powerManagement.enable = false;
	    # Fine-grained power management. Turns off GPU when not in use.
	    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
	    powerManagement.finegrained = true;
	
	    # Use the NVidia open source kernel module (not to be confused with the
	    # independent third-party "nouveau" open source driver).
	    # Support is limited to the Turing and later architectures. Full list of 
	    # supported GPUs is at: 
	    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
	    # Only available from driver 515.43.04+
	    # Currently alpha-quality/buggy, so false is currently the recommended setting.
	    open = false;
	
	    # Enable the Nvidia settings menu,
		# accessible via `nvidia-settings`.
	    nvidiaSettings = true;
	
	    # Optionally, you may need to select the appropriate driver version for your specific GPU.
	    package = config.boot.kernelPackages.nvidiaPackages.production;
	    
	    };

	    hardware.nvidia.prime = {
	    		offload = {
	    			enable = true;
	    			enableOffloadCmd = true;
	    		};
	    		# Make sure to use the correct Bus ID values for your system!
	    		amdgpuBusId = "PCI:4:0:0";
	    		nvidiaBusId = "PCI:1:0:0";
	    	};

	    # Early KMS
	    boot.initrd.kernelModules = [ "nvidia" ];
	    # boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
}
