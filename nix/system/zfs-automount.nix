# Configures PAM to automatically mount ZFS volumes for the given user.
{ config, pkgs, options, ... }:

let zfs_mount_script =
  # Create a script that will accept a password in stdin
  # and automount the 
  pkgs.writeTextFile {
    name = "zfs_mount_home";
    executable = true;
    destination = "/bin/zfs_mount_home.sh";
    text = ''
      #!${pkgs.bash}/bin/bash
      set -eu
      PASSWORD=$(${pkgs.coreutils}/bin/cat -)
      ZFS_POOL=main
      VOL_NAME="$ZFS_POOL/$PAM_USER"
      VOL_MOUNT="/home/$PAM_USER"

      # check if the volume exists
      status=0
      ${pkgs.zfs}/bin/zfs list $VOL_NAME || status=$?

      if [ "$status" -eq 0 ]; then
        ${pkgs.zfs}/bin/zfs load-key "$VOL_NAME" <<< "$PASSWORD" || true
        ${pkgs.mount}/bin/mount -t zfs $VOL_NAME $VOL_MOUNT || true
        echo "ZFS Automount: Mounted volume $VOL_NAME" | ${pkgs.systemd}/bin/systemd-cat
      else
        echo "ZFS Automount: No ZFS volume found for user $PAM_USER" | ${pkgs.systemd}/bin/systemd-cat
      fi
    '';
  };

in
{
  security.pam.services.greetd.text =
    ''
      # Account Management
      account required pam_unix.so

      # Authentication management
      auth required pam_unix.so nullok likeauth try_first_pass
      auth optional pam_exec.so debug expose_authtok ${zfs_mount_script}/bin/zfs_mount_home.sh

      # Password management
      password sufficient pam_unix.so sha512

      # Session management
      session required pam_env.so conffile=/etc/pam/environment readenv=0
      session required pam_unix.so
      session required pam_loginuid.so
      session required ${pkgs.linux-pam}/lib/security/pam_lastlog.so silent
      session optional ${pkgs.systemd}/lib/security/pam_systemd.so
    '';

  security.pam.services.login.text = ''
    # Account Management
    account required pam_unix.so

    # Authentication Management
    auth require pam_unix.so nullok likeauth try_first_pass
    auth optional pam_exec.so debug expose_authtok ${zfs_mount_script}/bin/zfs_mount_home.sh

    # Password management
    password sufficient pam_unix.so sha512

    # Session management
    session required pam_env.so conffile=/etc/pam/environment readenv=0
    session required pam_unix.so
    session required pam_loginuid.so
    session required ${pkgs.linux-pam}/lib/security/pam_lastlog.so silent
    session optional ${pkgs.systemd}/lib/security/pam_systemd.so
  '';
}
