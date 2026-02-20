# =============================================================================
# Módulo NixOS: Wallpaper Engine (KDE Plasma)
# Autor: rag
#
# O que é:
# - Integração declarativa do plugin "Wallpaper Engine for KDE Plasma".
# - Instala o wallpaper plugin (KPackage) e, opcionalmente, executa um refresh do cache do KDE
#   na inicialização da sessão para que o plugin apareça imediatamente no seletor de wallpapers.
#
# Por quê:
# - Permite habilitar a integração via `programs.wallpaper-engine-kde.enable` em NixOS.
# - Evita passos manuais como baixar/instalar plugin por GUI ou rodar comandos pós-switch.
#
# Como:
# - Instala `kdePackages.wallpaper-engine-plugin` (por padrão) no sistema.
# - Declara dependências runtime sugeridas (ex.: mpv/ffmpeg).
# - Opcionalmente cria um `systemd --user` oneshot para rodar `kbuildsycoca6` ao entrar na sessão.
#
# Riscos:
# - Este módulo NÃO instala o aplicativo proprietário "Wallpaper Engine" (Steam); ele instala o plugin KDE.
# - Alguns wallpapers podem não funcionar (dependendo do backend, codecs e suporte em Wayland/X11).
# =============================================================================

{ config, lib, pkgs, ... }:

let
	cfg = config.programs.wallpaper-engine-kde;

	# Condições de sessão para o service (Wayland/X11).
	sessionConditions =
		(lib.optionals (cfg.sessions.wayland && !cfg.sessions.x11) [ "WAYLAND_DISPLAY" ])
		++ (lib.optionals (!cfg.sessions.wayland && cfg.sessions.x11) [ "DISPLAY" "!WAYLAND_DISPLAY" ]);

	desktopConditions = lib.optionals cfg.requireKdeDesktop [ "XDG_CURRENT_DESKTOP=KDE" ];
in
{
	options.programs.wallpaper-engine-kde = {
		enable = lib.mkEnableOption "Wallpaper Engine plugin para KDE Plasma";

		package = lib.mkOption {
			type = lib.types.package;
			default = pkgs.kdePackages.wallpaper-engine-plugin;
			defaultText = lib.literalExpression "pkgs.kdePackages.wallpaper-engine-plugin";
			description = ''
				Pacote do plugin do KDE Plasma.

				Por padrão, usa o pacote do nixpkgs que instala o wallpaper plugin
				"Wallpaper Engine for KDE Plasma".
			'';
		};

		extraPackages = lib.mkOption {
			type = lib.types.listOf lib.types.package;
			default = with pkgs; [ mpv ffmpeg ];
			defaultText = lib.literalExpression "with pkgs; [ mpv ffmpeg ]";
			description = ''
				Dependências runtime sugeridas.

				O plugin suporta diferentes backends e pode depender de codecs/players.
				Manter `mpv` e `ffmpeg` instalados tende a melhorar compatibilidade.
			'';
		};

		autostart = lib.mkOption {
			type = lib.types.bool;
			default = true;
			description = ''
				Se habilitado, cria um `systemd --user` oneshot para rodar `kbuildsycoca6` ao iniciar a sessão.

				Isso ajuda o KDE a enxergar rapidamente o novo plugin após `nixos-rebuild switch`,
				evitando a necessidade de logout/login manual apenas para “recarregar” caches.
			'';
		};

		requireKdeDesktop = lib.mkOption {
			type = lib.types.bool;
			default = true;
			description = ''
				Se `true`, o serviço de autostart só roda quando `XDG_CURRENT_DESKTOP=KDE`.

				Mantém o comportamento bem "KDE-only" e evita rodar o refresh em outras sessões.
			'';
		};

		sessions = {
			wayland = lib.mkOption {
				type = lib.types.bool;
				default = true;
				description = "Permite o autostart em sessões Wayland (condição `WAYLAND_DISPLAY`).";
			};

			x11 = lib.mkOption {
				type = lib.types.bool;
				default = true;
				description = "Permite o autostart em sessões X11 (condição `DISPLAY`, e tenta evitar Wayland).";
			};
		};
	};

	config = lib.mkIf cfg.enable {
		environment.systemPackages = [ cfg.package ] ++ cfg.extraPackages;

		systemd.user.services.wallpaper-engine-kde-kbuildsycoca = lib.mkIf cfg.autostart {
			description = "Atualiza cache do KDE para o plugin Wallpaper Engine";

			# Sessão gráfica do usuário.
			wantedBy = [ "graphical-session.target" ];
			partOf = [ "graphical-session.target" ];
			after = [ "graphical-session.target" ];

			unitConfig = {
				ConditionEnvironment = desktopConditions ++ sessionConditions;
			};

			serviceConfig = {
				Type = "oneshot";
				ExecStart = "${pkgs.kdePackages.kservice}/bin/kbuildsycoca6";
				TimeoutSec = 30;
			};
		};
	};
}
