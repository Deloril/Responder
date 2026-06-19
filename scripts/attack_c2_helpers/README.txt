Project:Responder — attack C2 helper scripts (operator laptop + attack server)
================================================================================

These files support the attack_* scenario scripts:

  attack_c2_helpers/runner_lib.sh
      Sourced on your laptop; validates C2_FRAMEWORK and SSH-streams the remote script.

  attack_c2_helpers/remote_server_c2.sh
      Run ON the attack server via ssh stdin; builds payload or writes listener .rc / notes.

Scenarios (see each script header for full behaviour):

  attack_serve_c2_payload_over_http.sh <region>
      Build C2 payload, write listener config, serve HTTP :8080 from attack box, optional MSF tmux.

  attack_serve_c2_payload_for_web_phishing.sh <region>
      Same as above + messaging for corporate web upload + email phish URLs.

  attack_scenario_vscode_fake_extension_update.sh <region>
      Fake VS Code extension update server + DC DNS for updates.vaulttools.io + C2 listener path.

  attack_upload_c2_payload_to_corporate_web.sh <region> [disguised_filename]
      Exploit admin upload on web portal; expects report.exe from prior attack_serve_* script.

  attack_metasploit_restore_after_reboot.sh <region>
      After attack VM reboot: re-run msfvenom (optional skip), listener.rc, HTTP :8080, msf tmux "msf".

C2 selection:

  C2_FRAMEWORK=metasploit|sliver|mythic|havoc

Staged pre-built implant on the attack server (Mythic / Havoc / Sliver fallback). Default path uses a
bland corporate-style filename for IR drills; override on your laptop if needed:

  C2_STAGED_IMPLANT_PATH=/home/ubuntu/YourChosenName.exe ./scripts/attack_serve_c2_payload_for_web_phishing.sh apac

  Default: /home/ubuntu/TSG-DesktopSupportAssistant.exe

Install all C2 tooling on the attack server (run from repo root):

  ./scripts/attack_server_install_all_c2_tools.sh <region>
