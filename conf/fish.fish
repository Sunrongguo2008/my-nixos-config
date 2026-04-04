set -U fish_greeting
if status is-interactive
    fastfetch
    # Commands to run in interactive sessions can go here
end

# 示例：将 ~/.cargo/bin 加入系统环境变量 PATH 中
# set -Ux CARGO_HOME $HOME/.cargo
# set -Ux PATH $CARGO_HOME/bin $PATH

# 为命令提供缩写
function b
    #sudo nixos-rebuild switch
    cd /etc/nixos
    nh os switch $(pwd)
end

# 可以写多行
function u
    cd /etc/nixos
    #sudo nixos-rebuild switch --recreate-lock-file --flake .
    sudo nix flake update
    nh os switch $(pwd)
end

function push
    cd
    cd ./文档/my-blog/
    git add .
    git commit -m 更新文章
    git push -u origin main
end

function web
    cd
    cd ./文档/my-blog/
    hugo serve -D
end

starship init fish | source
