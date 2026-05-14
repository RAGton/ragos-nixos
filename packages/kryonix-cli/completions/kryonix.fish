# Fish completion for Kryonix CLI

function __fish_kryonix_commands
    kryonix commands
end

function __fish_kryonix_subcommands
    set -l cmd (commandline -opc)
    if [ (count $cmd) -ge 2 ]
        kryonix commands --subcommands $cmd[2]
    end
end

function __fish_kryonix_hosts
    echo "glacier"
    echo "inspiron"
    echo "inspiron-nina"
    echo "iso"
end

# Top-level commands
complete -c kryonix -f -n "__fish_is_token_n 1" -a "(__fish_kryonix_commands)"

# Subcommands
complete -c kryonix -f -n "__fish_is_token_n 2" -a "(__fish_kryonix_subcommands)"

# Global options
complete -c kryonix -f -l help -h 'Mostra ajuda'
complete -c kryonix -f -l update -d 'Força atualização'
complete -c kryonix -f -l dry -d 'Simulação segura'
complete -c kryonix -f -l json -d 'Saída JSON'
complete -c kryonix -f -l host -a "(__fish_kryonix_hosts)" -d 'Define alvo'
complete -c kryonix -f -l flake -r -d 'Define caminho da flake'
